%{
    #include <stdio.h>
    #include <algorithm>
    #include <iostream>
    #include <map>
    #include <stack>
    #include <string>

    extern int yylineno;
    extern FILE* yyin;

    int yylex(void);
    int yyerror(char const*);
    std::string takeFirstAvailableRegister();
    std::string takeFirstAvailableRegisterNotA();
    void freeRegister(std::string rx);
    std::string freeRegisterA();
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
    | PROGRAM IS IN commands END
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
        $$ = $1 + $4;
        $$ += "GET " + lastUsedRegister.top() + "\n";
        freeRegister(lastUsedRegister.top());
        lastUsedRegister.pop();
        $$ += "STORE " + lastUsedRegister.top() + "\n";
        freeRegister(lastUsedRegister.top());
        lastUsedRegister.pop();
        generatedLines += countLines($$);
    }
    | IF condition THEN commands ELSE commands ENDIF {
        int lenCondition = countLines($2);
        int lenTrue = countLines($4);
        int lenFalse = countLines($6);
        $$ = "#POCZĄTEK " + std::to_string(generatedLines - lenTrue - lenFalse) + $2;
        int elseBlock = generatedLines - countLines($6) + 1 + 1;
        $$ += "JPOS " + std::to_string(elseBlock) + "\n";
        $$ += "#TRUE " + $4;
        int endif = generatedLines + 3;
        $$ += "JUMP " + std::to_string(endif) + "\n";
        $$ += "#FALSE " + $6 + "#KONIEC\n";
    }
    | IF condition THEN commands ENDIF
    | WHILE condition DO commands ENDWHILE
    | REPEAT commands UNTIL condition SEMICOLON
    | proc_call SEMICOLON
    | READ identifier SEMICOLON {
        $$ = $2;
        $$ += "READ\n";
        $$ += "STORE " + lastUsedRegister.top() + "\n";
        freeRegister(lastUsedRegister.top());
        lastUsedRegister.pop();
        generatedLines += countLines($$);
        // std::errc << generatedLines << std::endl;
    }
    | WRITE value SEMICOLON {
        $$ = $2;
        $$ += "GET " + lastUsedRegister.top() + "\n";
        $$ += "WRITE\n";
        freeRegister(lastUsedRegister.top());
        lastUsedRegister.pop();
        generatedLines += countLines($$);
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
        freeRegister(r3);
        lastUsedRegister.pop();
        $$ = $1 + $3 + "GET " + lastUsedRegister.top() + "\n" + "ADD " + r3 + "\n" + "PUT " + lastUsedRegister.top() + "\n";
    }
    | value MINUS value {
        std::string r3 = lastUsedRegister.top();
        freeRegister(r3);
        lastUsedRegister.pop();
        $$ = $1 + $3 + "GET " + lastUsedRegister.top() + "\n" + "SUB " + r3 + "\n" + "PUT " + lastUsedRegister.top() + "\n";
    }
    | value ASTERISK value
    | value SLASH value
    | value PERCENT value
;

condition:
    value EQUAL value
    | value NEGATION EQUAL value
    | value MORE value
    | value LESS value
    | value MORE EQUAL value
    | value LESS EQUAL value
;

value:
    num {
        int x = stoi($1);
        std::string r = takeFirstAvailableRegisterNotA();

        $$ = "RST " + r + "\n";
        generatedLines++;
        while(x > 0)
        {
            if(x % 2 == 1)
            {
                $$ += "SHL " + r + "\n";
                $$ += "INC " + r + "\n";
                generatedLines += 2;
            }
            else
            {
                $$ += "SHL " + r + "\n";
                generatedLines += 1;
            }
            x /= 2;
        }
        // for(int i = 0; i < x; i++)
        //     $$ += "INC " + r + "\n";

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
        int varAddress = variableMap[varName];
        $$ = "RST " + r + "\n";
        for(int i = 0; i < varAddress; i++)
            $$ += "INC " + r + "\n";   
        lastUsedRegister.push(r);
        }
    | pidentifier LSPAR num RSPAR { 
        std::string r1 = takeFirstAvailableRegisterNotA();
        std::string varName = varPrefix + $1;
        int varAddress = variableMap[varName];
        int offset = stoi($3);
        $$ = "RST " + r1 + "\n";
        for(int i = 0; i < varAddress + offset; i++)
            $$ += "INC " + r1 + "\n";
        lastUsedRegister.push(r1);
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

// Zwalnia rejestr a zwracając rejestr do którego została przeniesiona jego zawartość
std::string freeRegisterA()
{
    if(availableRegister[0])
        return "a";
    std::string rs = takeFirstAvailableRegisterNotA();
    printCmd("PUT " + rs);
    freeRegister("a");
    return rs;
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
