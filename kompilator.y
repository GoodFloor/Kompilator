%{
    #include <stdio.h>
    #include <algorithm>
    #include <iostream>
    #include <map>
    #include <stack>
    #include <string>
    #include "utils.hpp"

    extern int yylineno;
    extern FILE* yyin;

    int yylex(void);
    int yyerror(char const*);
    std::string takeFirstAvailableRegister();
    std::string takeFirstAvailableRegisterNotA();
    void freeRegister(std::string rx);
    void printCmd(std::string cmd);
    int countLines(std::string s);


    int generatedLines = 0;
    int currentProcedureId = 0;
    int currentVarAddress = 0;
    std::string varPrefix = "proc" + std::to_string(currentProcedureId) + "_";
    std::map<std::string, int> variableMap;
    bool availableRegister[8];
    std::stack<std::string> lastUsedRegister;
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
    procedures main
;

procedures:
    procedures PROCEDURE proc_head IS declarations IN commands END { 
        currentProcedureId++;
        varPrefix = "proc" + std::to_string(currentProcedureId) + "_"; 
        }
    | procedures PROCEDURE proc_head IS IN commands END { 
        currentProcedureId++;
        varPrefix = "proc" + std::to_string(currentProcedureId) + "_"; 
        }
    | 
;

main:
    PROGRAM IS declarations IN commands END {
        printCmd($5);
    }
    | PROGRAM IS IN commands END {
        printCmd($4);
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
        int loopBegin = generatedLines - countLines($2) - countLines($4);
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
    | proc_call SEMICOLON
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
    pidentifier LPAR args_decl RPAR
;

proc_call:
    pidentifier LPAR args RPAR
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
    args_decl COMMA pidentifier
    | args_decl COMMA T pidentifier
    | pidentifier
    | T pidentifier
;

args:
    args COMMA pidentifier
    | pidentifier
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
    | value ASTERISK value
    | value SLASH value
    | value PERCENT value
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
    pidentifier { 
        std::string r = takeFirstAvailableRegisterNotA();  
        std::string varName = varPrefix + $1;
        // TODO: Sprawdź czy zmienna istnieje
        int varAddress = variableMap[varName];
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
        int varAddress = variableMap[varName];
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
    | pidentifier LSPAR pidentifier RSPAR 
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

std::string takeFirstAvailableRegister()
{
    for(int i = 0; i < 8; i++)
        if(availableRegister[i])
        {
            availableRegister[i] = false;
            std::string s(1, ('a' + i));
            return s;
        }
            
    throw "Brak wolnych rejestrów";
}

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

int countLines(std::string s)
{
    return std::count(s.begin(), s.end(), '\n');
}

void printCmd(std::string cmd)
{
    std::cout << cmd;
    /* generatedLines += countLines(cmd); */
}

int yyerror(char const* s)
{
    printf("Error: %s at line %d\n", s, yylineno);	
    return 0;
}

int main(int argc, char const *argv[])
{
    // Otworzenie pliku wejściowego i wyjściowego
    if(argc > 1) 
    {
        FILE* f;
        f = fopen(argv[1], "r");
        yyin = f;
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
    printCmd("HALT\n");
    /* printf("Przeczytano %d linii\n", yylineno); */
    /* std::map<std::string, int>::iterator it = variableMap.begin();
    while(it != variableMap.end()) {
        std::cout << "map[" << it->first << "] = " << it->second << std::endl;
        ++it;
    } */
    return 0;
}
