%{
    #include <stdio.h>
    #include <fstream>
    #include <iostream>
    #include <map>
    #include <stack>
    #include <string>
    #include <vector>
    #include "utils.hpp"

    extern int yylineno;
    extern FILE* yyin;

    int yylex(void);
    int yyerror(char const*);
    std::string takeFirstAvailableRegisterNotA();
    void freeRegister(std::string rx);
    void printCmd(std::string cmd);
    int getAddress(std::string var);


    std::fstream outputFile;
    int generatedLines = 0;
    int currentProcedureId = 0;
    int currentVarAddress = 0;
    std::string varPrefix = "proc" + std::to_string(currentProcedureId) + "_";
    std::map<std::string, int> variableMap;
    std::map<std::string, std::string> procedureAlias;
    std::map<std::string, int> procedureAddress;
    std::map<std::string, std::string> argsAlias;
    bool availableRegister[8];
    std::stack<std::string> lastUsedRegister;
    int argId = 0;
    std::vector<std::string> argsVector;
%}

%define api.value.type {std::string}
%define parse.error verbose

%token PROCEDURE
%token IS
%token IN
%token END
%token PROGRAM
%token IF
%token THEN
%token ELSE
%token ENDIF
%token WHILE
%token DO
%token ENDWHILE
%token REPEAT
%token UNTIL
%token READ
%token WRITE
%token T
%token num
%token pidentifier
%token SEMICOLON
%token COMMA
%token COLON
%token EQUAL
%token LPAR
%token RPAR
%token LSPAR
%token RSPAR
%token PLUS
%token MINUS
%token SLASH
%token ASTERISK
%token PERCENT
%token NEGATION
%token MORE
%token LESS






%%
program_all:
    procedures main {
        printCmd("JUMP " + std::to_string(generatedLines - countLines($2) + 1) + "\n");
        printCmd($1);
        printCmd($2);
    }
;

procedures:
    procedures PROCEDURE proc_head IS declarations IN commands END { 
        variableMap[varPrefix + "@return"] = currentVarAddress;
        currentVarAddress++;

        std::string r = takeFirstAvailableRegisterNotA();  
        std::string varName = varPrefix + "@return";
        int varAddress = getAddress(varName);
        std::string n = intToBinary(varAddress);

        $$ = "#PROCEDURE " + varPrefix + "\n" + $7;

        $$ += "RST " + r + "\n";
        generatedLines++;
        for(int i = 0; i < n.size(); i++)
        {
            if(i > 0)
            {
                $$ += "SHL " + r + "\n";
                generatedLines++;
            }
            if(n[i] == '1')
            {
                $$ += "INC " + r + "\n";
                generatedLines++;
            }
        } 
        $$ += "JUMPR " + r + "\n";
        generatedLines++;

        currentProcedureId++;
        varPrefix = "proc" + std::to_string(currentProcedureId) + "_"; 
        }
    | procedures PROCEDURE proc_head IS IN commands END { 
        variableMap[varPrefix + "@return"] = currentVarAddress;
        currentVarAddress++;

        std::string r = takeFirstAvailableRegisterNotA();  
        std::string varName = varPrefix + "@return";
        int varAddress = getAddress(varName);
        std::string n = intToBinary(varAddress);

        $$ = "#PROCEDURE " + varPrefix + "\n" + $6;

        $$ += "RST " + r + "\n";
        generatedLines++;
        for(int i = 0; i < n.size(); i++)
        {
            if(i > 0)
            {
                $$ += "SHL " + r + "\n";
                generatedLines++;
            }
            if(n[i] == '1')
            {
                $$ += "INC " + r + "\n";
                generatedLines++;
            }
        } 
        $$ += "JUMPR " + r + "\n";
        generatedLines++;

        currentProcedureId++;
        varPrefix = "proc" + std::to_string(currentProcedureId) + "_"; 
        }
    | {
        generatedLines++;
    }
;

main:
    PROGRAM IS declarations IN commands END {
        $$ = "#MAIN\n" + $5;
        $$ += "HALT\n";
        generatedLines++;
    }
    | PROGRAM IS IN commands END {
        $$ = "#MAIN\n" + $4;
        $$ += "HALT\n";
        generatedLines++;
    }
;

commands:
    commands command {
        $$ = $1 + $2;
    }
    | command {
        $$ = $1;
    }
;

command:
    identifier COLON EQUAL expression SEMICOLON {
        std::string r4 = lastUsedRegister.top();
        lastUsedRegister.pop();
        freeRegister(r4);
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();
        freeRegister(r1);

        $$ = $1 + $4;
        $$ += "GET " + r4 + "\n";
        $$ += "STORE " + r1 + "\n";
        generatedLines += 2;
    }
    | IF condition THEN commands ELSE commands ENDIF {
        generatedLines += 2;
        int len6 = countLines($6);
        int addr6 = generatedLines - len6;

        $$ = $2;
        $$ += "JPOS " + std::to_string(addr6) + "\n";
        $$ += $4;
        $$ += "JUMP " + std::to_string(generatedLines) + "\n";
        $$ += $6;
    }
    | IF condition THEN commands ENDIF {
        generatedLines += 1;

        $$ = $2;
        $$ += "JPOS " + std::to_string(generatedLines) + "\n";
        $$ += $4;
    }
    | WHILE condition DO commands ENDWHILE {
        int loopBegin = generatedLines - countLines($2) - countLines($4) + 1;
        generatedLines += 2;

        $$ = $2;
        $$ += "JPOS " + std::to_string(generatedLines) + "\n";
        $$ += $4;
        $$ += "JUMP " + std::to_string(loopBegin) + "\n";
    }
    | REPEAT commands UNTIL condition SEMICOLON {
        int loopBegin = generatedLines - countLines($2) - countLines($4);

        $$ = $2 + $4;
        $$ += "JPOS " + std::to_string(loopBegin) + "\n";
        generatedLines += 1;
    }
    | proc_call SEMICOLON {
        $$ = $1;
    }
    | READ identifier SEMICOLON {
        std::string r = lastUsedRegister.top();

        $$ = $2;
        $$ += "READ\n";
        $$ += "STORE " + r + "\n";
        generatedLines += 2;

        freeRegister(r);
        lastUsedRegister.pop();
    }
    | WRITE value SEMICOLON {
        std::string r = lastUsedRegister.top();

        $$ = $2;
        $$ += "GET " + r + "\n";
        $$ += "WRITE\n";
        generatedLines += 2;

        freeRegister(r);
        lastUsedRegister.pop();
    }
;

proc_head:
    pidentifier LPAR args_decl RPAR {
        procedureAlias[$1] = varPrefix;
        argId = 0;
    }
;

proc_call:
    pidentifier LPAR args RPAR {
        std::string procId = procedureAlias[$1];
        int procAddr = procedureAddress[procId];
        int returnAddr = getAddress(procId + "@return");
        std::string r1 = takeFirstAvailableRegisterNotA();  
        std::string r2 = takeFirstAvailableRegisterNotA();

        $$ = "#CALL " + procId + "\n";

        // Dla każdego argumentu w wywołaniu funkcji
        for(int j = 0; j < argsVector.size(); j++)
        {
            std::string targetName = procId + "arg" + std::to_string(j);
            targetName = argsAlias[targetName];
            std::string sourceName = argsVector[j];

            int sourceAddr = getAddress(sourceName);
            int targetAddr = getAddress(targetName);

            generatedLines += insertingNumber("a", sourceAddr, &$$);
            generatedLines += insertingNumber(r1, targetAddr, &$$);
            $$ += "STORE " + r1 + "\n";
        }

        generatedLines += insertingNumber(r1, returnAddr, &$$);
        $$ += "RST " + r2 + "\n";
        $$ += "INC " + r2 + "\n";
        $$ += "SHL " + r2 + "\n";
        $$ += "SHL " + r2 + "\n";
        $$ += "STRK a\n";
        $$ += "ADD " + r2 + "\n";
        $$ += "STORE " + r1 + "\n";
        $$ += "JUMP " + std::to_string(procAddr) + "\n";
        generatedLines += 8;

        $$ += "#END OF CALL\n";

        freeRegister(r1);
        freeRegister(r2);
        argsVector.clear();
    }
;

declarations:
    declarations COMMA pidentifier {
        variableMap[varPrefix + $3] = currentVarAddress;
        currentVarAddress++;
    }
    | declarations COMMA pidentifier LSPAR num RSPAR {
        variableMap[varPrefix + $3] = currentVarAddress;
        currentVarAddress += stoi($5);
    }
    | pidentifier {
        variableMap[varPrefix + $1] = currentVarAddress;
        currentVarAddress++;
    }
    | pidentifier LSPAR num RSPAR {
        variableMap[varPrefix + $1] = currentVarAddress;
        currentVarAddress += stoi($3);
    }
;

args_decl:
    args_decl COMMA pidentifier {
        variableMap[varPrefix + $3] = currentVarAddress;
        currentVarAddress++;

        argsAlias[varPrefix + "arg" + std::to_string(argId)] = varPrefix + $3;
        argId++;
    }
    | args_decl COMMA T pidentifier {
        variableMap[varPrefix + $4] = currentVarAddress;
        currentVarAddress++;

        argsAlias[varPrefix + "arg" + std::to_string(argId)] = varPrefix + $4;
        argId++;
    }
    | pidentifier {
        variableMap[varPrefix + $1] = currentVarAddress;
        currentVarAddress++;

        argsAlias[varPrefix + "arg" + std::to_string(argId)] = varPrefix + $1;
        argId++;
    }
    | T pidentifier {
        variableMap[varPrefix + $2] = currentVarAddress;
        currentVarAddress++;

        argsAlias[varPrefix + "arg" + std::to_string(argId)] = varPrefix + $2;
        argId++;
    }
;

args:
    args COMMA pidentifier {
        argsVector.push_back(varPrefix + $3);
        // std::cout << argId << $3 << std::endl;
        // argId++;
    }
    | pidentifier {
        argsVector.push_back(varPrefix + $1);
        // std::cout << argId << $1 << std::endl;
        // argId++;
    }
;

expression:
    value
    | value PLUS value {
        std::string r3 = lastUsedRegister.top();
        lastUsedRegister.pop();
        freeRegister(r3);
        std::string r1 = lastUsedRegister.top();

        $$ = $1 + $3;
        $$ += "GET " + r1 + "\n";
        $$ += "ADD " + r3 + "\n";
        $$ += "PUT " + r1 + "\n";
        generatedLines += 3;
    }
    | value MINUS value {
        std::string r3 = lastUsedRegister.top();
        lastUsedRegister.pop();
        freeRegister(r3);
        std::string r1 = lastUsedRegister.top();

        $$ = $1 + $3;
        $$ += "GET " + r1 + "\n";
        $$ += "SUB " + r3 + "\n";
        $$ += "PUT " + r1 + "\n";
        generatedLines += 3;
    }
    | value ASTERISK value {
        std::string c = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string b = lastUsedRegister.top();
        std::string d = takeFirstAvailableRegisterNotA();
        freeRegister(b);
        freeRegister(c);
        freeRegister(d);

        $$ = $1 + $3;
        $$ += "GET " + b + "\n";
        $$ += "JZERO " + std::to_string(generatedLines + 32) + "\n";
        $$ += "GET " + c + "\n";
        $$ += "JPOS " + std::to_string(generatedLines + 6) + "\n";
        $$ += "RST " + b + "\n";
        $$ += "JUMP " + std::to_string(generatedLines + 32) + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JZERO " + std::to_string(generatedLines + 14) + "\n";
        $$ += "GET " + b + "\n";
        $$ += "PUT " + d + "\n";
        $$ += "GET " + c + "\n";
        $$ += "PUT " + b + "\n";
        $$ += "GET " + d + "\n";
        $$ += "PUT " + c + "\n";
        $$ += "RST " + d + "\n";
        $$ += "GET " + c + "\n";
        $$ += "DEC a\n";
        $$ += "JZERO " + std::to_string(generatedLines + 29) + "\n";
        $$ += "GET " + c + "\n";
        $$ += "SHR " + c + "\n";
        $$ += "SHL " + c + "\n";
        $$ += "SUB " + c + "\n";
        $$ += "JZERO " + std::to_string(generatedLines + 26) + "\n";
        $$ += "GET " + b + "\n";
        $$ += "ADD " + d + "\n";
        $$ += "PUT " + d + "\n";
        $$ += "SHL " + b + "\n";
        $$ += "SHR " + c + "\n";
        $$ += "JUMP " + std::to_string(generatedLines + 15) + "\n";
        $$ += "GET " + b + "\n";
        $$ += "ADD " + d + "\n";
        $$ += "PUT " + b + "\n";

        generatedLines += 32;
    }
    | value SLASH value {
        std::string c = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string b = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string d = takeFirstAvailableRegisterNotA();
        std::string e = takeFirstAvailableRegisterNotA();

        $$ = $1 + $3;
        $$ += "RST " + d + "\n";
        $$ += "GET " + b + "\n";
        $$ += "JZERO " + std::to_string(generatedLines + 40) + "\n";
        $$ += "PUT " + d + "\n";
        $$ += "RST " + b + "\n";
        $$ += "GET " + c + "\n"; 
        $$ += "DEC a\n"; 
        $$ += "JZERO " + std::to_string(generatedLines + 40) + "\n";
        $$ += "GET " + d + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "RST " + d + "\n"; 
        $$ += "GET " + c + "\n"; 
        $$ += "SUB " + b + "\n"; 
        $$ += "JPOS " + std::to_string(generatedLines + 40) + "\n";
        $$ += "RST " + e + "\n"; 
        $$ += "GET " + c + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JPOS " + std::to_string(generatedLines + 21) + "\n";
        $$ += "SHL " + c + "\n"; 
        $$ += "INC " + e + "\n";
        $$ += "JUMP " + std::to_string(generatedLines + 15) + "\n";
        $$ += "SHR " + c + "\n"; 
        $$ += "DEC " + e + "\n"; 
        $$ += "INC " + d + "\n"; 
        $$ += "GET " + b + "\n"; 
        $$ += "SUB " + c + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "GET " + e + "\n";
        $$ += "JZERO " + std::to_string(generatedLines + 40) + "\n";
        $$ += "SHL " + d + "\n"; 
        $$ += "DEC " + e + "\n"; 
        $$ += "SHR " + c + "\n";
        $$ += "GET " + c + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JPOS " + std::to_string(generatedLines + 27) + "\n";
        $$ += "INC " + d + "\n"; 
        $$ += "GET " + b + "\n"; 
        $$ += "SUB " + c + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "JUMP " + std::to_string(generatedLines + 27) + "\n";

        lastUsedRegister.push(d);
        freeRegister(b);
        freeRegister(c);
        freeRegister(e);
        generatedLines += 40;
    }
    | value PERCENT value {
        std::string c = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string b = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string d = takeFirstAvailableRegisterNotA();
        std::string e = takeFirstAvailableRegisterNotA();

        $$ = $1 + $3;
        $$ += "RST " + d + "\n";
        $$ += "GET " + b + "\n";
        $$ += "JZERO " + std::to_string(generatedLines + 40) + "\n";
        $$ += "PUT " + d + "\n";
        $$ += "RST " + b + "\n";
        $$ += "GET " + c + "\n"; 
        $$ += "DEC a\n"; 
        $$ += "JZERO " + std::to_string(generatedLines + 40) + "\n";
        $$ += "GET " + d + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "RST " + d + "\n"; 
        $$ += "GET " + c + "\n"; 
        $$ += "SUB " + b + "\n"; 
        $$ += "JPOS " + std::to_string(generatedLines + 40) + "\n";
        $$ += "RST " + e + "\n"; 
        $$ += "GET " + c + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JPOS " + std::to_string(generatedLines + 21) + "\n";
        $$ += "SHL " + c + "\n"; 
        $$ += "INC " + e + "\n";
        $$ += "JUMP " + std::to_string(generatedLines + 15) + "\n";
        $$ += "SHR " + c + "\n"; 
        $$ += "DEC " + e + "\n"; 
        $$ += "INC " + d + "\n"; 
        $$ += "GET " + b + "\n"; 
        $$ += "SUB " + c + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "GET " + e + "\n";
        $$ += "JZERO " + std::to_string(generatedLines + 40) + "\n";
        $$ += "SHL " + d + "\n"; 
        $$ += "DEC " + e + "\n"; 
        $$ += "SHR " + c + "\n";
        $$ += "GET " + c + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JPOS " + std::to_string(generatedLines + 27) + "\n";
        $$ += "INC " + d + "\n"; 
        $$ += "GET " + b + "\n"; 
        $$ += "SUB " + c + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "JUMP " + std::to_string(generatedLines + 27) + "\n";

        lastUsedRegister.push(b);
        freeRegister(c);
        freeRegister(d);
        freeRegister(e);
        generatedLines += 40;
    }
;

condition:
    value EQUAL value {
        std::string r3 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string rt = takeFirstAvailableRegisterNotA();
        freeRegister(r3);
        freeRegister(rt);
        freeRegister(r1);

        $$ = $1 + $3;
        $$ += "GET " + r1 + "\n";
        $$ += "SUB " + r3 + "\n";
        $$ += "PUT " + rt + "\n";
        $$ += "GET " + r3 + "\n";
        $$ += "SUB " + r1 + "\n";
        $$ += "ADD " + rt + "\n";
        generatedLines += 6;
    }
    | value NEGATION EQUAL value {
        std::string r4 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string rt = takeFirstAvailableRegisterNotA();
        freeRegister(r4);
        freeRegister(rt);
        freeRegister(r1);

        $$ = $1 + $4;
        $$ += "GET " + r1 + "\n";
        $$ += "SUB " + r4 + "\n";
        $$ += "PUT " + rt + "\n";
        $$ += "GET " + r4 + "\n";
        $$ += "SUB " + r1 + "\n";
        $$ += "ADD " + rt + "\n";
        generatedLines += 6;

        $$ += "JPOS " + std::to_string(generatedLines + 3) + "\n";
        $$ += "INC a\n";
        $$ += "JUMP " + std::to_string(generatedLines + 4) + "\n";
        $$ += "RST a\n"; 
        generatedLines += 4;
    }
    | value MORE value {
        std::string r3 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();
        
        $$ = $1 + $3;
        $$ += "GET " + r1 + "\n";
        $$ += "SUB " + r3 + "\n";
        generatedLines += 2;

        $$ += "JPOS " + std::to_string(generatedLines + 3) + "\n";
        $$ += "INC a\n";
        $$ += "JUMP " + std::to_string(generatedLines + 4) + "\n";
        $$ += "RST a\n"; 
        generatedLines += 4;

        freeRegister(r1);
        freeRegister(r3);
    }
    | value LESS value {
        std::string r3 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();
        
        $$ = $1 + $3;
        $$ += "#LESS\n";
        $$ += "GET " + r3 + "\n";
        $$ += "SUB " + r1 + "\n";
        generatedLines += 2;

        $$ += "JPOS " + std::to_string(generatedLines + 3) + "\n";
        $$ += "INC a\n";
        $$ += "JUMP " + std::to_string(generatedLines + 4) + "\n";
        $$ += "RST a\n"; 
        generatedLines += 4;

        freeRegister(r1);
        freeRegister(r3);
    }
    | value MORE EQUAL value {
        std::string r4 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();
        
        $$ = $1 + $4;
        $$ += "GET " + r4 + "\n";
        $$ += "SUB " + r1 + "\n";
        generatedLines += 2;

        freeRegister(r1);
        freeRegister(r4);
    }
    | value LESS EQUAL value {
        std::string r4 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();
        
        $$ = $1 + $4;
        $$ += "GET " + r1 + "\n";
        $$ += "SUB " + r4 + "\n";
        generatedLines += 2;

        freeRegister(r1);
        freeRegister(r4);
    }
;

value:
    num {
        int x = stoi($1);
        std::string n = intToBinary(x);
        std::string r = takeFirstAvailableRegisterNotA();

        $$ = "RST " + r + "\n";
        generatedLines++;
        for(int i = 0; i < n.size(); i++)
        {
            if(i > 0)
            {
                $$ += "SHL " + r + "\n";
                generatedLines++;
            }
            if(n[i] == '1')
            {
                $$ += "INC " + r + "\n";
                generatedLines++;
            }
        }

        lastUsedRegister.push(r);
    }
    | identifier {
        $$ = $1;
        $$ += "LOAD " + lastUsedRegister.top() + "\n";
        $$ += "PUT " + lastUsedRegister.top() + "\n";
        generatedLines += 2;
    }
;

identifier:
    pidentifier { // TODO: Sprawdź czy zmienna istnieje
        std::string r = takeFirstAvailableRegisterNotA();  
        std::string varName = varPrefix + $1;
        int varAddress = getAddress(varName);
        std::string n = intToBinary(varAddress);

        $$ = "RST " + r + "\n";
        generatedLines++;
        for(int i = 0; i < n.size(); i++)
        {
            if(i > 0)
            {
                $$ += "SHL " + r + "\n";
                generatedLines++;
            }
            if(n[i] == '1')
            {
                $$ += "INC " + r + "\n";
                generatedLines++;
            }
        }  

        lastUsedRegister.push(r);
        }
    | pidentifier LSPAR num RSPAR { 
        std::string r = takeFirstAvailableRegisterNotA();
        std::string varName = varPrefix + $1;
        int varAddress = getAddress(varName);
        int offset = stoi($3);
        std::string n = intToBinary(varAddress + offset);

        $$ = "RST " + r + "\n";
        generatedLines++;
        for(int i = 0; i < n.size(); i++)
        {
            if(i > 0)
            {
                $$ += "SHL " + r + "\n";
                generatedLines++;
            }
            if(n[i] == '1')
            {
                $$ += "INC " + r + "\n";
                generatedLines++;
            }
        } 

        lastUsedRegister.push(r);
        }
    | pidentifier LSPAR pidentifier RSPAR  { 
        std::string r = takeFirstAvailableRegisterNotA();  
        std::string tabName = varPrefix + $1;
        int tabAddress = getAddress(tabName);
        std::string n = intToBinary(tabAddress);

        $$ = "RST " + r + "\n";
        generatedLines++;
        for(int i = 0; i < n.size(); i++)
        {
            if(i > 0)
            {
                $$ += "SHL " + r + "\n";
                generatedLines++;
            }
            if(n[i] == '1')
            {
                $$ += "INC " + r + "\n";
                generatedLines++;
            }
        } 

        std::string varName = varPrefix + $3;
        int varAddress = getAddress(varName);
        std::string m = intToBinary(varAddress);

        $$ += "RST a\n";
        generatedLines++;
        for(int i = 0; i < m.size(); i++)
        {
            if(i > 0)
            {
                $$ += "SHL a\n";
                generatedLines++;
            }
            if(m[i] == '1')
            {
                $$ += "INC a\n";
                generatedLines++;
            }
        } 
        $$ += "LOAD a\n";
        $$ += "ADD " + r + "\n";
        $$ += "PUT " + r + "\n";
        generatedLines += 3;

        lastUsedRegister.push(r);
        }
;





/* line: exp1 END 	{ 
        if(zerodiv) {
            zerodiv = false;
            printf("\nBłąd w linii %d! Dzielenie przez nieodwracalną liczbę!\n", yylineno-1);
        }
        else
            printf("\nWynik:\t%d\n",(int)$1); 
        printf("\n");
    }
    | error END	{ printf("Błąd składni w linii %d!\n",yylineno-1); printf("\n");}
; */
%%

std::string takeFirstAvailableRegisterNotA()
{
    for(int i = 1; i < 8; i++)
        if(availableRegister[i])
        {
            availableRegister[i] = false;
            std::string s(1, ('a' + i));
            return s;
        }
    
    throw "Brak wolnych rejestrów";
}

void freeRegister(std::string rx)
{
    char x = rx[0];
    availableRegister[x - 'a'] = true;
}

void printCmd(std::string cmd)
{
    outputFile << cmd;
}

int getAddress(std::string var)
{
    std::map<std::string, int>::iterator it;
    it = variableMap.find(var);
    if(it != variableMap.end())
    {
        return it->second;
    }
    std::cout << "Próba dostępu do niezadeklarowanej zmiennej \"" << var << "\" w linii " << yylineno << std::endl;
    throw "VariableError";
}

int yyerror(char const* s)
{
    printf("Error: %s at line %d\n", s, yylineno);	
    return 0;
}

int main(int argc, char const *argv[])
{

    if(argc != 3)
    {
        std::cout << "Poprawna składnia: \n\t./kompilator <plik źródłowy> <nazwa pliku docelowego>" << std::endl;
        return 44;
    }
    // Otworzenie pliku wejściowego i wyjściowego
    FILE* f;
    f = fopen(argv[1], "r");
    yyin = f;

    outputFile.open(argv[2], std::ios::out);
    if (!outputFile.good())
    {
        throw "Nie udało się utworzyć pliku wynikowego";
    }

    for(int i = 0; i < 8; i++)
    {
        availableRegister[i] = true;
    }

    printCmd("RST a\n");
    printCmd("RST b\n");
    printCmd("RST c\n");
    printCmd("RST d\n");
    printCmd("RST e\n");
    printCmd("RST f\n");
    printCmd("RST g\n");
    printCmd("RST h\n");
    generatedLines += 8;

    yyparse();

    outputFile.close();

    /* printf("Przeczytano %d linii\n", yylineno); */
    std::map<std::string, int>::iterator it = variableMap.begin();
    while(it != variableMap.end()) {
        std::cout << "map[" << it->first << "] = " << it->second << std::endl;
        ++it;
    }
    return 0;
}
