%option noyywrap
%option yylineno

%{
    #include <iostream>
    #include <string>
    #include "kompilator_y.hpp"
    int yylex();
%}

%%
\n ;
[ \t]+ 	;
^[ \t]*\#.*\n ;
"PROCEDURE" { return PROCEDURE; }
"IS"        { return IS; }
"IN"        { return IN; }
"END"       { return END; }
"PROGRAM"   { return PROGRAM; }
"IF"        { return IF; }
"THEN"      { return THEN; }
"ELSE"      { return ELSE; }
"ENDIF"     { return ENDIF; }
"WHILE"     { return WHILE; }
"DO"        { return DO; }
"ENDWHILE"  { return ENDWHILE; }
"REPEAT"    { return REPEAT; }
"UNTIL"     { return UNTIL; }
"READ"      { return READ; }
"WRITE"     { return WRITE; }
"T"         { return T; }

[_a-z]+     { yylval = std::string(yytext); return pidentifier; }
[0-9]+      { yylval = std::string(yytext); return num; }
","         { return COMMA; }
";"         { return SEMICOLON; }
":"         { return COLON; }
"="         { return EQUAL; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return ASTERISK; }
"/"         { return SLASH; }
"%"         { return PERCENT; }
">"         { return MORE; }
"<"         { return LESS; }
"!"         { return NEGATION; }
"("         { return LPAR; }
")"         { return RPAR; }
"["         { return LSPAR; }
"]"         { return RSPAR; }
%%
