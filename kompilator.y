%{
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
    unsigned long long getAddress(std::string var);
    int getNumberOfArguments(std::string procedureName);

    int currentProcedureId = 0;
    unsigned long long currentVarAddress = 0;
    std::string varPrefix = "proc" + std::to_string(currentProcedureId) + "_";
    std::map<std::string, unsigned long long> variableMap;
    std::map<std::string, bool> isArgument;
    std::map<std::string, std::string> procedureAlias;
    std::map<std::string, std::string> argsAlias;
    std::map<std::string, int> numberOfArguments;
    bool availableRegister[8];
    std::stack<std::string> lastUsedRegister;
    int argId = 0;
    std::vector<std::string> argsVector;
    int jumpId = 0;
    std::string addressPrefix = "@addr";
    std::string endResult = "";

    // Zmienne do sprawdzania poprawności
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
        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        endResult = "JUMP " + addr1 + "\n";
        endResult += "# procedury\n";
        endResult += $1;
        endResult += "# main\n";
        endResult += addr1 + "\n";
        endResult += $2;
    }
;

procedures:
    procedures PROCEDURE proc_head IS declarations IN commands END { 
        variableMap[varPrefix + "@return"] = currentVarAddress;
        isArgument[varPrefix + $3] = false;
        currentVarAddress++;

        std::string r = takeFirstAvailableRegisterNotA();  
        std::string varName = varPrefix + "@return";
        unsigned long long varAddress = getAddress(varName);

        $$ = $1;
        $$ += "# " + $3 + " (" + varPrefix + ")" + "\n";
        $$ += "@" + varPrefix + "\n";
        $$ += $7;
        $$ += insertingNumber(r, varAddress);
        $$ += "LOAD " + r + "\n";
        $$ += "JUMPR a\n";

        currentProcedureId++;
        varPrefix = "proc" + std::to_string(currentProcedureId) + "_"; 
        freeRegister(r);
        }
    | procedures PROCEDURE proc_head IS IN commands END { 
        variableMap[varPrefix + "@return"] = currentVarAddress;
        isArgument[varPrefix + $3] = false;
        currentVarAddress++;

        std::string r = takeFirstAvailableRegisterNotA();  
        std::string varName = varPrefix + "@return";
        unsigned long long varAddress = getAddress(varName);

        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = $1;
        $$ += "# " + $3 + " (" + varPrefix + ")" + "\n";
        $$ += "@" + varPrefix + "\n";
        $$ += $6;
        $$ += insertingNumber(r, varAddress);
        $$ += "LOAD " + r + "\n";
        $$ += "JUMPR a\n";

        currentProcedureId++;
        varPrefix = "proc" + std::to_string(currentProcedureId) + "_"; 
        freeRegister(r);
        }
    | 
;

main:
    PROGRAM IS declarations IN commands END {
        $$ = $5;
        $$ += "HALT\n";
    }
    | PROGRAM IS IN commands END {
        $$ = $4;
        $$ += "HALT\n";
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

        $$ = "# x := y;\n";
        $$ += $1 + $4;
        $$ += "GET " + r4 + "\n";
        $$ += "STORE " + r1 + "\n";
    }
    | IF condition THEN commands ELSE commands ENDIF {
        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string addr2 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = "# if-else\n";
        $$ += $2;
        $$ += "JPOS " + addr1 + "\n";
        $$ += "# if true\n";
        $$ += $4;
        $$ += "JUMP " + addr2 + "\n";
        $$ += "# if false\n";
        $$ += addr1 + "\n";
        $$ += $6;
        $$ += addr2 + "\n";
        $$ += "# endif\n";
    }
    | IF condition THEN commands ENDIF {
        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = "# if\n";
        $$ += $2;
        $$ += "JPOS " + addr1 + "\n";
        $$ += "# if true\n";
        $$ += $4;
        $$ += addr1 + "\n";
        $$ += "# endif\n";
    }
    | WHILE condition DO commands ENDWHILE {
        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string addr2 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = "# while\n";
        $$ += addr2 + "\n";
        $$ += $2;
        $$ += "JPOS " + addr1 + "\n";
        $$ += "# while true\n";
        $$ += $4;
        $$ += "JUMP " + addr2 + "\n";
        $$ += addr1 + "\n";
        $$ += "# endwhile\n";
    }
    | REPEAT commands UNTIL condition SEMICOLON {
        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = "# repeat\n";
        $$ += addr1 + "\n";
        $$ += $2 + $4;
        $$ += "# until\n";
        $$ += "JPOS " + addr1 + "\n";
    }
    | proc_call SEMICOLON {
        $$ = $1;
    }
    | READ identifier SEMICOLON {
        std::string r = lastUsedRegister.top();

        $$ = "# read x;\n";
        $$ += $2;
        $$ += "READ\n";
        $$ += "STORE " + r + "\n";

        freeRegister(r);
        lastUsedRegister.pop();
    }
    | WRITE value SEMICOLON {
        std::string r = lastUsedRegister.top();

        $$ = "# write x;\n";
        $$ += $2;
        $$ += "GET " + r + "\n";
        $$ += "WRITE\n";

        freeRegister(r);
        lastUsedRegister.pop();
    }
;

proc_head:
    pidentifier LPAR args_decl RPAR {
        procedureAlias[$1] = varPrefix;
        numberOfArguments[varPrefix] = argId;
        argId = 0;
        $$ = $1;
    }
;

proc_call:
    pidentifier LPAR args RPAR {
        std::string procId = procedureAlias[$1];
        unsigned long long returnAddr = getAddress(procId + "@return");
        std::string r1 = takeFirstAvailableRegisterNotA();  
        std::string r2 = takeFirstAvailableRegisterNotA();

        $$ = "# call " + procId + "\n";

        // Dla każdego argumentu w wywołaniu funkcji
        if(argsVector.size() != getNumberOfArguments(procId))
        {
            std::cerr << "Niepoprawna liczba argumentów w wywołaniu funkcji w linii " << yylineno << std::endl;
            throw "NumberOfArgumentsError";
        }
        for(int j = 0; j < argsVector.size(); j++)
        {
            std::string targetName = procId + "arg" + std::to_string(j);
            targetName = argsAlias[targetName];
            std::string sourceName = argsVector[j];

            unsigned long long sourceAddr = getAddress(sourceName);
            unsigned long long targetAddr = getAddress(targetName);

            $$ += insertingNumber("a", sourceAddr);
            if (isArgument[sourceName])
                $$ += "LOAD a\n";
            $$ += insertingNumber(r1, targetAddr);
            $$ += "STORE " + r1 + "\n";
        }

        $$ += insertingNumber(r1, returnAddr);
        $$ += "RST " + r2 + "\n";
        $$ += "INC " + r2 + "\n";
        $$ += "SHL " + r2 + "\n";
        $$ += "SHL " + r2 + "\n";
        $$ += "STRK a\n";
        $$ += "ADD " + r2 + "\n";
        $$ += "STORE " + r1 + "\n";
        $$ += "JUMP @" + procId + "\n";

        $$ += "# end of call\n";

        freeRegister(r1);
        freeRegister(r2);
        argsVector.clear();
    }
;

declarations:
    declarations COMMA pidentifier {
        variableMap[varPrefix + $3] = currentVarAddress;
        isArgument[varPrefix + $3] = false;
        currentVarAddress++;
    }
    | declarations COMMA pidentifier LSPAR num RSPAR {
        variableMap[varPrefix + $3] = currentVarAddress;
        isArgument[varPrefix + $3] = false;
        currentVarAddress += stoull($5);
    }
    | pidentifier {
        variableMap[varPrefix + $1] = currentVarAddress;
        isArgument[varPrefix + $1] = false;
        currentVarAddress++;
    }
    | pidentifier LSPAR num RSPAR {
        variableMap[varPrefix + $1] = currentVarAddress;
        isArgument[varPrefix + $1] = false;
        currentVarAddress += stoull($3);
    }
;

args_decl:
    args_decl COMMA pidentifier {
        variableMap[varPrefix + $3] = currentVarAddress;
        isArgument[varPrefix + $3] = true;
        currentVarAddress++;

        argsAlias[varPrefix + "arg" + std::to_string(argId)] = varPrefix + $3;
        argId++;
    }
    | args_decl COMMA T pidentifier {
        variableMap[varPrefix + $4] = currentVarAddress;
        isArgument[varPrefix + $4] = true;
        currentVarAddress++;

        argsAlias[varPrefix + "arg" + std::to_string(argId)] = varPrefix + $4;
        argId++;
    }
    | pidentifier {
        variableMap[varPrefix + $1] = currentVarAddress;
        isArgument[varPrefix + $1] = true;
        currentVarAddress++;

        argsAlias[varPrefix + "arg" + std::to_string(argId)] = varPrefix + $1;
        argId++;
    }
    | T pidentifier {
        variableMap[varPrefix + $2] = currentVarAddress;
        isArgument[varPrefix + $2] = true;
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
    }
    | value ASTERISK value {
        std::string c = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string b = lastUsedRegister.top();
        std::string d = takeFirstAvailableRegisterNotA();
        freeRegister(c);
        freeRegister(d);

        std::string line6 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line14 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line15 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line26 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line29 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line32 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = $1 + $3;
        $$ += "# mnożenie\n";
        $$ += "GET " + b + "\n";
        $$ += "JZERO " + line32 + "\n";
        $$ += "GET " + c + "\n";
        $$ += "JPOS " + line6 + "\n";
        $$ += "RST " + b + "\n";
        $$ += "JUMP " + line32 + "\n";
        $$ += line6 + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JZERO " + line14 + "\n";
        $$ += "GET " + b + "\n";
        $$ += "PUT " + d + "\n";
        $$ += "GET " + c + "\n";
        $$ += "PUT " + b + "\n";
        $$ += "GET " + d + "\n";
        $$ += "PUT " + c + "\n";
        $$ += line14 + "\n";
        $$ += "RST " + d + "\n";
        $$ += line15 + "\n";
        $$ += "GET " + c + "\n";
        $$ += "DEC a\n";
        $$ += "JZERO " + line29 + "\n";
        $$ += "GET " + c + "\n";
        $$ += "SHR " + c + "\n";
        $$ += "SHL " + c + "\n";
        $$ += "SUB " + c + "\n";
        $$ += "JZERO " + line26 + "\n";
        $$ += "GET " + b + "\n";
        $$ += "ADD " + d + "\n";
        $$ += "PUT " + d + "\n";
        $$ += line26 + "\n";
        $$ += "SHL " + b + "\n";
        $$ += "SHR " + c + "\n";
        $$ += "JUMP " + line15 + "\n";
        $$ += line29 + "\n";
        $$ += "GET " + b + "\n";
        $$ += "ADD " + d + "\n";
        $$ += "PUT " + b + "\n";
        $$ += line32 + "\n";
    }
    | value SLASH value {
        std::string c = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string b = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string d = takeFirstAvailableRegisterNotA();
        std::string e = takeFirstAvailableRegisterNotA();

        std::string line15 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line21 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line27 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line40 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = $1 + $3;
        $$ += "# dzielenie\n";
        $$ += "RST " + d + "\n";
        $$ += "GET " + b + "\n";
        $$ += "JZERO " + line40 + "\n";
        $$ += "PUT " + d + "\n";
        $$ += "RST " + b + "\n";
        $$ += "GET " + c + "\n"; 
        $$ += "DEC a\n"; 
        $$ += "JZERO " + line40 + "\n";
        $$ += "GET " + d + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "RST " + d + "\n"; 
        $$ += "GET " + c + "\n"; 
        $$ += "SUB " + b + "\n"; 
        $$ += "JPOS " + line40 + "\n";
        $$ += "RST " + e + "\n"; 
        $$ += line15 + "\n";
        $$ += "GET " + c + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JPOS " + line21 + "\n";
        $$ += "SHL " + c + "\n"; 
        $$ += "INC " + e + "\n";
        $$ += "JUMP " + line15 + "\n";
        $$ += line21 + "\n";
        $$ += "SHR " + c + "\n"; 
        $$ += "DEC " + e + "\n"; 
        $$ += "INC " + d + "\n"; 
        $$ += "GET " + b + "\n"; 
        $$ += "SUB " + c + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += line27 + "\n";
        $$ += "GET " + e + "\n";
        $$ += "JZERO " + line40 + "\n";
        $$ += "SHL " + d + "\n"; 
        $$ += "DEC " + e + "\n"; 
        $$ += "SHR " + c + "\n";
        $$ += "GET " + c + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JPOS " + line27 + "\n";
        $$ += "INC " + d + "\n"; 
        $$ += "GET " + b + "\n"; 
        $$ += "SUB " + c + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "JUMP " + line27 + "\n";
        $$ += line40 + "\n";

        lastUsedRegister.push(d);
        freeRegister(b);
        freeRegister(c);
        freeRegister(e);
    }
    | value PERCENT value {
        std::string c = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string b = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string d = takeFirstAvailableRegisterNotA();
        std::string e = takeFirstAvailableRegisterNotA();

        std::string line15 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line21 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line27 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string line40 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = $1 + $3;
        $$ += "# reszta\n";
        $$ += "RST " + d + "\n";
        $$ += "GET " + b + "\n";
        $$ += "JZERO " + line40 + "\n";
        $$ += "PUT " + d + "\n";
        $$ += "RST " + b + "\n";
        $$ += "GET " + c + "\n"; 
        $$ += "DEC a\n"; 
        $$ += "JZERO " + line40 + "\n";
        $$ += "GET " + d + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "RST " + d + "\n"; 
        $$ += "GET " + c + "\n"; 
        $$ += "SUB " + b + "\n"; 
        $$ += "JPOS " + line40 + "\n";
        $$ += "RST " + e + "\n"; 
        $$ += line15 + "\n";
        $$ += "GET " + c + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JPOS " + line21 + "\n";
        $$ += "SHL " + c + "\n"; 
        $$ += "INC " + e + "\n";
        $$ += "JUMP " + line15 + "\n";
        $$ += line21 + "\n";
        $$ += "SHR " + c + "\n"; 
        $$ += "DEC " + e + "\n"; 
        $$ += "INC " + d + "\n"; 
        $$ += "GET " + b + "\n"; 
        $$ += "SUB " + c + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += line27 + "\n";
        $$ += "GET " + e + "\n";
        $$ += "JZERO " + line40 + "\n";
        $$ += "SHL " + d + "\n"; 
        $$ += "DEC " + e + "\n"; 
        $$ += "SHR " + c + "\n";
        $$ += "GET " + c + "\n";
        $$ += "SUB " + b + "\n";
        $$ += "JPOS " + line27 + "\n";
        $$ += "INC " + d + "\n"; 
        $$ += "GET " + b + "\n"; 
        $$ += "SUB " + c + "\n"; 
        $$ += "PUT " + b + "\n"; 
        $$ += "JUMP " + line27 + "\n";
        $$ += line40 + "\n";

        lastUsedRegister.push(b);
        freeRegister(c);
        freeRegister(d);
        freeRegister(e);
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

        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string addr2 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = $1 + $4;
        $$ += "GET " + r1 + "\n";
        $$ += "SUB " + r4 + "\n";
        $$ += "PUT " + rt + "\n";
        $$ += "GET " + r4 + "\n";
        $$ += "SUB " + r1 + "\n";
        $$ += "ADD " + rt + "\n";

        $$ += "JPOS " + addr1 + "\n";
        $$ += "INC a\n";
        $$ += "JUMP " + addr2 + "\n";
        $$ += addr1 + "\n";
        $$ += "RST a\n"; 
        $$ += addr2 + "\n";
    }
    | value MORE value {
        std::string r3 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();

        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string addr2 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        
        $$ = $1 + $3;
        $$ += "GET " + r1 + "\n";
        $$ += "SUB " + r3 + "\n";

        $$ += "JPOS " + addr1 + "\n";
        $$ += "INC a\n";
        $$ += "JUMP " + addr2 + "\n";
        $$ += addr1 + "\n";
        $$ += "RST a\n"; 
        $$ += addr2 + "\n";

        freeRegister(r1);
        freeRegister(r3);
    }
    | value LESS value {
        std::string r3 = lastUsedRegister.top();
        lastUsedRegister.pop();
        std::string r1 = lastUsedRegister.top();
        lastUsedRegister.pop();
        
        std::string addr1 = addressPrefix + std::to_string(jumpId);
        jumpId++;
        std::string addr2 = addressPrefix + std::to_string(jumpId);
        jumpId++;

        $$ = $1 + $3;
        $$ += "#LESS\n";
        $$ += "GET " + r3 + "\n";
        $$ += "SUB " + r1 + "\n";


        $$ += "JPOS " + addr1 + "\n";
        $$ += "INC a\n";
        $$ += "JUMP " + addr2 + "\n";
        $$ += addr1 + "\n";
        $$ += "RST a\n"; 
        $$ += addr2 + "\n";

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

        freeRegister(r1);
        freeRegister(r4);
    }
;

value:
    num {
        unsigned long long x = stoull($1);
        std::string r = takeFirstAvailableRegisterNotA();

        $$ = insertingNumber(r, x);

        lastUsedRegister.push(r);
    }
    | identifier {
        $$ = $1;
        $$ += "LOAD " + lastUsedRegister.top() + "\n";
        $$ += "PUT " + lastUsedRegister.top() + "\n";
    }
;

identifier:
    pidentifier { 
        std::string r = takeFirstAvailableRegisterNotA();  
        std::string varName = varPrefix + $1;
        unsigned long long varAddress = getAddress(varName);

        $$ = insertingNumber(r, varAddress);

        if (isArgument[varName])
        {
            $$ += "LOAD " + r + "\n";
            $$ += "PUT " + r + "\n";
        }

        lastUsedRegister.push(r);
        }
    | pidentifier LSPAR num RSPAR { 
        std::string r = takeFirstAvailableRegisterNotA();
        std::string varName = varPrefix + $1;
        unsigned long long varAddress = getAddress(varName);
        unsigned long long offset = stoull($3);

        if (isArgument[varName])
        {
            $$ = insertingNumber(r, varAddress);
            $$ += "LOAD " + r + "\n";
            $$ += "PUT " + r + "\n";
            $$ += insertingNumber("a", offset);
            $$ += "ADD " + r + "\n";
            $$ += "PUT " + r + "\n";
        }
        else 
        {
            $$ = insertingNumber(r, varAddress + offset);
        }

        lastUsedRegister.push(r);
        }
    | pidentifier LSPAR pidentifier RSPAR  { 
        std::string r = takeFirstAvailableRegisterNotA();  
        std::string tabName = varPrefix + $1;
        std::string offsetName = varPrefix + $3;
        unsigned long long tabAddress = getAddress(tabName);
        unsigned long long offsetAddress = getAddress(offsetName);

        $$ = insertingNumber(r, tabAddress);
        if (isArgument[tabName])
        {
            $$ += "LOAD " + r + "\n";
            $$ += "PUT " + r + "\n";
        }

        $$ += insertingNumber("a", offsetAddress);
        if (isArgument[offsetName])
            $$ += "LOAD a\n";

        $$ += "LOAD a\n";
        $$ += "ADD " + r + "\n";
        $$ += "PUT " + r + "\n";

        lastUsedRegister.push(r);
        }
;
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

unsigned long long getAddress(std::string var)
{
    std::map<std::string, unsigned long long>::iterator it;
    it = variableMap.find(var);
    if(it != variableMap.end())
    {
        return it->second;
    }
    std::cerr << "Próba dostępu do niezadeklarowanej zmiennej \"" << var << "\" w linii " << yylineno << std::endl;
    throw "VariableError";
}

int getNumberOfArguments(std::string procedureName)
{
    std::map<std::string, int>::iterator it;
    it = numberOfArguments.find(procedureName);
    if(it != numberOfArguments.end())
        return it->second;
    std::cerr << "Próba wywołania niezadeklarowanej procedury \"" << procedureName << "\" w linii " << yylineno << std::endl;
    throw "ProcedureError";
}

int yyerror(char const* s)
{
    std::cerr << "Error: " << s << " at line " << yylineno << std::endl;	
    return 0;
}

int main(int argc, char const *argv[])
{

    if(argc != 3)
    {
        std::cout << "Poprawna składnia: \n\t./kompilator <plik źródłowy> <nazwa pliku docelowego>" << std::endl;
        return 44;
    }

    // Otworzenie pliku wejściowego
    yyin = fopen(argv[1], "r");

    for(int i = 0; i < 8; i++)
    {
        availableRegister[i] = true;
    }

    yyparse();

    printCmd(endResult, argv[2]);
    return 0;
}
