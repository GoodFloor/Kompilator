/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_KOMPILATOR_Y_HPP_INCLUDED
# define YY_YY_KOMPILATOR_Y_HPP_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    PROCEDURE = 258,               /* PROCEDURE  */
    IS = 259,                      /* IS  */
    IN = 260,                      /* IN  */
    END = 261,                     /* END  */
    PROGRAM = 262,                 /* PROGRAM  */
    IF = 263,                      /* IF  */
    THEN = 264,                    /* THEN  */
    ELSE = 265,                    /* ELSE  */
    ENDIF = 266,                   /* ENDIF  */
    WHILE = 267,                   /* WHILE  */
    DO = 268,                      /* DO  */
    ENDWHILE = 269,                /* ENDWHILE  */
    REPEAT = 270,                  /* REPEAT  */
    UNTIL = 271,                   /* UNTIL  */
    READ = 272,                    /* READ  */
    WRITE = 273,                   /* WRITE  */
    T = 274,                       /* T  */
    num = 275,                     /* num  */
    pidentifier = 276,             /* pidentifier  */
    SEMICOLON = 277,               /* SEMICOLON  */
    COMMA = 278,                   /* COMMA  */
    COLON = 279,                   /* COLON  */
    EQUAL = 280,                   /* EQUAL  */
    LPAR = 281,                    /* LPAR  */
    RPAR = 282,                    /* RPAR  */
    LSPAR = 283,                   /* LSPAR  */
    RSPAR = 284,                   /* RSPAR  */
    PLUS = 285,                    /* PLUS  */
    MINUS = 286,                   /* MINUS  */
    SLASH = 287,                   /* SLASH  */
    ASTERISK = 288,                /* ASTERISK  */
    PERCENT = 289,                 /* PERCENT  */
    NEGATION = 290,                /* NEGATION  */
    MORE = 291,                    /* MORE  */
    LESS = 292                     /* LESS  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef std::string YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_KOMPILATOR_Y_HPP_INCLUDED  */
