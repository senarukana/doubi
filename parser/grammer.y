%{

package parser

import (
       "github.com/jxwr/doubi/ast"
       "github.com/jxwr/doubi/token"
)

var ProgramAst []ast.Stmt

type Tok struct {
    Lit string
    Line int
    Col int
    Pos token.Pos
}

func (t Tok) String() string {
    return t.Lit
}

%}

// fields inside this union end up as the fields in a structure known
// as ${PREFIX}SymType, of which a reference is passed to the lexer.
%union {
    node ast.Node
    expr ast.Expr
    expr_list []ast.Expr
    stmt ast.Stmt
    stmt_list []ast.Stmt
    field *ast.Field
    field_list []*ast.Field
    ident_list []*ast.Ident
    tok Tok
}

%type <expr> expr ident basiclit
%type <expr> paren_expr selector_expr index_expr slice_expr func_decl_expr
%type <expr> call_expr unary_expr binary_expr array_expr dict_expr set_expr
%type <expr_list> expr_list
%type <field> field_pair
%type <field_list> field_list
%type <ident_list> ident_list

%type <stmt> stmt expr_stmt send_stmt incdec_stmt assign_stmt go_stmt
%type <stmt> return_stmt branch_stmt block_stmt if_stmt 
%type <stmt> case_clause case_block switch_stmt select_stmt for_stmt range_stmt
%type <stmt_list> stmt_list case_clause_list prog

%token <tok> EOF EOL COMMENT
%token <tok> IDENT INT FLOAT STRING CHAR 
%token <tok> SHL SHR AND_NOT 
%token <tok> ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token <tok> AND_ASSIGN OR_ASSIGN XOR_ASSIGN SHL_ASSIGN SHR_ASSIGN AND_NOT_ASSIGN
%token <tok> LAND LOR ARROW INC DEC EQL
%token <tok> NEQ LEQ GEQ DEFINE ELLIPSIS ADD SUB MUL QUO REM AND OR XOR
%token <tok> LSS GTR ASSIGN NOT 
%token <tok> LPAREN LBRACK LBRACE COMMA PERIOD RPAREN RBRACK RBRACE
%token <tok> SEMICOLON COLON

%token <tok> BREAK CASE CHAN CONTINUE CONST
%token <tok> DEFAULT DEFER ELSE FALLTHROUGH FOR
%token <tok> FUNC GO GOTO IF IMPORT INTERFACE MAP PACKAGE RANGE RETURN 
%token <tok> SELECT STRUCT SWITCH TYPE VAR 

%left LAND LOR ARROW
%left SHL SHR AND_NOT 
%left OR
%left AND XOR
%left ADD SUB
%left NEQ LEQ GEQ EQL
%left MUL QUO REM
%left LSS GTR
%left NOT 
%left INC DEC
%left UMINUS
%left LPAREN
%left LBRACK
%left PERIOD

%right ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN AND_ASSIGN OR_ASSIGN XOR_ASSIGN SHL_ASSIGN SHR_ASSIGN AND_NOT_ASSIGN DEFINE

%start prog

%%

ident : IDENT				{ $$ = &ast.Ident{$1.Pos, $1.Lit} }

basiclit : INT				{ $$ = &ast.BasicLit{$1.Pos, token.INT, $1.Lit} }
	 | FLOAT			{ $$ = &ast.BasicLit{$1.Pos, token.FLOAT, $1.Lit} }
	 | STRING 			{ $$ = &ast.BasicLit{$1.Pos, token.STRING, $1.Lit} }
	 | CHAR				{ $$ = &ast.BasicLit{$1.Pos, token.CHAR, $1.Lit} }

paren_expr : LPAREN expr RPAREN		{ $$ = &ast.ParenExpr{$1.Pos, $2, $3.Pos} }

selector_expr : expr PERIOD ident      	{ $$ = &ast.SelectorExpr{$1, $3.(*ast.Ident)} }

slice_expr : expr LBRACK expr COLON expr RBRACK	
	     { $$ = &ast.SliceExpr{$1, $2.Pos, $3, $5, $6.Pos} }
           | expr LBRACK COLON expr RBRACK	
	     { $$ = &ast.SliceExpr{$1, $2.Pos, nil, $4, $5.Pos} }
           | expr LBRACK expr COLON RBRACK	
	     { $$ = &ast.SliceExpr{$1, $2.Pos, $3, nil, $5.Pos} }

index_expr : expr LBRACK expr RBRACK    
	     { $$ = &ast.IndexExpr{$1, $2.Pos, $3, $2.Pos} }

expr_list : /* empty */		      	  { $$ = []ast.Expr{} }
	  | expr			  { $$ = []ast.Expr{$1} }
	  | expr_list COMMA expr	  { $$ = append($1, $3) }
	  | expr_list COMMA EOL expr	  { $$ = append($1, $4) }

call_expr : expr LPAREN expr_list RPAREN  { $$ = &ast.CallExpr{$1, 0, $3, 0} }

unary_expr : SUB expr %prec UMINUS	  { $$ = &ast.UnaryExpr{0, token.SUB, $2 } }

binary_expr : expr ADD expr 		  { $$ = &ast.BinaryExpr{$1, 0, token.ADD, $3 } }
            | expr SUB expr		  { $$ = &ast.BinaryExpr{$1, 0, token.SUB, $3 } }
            | expr MUL expr		  { $$ = &ast.BinaryExpr{$1, 0, token.MUL, $3 } }
            | expr QUO expr		  { $$ = &ast.BinaryExpr{$1, 0, token.QUO, $3 } }
            | expr REM expr		  { $$ = &ast.BinaryExpr{$1, 0, token.REM, $3 } }
            | expr AND expr		  { $$ = &ast.BinaryExpr{$1, 0, token.AND, $3 } }
            | expr OR expr		  { $$ = &ast.BinaryExpr{$1, 0, token.OR, $3 } }
            | expr XOR expr		  { $$ = &ast.BinaryExpr{$1, 0, token.XOR, $3 } }
            | expr SHL expr		  { $$ = &ast.BinaryExpr{$1, 0, token.SHL, $3 } }
            | expr SHR expr		  { $$ = &ast.BinaryExpr{$1, 0, token.SHR, $3 } }
            | expr AND_NOT expr		  { $$ = &ast.BinaryExpr{$1, 0, token.AND_NOT, $3 } }
            | expr LSS expr		  { $$ = &ast.BinaryExpr{$1, 0, token.LSS, $3 } }
            | expr GTR expr		  { $$ = &ast.BinaryExpr{$1, 0, token.GTR, $3 } }
            | expr NEQ expr		  { $$ = &ast.BinaryExpr{$1, 0, token.NEQ, $3 } }
            | expr LEQ expr		  { $$ = &ast.BinaryExpr{$1, 0, token.LEQ, $3 } }
            | expr GEQ expr		  { $$ = &ast.BinaryExpr{$1, 0, token.GEQ, $3 } }
            | expr EQL expr		  { $$ = &ast.BinaryExpr{$1, 0, token.EQL, $3 } }

            | expr LAND expr		  { $$ = &ast.BinaryExpr{$1, 0, token.LAND, $3 } }
            | expr LOR expr		  { $$ = &ast.BinaryExpr{$1, 0, token.LOR, $3 } }

array_expr : LBRACK expr_list RBRACK
	     { $$ = &ast.ArrayExpr{0, $2, 0} }
	   | LBRACK EOL expr_list EOL RBRACK
	     { $$ = &ast.ArrayExpr{0, $3, 0} }
	   | LBRACK EOL expr_list RBRACK
	     { $$ = &ast.ArrayExpr{0, $3, 0} }

set_expr : '#' LBRACK expr_list RBRACK
	   { $$ = &ast.SetExpr{0, $3, 0} }
	 | '#' LBRACK EOL expr_list EOL RBRACK
	   { $$ = &ast.SetExpr{0, $4, 0} }
	 | '#' LBRACK EOL expr_list RBRACK
	   { $$ = &ast.SetExpr{0, $4, 0} }

field_pair : expr COLON expr
	     { $$ = &ast.Field{$1, 0, $3} }

field_list : /* empty */			    { $$ = []*ast.Field{} } 
	   | field_pair	     		     	    { $$ = []*ast.Field{$1} } 
	   | field_list EOL field_pair	       	    { $$ = append($1, $3) }
	   | field_list COMMA field_pair	    { $$ = append($1, $3) }
	   | field_list COMMA EOL field_pair	    { $$ = append($1, $4) }
	   | field_list EOL	     		    { $$ = $1 }
	   | field_list COMMA EOL	     	    { $$ = $1 }

dict_expr : '#' LBRACE field_list RBRACE
	    { $$ = &ast.DictExpr{0, $3, 0} }

ident_list : /* empty */
   	     { $$ = []*ast.Ident{} }
	   | IDENT
	     { $$ = []*ast.Ident{&ast.Ident{0, $1.Lit}} }
	   | ident_list COMMA IDENT
	     { $$ = append($1, &ast.Ident{0, $3.Lit}) }

func_decl_expr : FUNC LPAREN ident_list RPAREN block_stmt
                 { $$ = &ast.FuncDeclExpr{0, nil, nil, nil, $3, $5.(*ast.BlockStmt), []string{}} }
	       | FUNC IDENT LPAREN ident_list RPAREN block_stmt
                 { $$ = &ast.FuncDeclExpr{0, nil, nil, &ast.Ident{0, $2.Lit}, $4, $6.(*ast.BlockStmt), []string{}} }
	       | FUNC LPAREN IDENT IDENT RPAREN IDENT LPAREN ident_list RPAREN block_stmt
	       	 { $$ = &ast.FuncDeclExpr{0, &ast.Ident{0, $3.Lit}, &ast.Ident{0, $4.Lit},
                                          &ast.Ident{0, $6.Lit}, $8, $10.(*ast.BlockStmt), []string{}} }

expr : ident
     | basiclit
     | paren_expr
     | selector_expr
     | index_expr
     | slice_expr
     | call_expr
     | unary_expr
     | binary_expr
     | array_expr
     | dict_expr
     | set_expr
     | func_decl_expr

/// stmts

expr_stmt : expr			{ $$ = &ast.ExprStmt{$1} }

send_stmt : expr ARROW expr		{ $$ = &ast.SendStmt{$1, 0, $3} }

incdec_stmt : expr INC 			{ $$ = &ast.IncDecStmt{$1, 0, token.INC} }
            | expr DEC			{ $$ = &ast.IncDecStmt{$1, 0, token.DEC} }

assign_stmt : expr_list ASSIGN expr_list       		{ $$ = &ast.AssignStmt{$1, 0, token.ASSIGN, $3} }
	    | expr_list ADD_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.ADD_ASSIGN, $3} }
	    | expr_list SUB_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.SUB_ASSIGN, $3} }
	    | expr_list MUL_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.MUL_ASSIGN, $3} }
	    | expr_list QUO_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.QUO_ASSIGN, $3} }
	    | expr_list REM_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.REM_ASSIGN, $3} }
	    | expr_list AND_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.AND_ASSIGN, $3} }
	    | expr_list OR_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.OR_ASSIGN, $3} }
	    | expr_list XOR_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.XOR_ASSIGN, $3} }
	    | expr_list SHL_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.SHL_ASSIGN, $3} }
	    | expr_list SHR_ASSIGN expr_list		{ $$ = &ast.AssignStmt{$1, 0, token.SHR_ASSIGN, $3} }
	    | expr_list AND_NOT_ASSIGN expr_list	{ $$ = &ast.AssignStmt{$1, 0, token.AND_NOT_ASSIGN, $3} }

go_stmt : GO call_expr
	  { $$ = &ast.GoStmt{0, $2.(*ast.CallExpr)} }

return_stmt : RETURN expr_list
	      { $$ = &ast.ReturnStmt{0, $2} }

branch_stmt : BREAK				{ $$ = &ast.BranchStmt{0, token.BREAK} }
	     | CONTINUE				{ $$ = &ast.BranchStmt{0, token.CONTINUE } }

block_stmt : LBRACE stmt_list RBRACE		{ $$ = &ast.BlockStmt{0, $2 ,0} }

if_stmt : IF expr block_stmt  			{ $$ = &ast.IfStmt{0, $2, $3.(*ast.BlockStmt), nil} }
	| IF expr block_stmt ELSE stmt		{ $$ = &ast.IfStmt{0, $2, $3.(*ast.BlockStmt), $5} }

case_clause : CASE expr_list COLON stmt_list	{ $$ = &ast.CaseClause{0, $2, 0, $4} }
            | DEFAULT COLON stmt_list           { $$ = &ast.CaseClause{0, nil, 0, $3} }

case_clause_list : EOL	     	   		{ $$ = []ast.Stmt{} }
		 | case_clause	   		{ $$ = []ast.Stmt{$1} }
		 | case_clause_list case_clause { $$ = append($1, $2) }

case_block : LBRACE case_clause_list RBRACE	{ $$ = &ast.BlockStmt{0, $2, 0} }

switch_stmt : SWITCH stmt case_block		{ $$ = &ast.SwitchStmt{0, $2, $3.(*ast.BlockStmt)} }

select_stmt : SELECT case_block			{ $$ = &ast.SelectStmt{0, $2.(*ast.BlockStmt)} }

for_stmt : FOR stmt SEMICOLON expr SEMICOLON stmt block_stmt
	   { $$ = &ast.ForStmt{0, $2, $4, $6, $7.(*ast.BlockStmt)} }
         | FOR SEMICOLON expr SEMICOLON stmt block_stmt
	   { $$ = &ast.ForStmt{0, nil, $3, $5, $6.(*ast.BlockStmt)} }
         | FOR expr block_stmt
	   { $$ = &ast.ForStmt{0, nil, $2, nil, $3.(*ast.BlockStmt)} }

range_stmt : FOR expr_list ASSIGN RANGE expr block_stmt 
	     { $$ = &ast.RangeStmt{0, $2, $5, $6.(*ast.BlockStmt)} }

stmt : expr_stmt
     | send_stmt
     | incdec_stmt
     | assign_stmt
     | go_stmt
     | return_stmt
     | branch_stmt
     | block_stmt
     | if_stmt
     | switch_stmt
     | select_stmt
     | for_stmt
     | range_stmt

stmt_list : /* empty */			{ $$ = []ast.Stmt{} }
	  | stmt			{ $$ = []ast.Stmt{$1} }
	  | stmt_list EOL stmt		{ $$ = append($1, $3) }
	  | stmt_list SEMICOLON stmt	{ $$ = append($1, $3) }
	  | stmt_list EOL		{ $$ = $1 }

/// program

prog : stmt_list EOL
       { ProgramAst = $1 }

