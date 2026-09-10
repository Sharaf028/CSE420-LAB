%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table* symbt_table;

// create your symbol table here.
// You can store the pointer to your symbol table in a global variable
// or you can create an object

int lines = 1;

ofstream outlog;
ofstream outerr;

int error_count = 0;

// you may declare other necessary variables here to store necessary info
// such as current variable type, variable list, function name, return type, function parameter types, parameters names etc.

struct variable_data
{
    string name;
    bool isArray;
    int size;
};

vector<variable_data> variable_list;
string current_type = "";                            
string func_ret_type = "";
string func_name = "";

vector<string> parameter_names;
vector<string> parameter_types;
vector<string> argument_types;

void yyerror(char *s)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		symbt_table->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"program");
	}
	;

unit : variable_decl
	 {
		outlog<<"At line no: "<<lines<<" unit : variable_decl "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN param_list RPAREN
		{
			// Insert the function symbol into the CURRENT (outer) scope now,
			// before entering the function's own scope.
			symbol_info *func = new symbol_info($2->getname(),"ID");

			func->set_symbol_type("function");
			func->set_return_type($1->getname()); 
			func_name = $2->getname();

			for(size_t i=0;i<parameter_names.size();i++)
			{
				func->add_parameter(parameter_names[i],parameter_types[i]);
			}

			if(!symbt_table->insert(func))
			{
				outerr<<"At line no: "<<lines<<" Multiple declaration of function "<<$2->getname()<<endl<<endl;
				error_count++;
			}
		}
		compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$4->getname()+")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$4->getname()+")\n"+$7->getname(),"func_def");	
		}
		| type_specifier ID LPAREN RPAREN
		{
			symbol_info *func = new symbol_info($2->getname(),"ID");

			func->set_symbol_type("function");
			func->set_return_type($1->getname());
			func_name = $2->getname();
			// no parameters

			if(!symbt_table->insert(func))
			{
				outerr<<"At line no: "<<lines<<" Multiple declaration of function "<<$2->getname()<<endl<<endl;
				error_count++;
			}
		}
		compound_statement
		{
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$6->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$6->getname(),"func_def");	
		}
 		;
enter_func :
		{
			symbt_table->enter_scope(outlog);

			for(size_t i=0;i<parameter_names.size();i++)
			{
				symbol_info *temp = new symbol_info(parameter_names[i], "ID");
				temp->set_symbol_type("variable");
				temp->set_id_type(parameter_types[i]);

				if(!symbt_table->insert(temp))
				{
					outerr<<"At line no: "<<lines<<" Multiple declaration of variable "<<parameter_names[i]<<" in parameter of "<<func_name<<endl<<endl;
					error_count++;
				}
			}

			parameter_names.clear();
			parameter_types.clear();
		}
		;
param_list : param_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<" "<<$4->getname()<<endl<<endl;
					
			$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
			
			parameter_types.push_back($3->getname());
    		parameter_names.push_back($4->getname());
		}
		| param_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			
			parameter_types.push_back($3->getname());
    		parameter_names.push_back("");
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");

			parameter_types.push_back($1->getname());
    		parameter_names.push_back($2->getname());
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"param_list");

			parameter_types.push_back($1->getname());
    		parameter_names.push_back("");
		}
 		;

compound_statement : LCURL enter_func statements RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
        outlog<<"{\n"<<$3->getname()<<"\n}"<<endl<<endl;

        $$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");

        symbt_table->exit_scope(outlog);
    }
    | LCURL enter_func RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
        outlog<<"{\n}"<<endl<<endl;

        $$ = new symbol_info("{\n}","comp_stmnt");

        symbt_table->exit_scope(outlog);
    }
    ;
variable_decl : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" variable_decl : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_dec");
			
			if(current_type == "void")
			{
				outerr<<"At line no: "<<lines<<" variable type can not be void "<<endl<<endl;
				error_count++;
			}
			
			// Insert necessary information about the variables in the symbol table
			for(size_t i=0;i<variable_list.size();i++)
			{
				symbol_info *temp=new symbol_info(variable_list[i].name,"ID");

				if(variable_list[i].isArray)
				{
					temp->set_symbol_type("array");
					temp->set_array_size(variable_list[i].size);
				}
				else
				{
					temp->set_symbol_type("variable");
				}
				temp->set_id_type(current_type);

				if(!symbt_table->insert(temp))
				{
					outerr<<"At line no: "<<lines<<" Multiple declaration of variable "<<variable_list[i].name<<endl<<endl;
					error_count++;
				}
			}

			variable_list.clear();
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			
			$$ = new symbol_info("int","type");
			 current_type = "int";
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			
			$$ = new symbol_info("float","type");
			 current_type = "float";
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			 current_type = "void";
			
			$$ = new symbol_info("void","type");
	    }
		| CHAR
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : CHAR "<<endl<<endl;
			outlog<<"char"<<endl<<endl;
			
			$$ = new symbol_info("char","type");
			 current_type = "char";
	    }
 		;

declaration_list : declaration_list COMMA ID
    {
        outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
        outlog<<$1->getname()+","<<$3->getname()<<endl<<endl;

        variable_list.push_back({$3->getname(), false, 0});
        $$ = new symbol_info($1->getname()+","+$3->getname(),"declaration_list");
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
        outlog<<$1->getname()+","<<$3->getname()<<"["<<$5->getname()<<"]"<<endl<<endl;

        variable_list.push_back({$3->getname(), true, stoi($5->getname())});
        $$ = new symbol_info($1->getname()+","+$3->getname()+"["+$5->getname()+"]","declaration_list");
    }
    | ID
    {
        outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
        outlog<<$1->getname()<<endl<<endl;

        variable_list.push_back({$1->getname(), false, 0});
        $$ = new symbol_info($1->getname(),"declaration_list");
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
        outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;

        variable_list.push_back({$1->getname(), true, stoi($3->getname())});
        $$ = new symbol_info($1->getname()+"["+$3->getname()+"]","declaration_list");
    }
    ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	   }
	   ;
	   
statement : variable_decl
	  {
	    	outlog<<"At line no: "<<lines<<" statement : variable_decl "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->getname()<<endl<<endl;

            $$ = new symbol_info($1->getname(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->getname()<<");"<<endl<<endl; 

			symbol_info *temp = new symbol_info($3->getname(), "ID");
			symbol_info *found = symbt_table->lookup(temp);

			if(found == NULL)
			{
				outerr<<"At line no: "<<lines<<" Undeclared variable "<<$3->getname()<<endl<<endl;

				error_count++;
			}

			$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->getname()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->getname()+";","expr_stmt");
	        }
			;
	  
variable : ID
{
    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
    outlog<<$1->getname()<<endl<<endl;

    symbol_info *temp = new symbol_info($1->getname(), "ID");
    symbol_info *found = symbt_table->lookup(temp);

    if(found == NULL)
    {
        outerr<<"At line no: "<<lines
              <<" Undeclared variable "
              <<$1->getname()<<endl<<endl;

        error_count++;
    }

    $$ = new symbol_info($1->getname(),"varbl");

    if(found != NULL)
    {
        if(found->get_symbol_type() == "array")
        {
            outerr<<"At line no: "<<lines
                  <<" variable is of array type : "
                  <<$1->getname()<<endl<<endl;

            error_count++;
        }

        if(found->get_symbol_type() == "array")
        {
            // an array used without an index is never a valid scalar
            // value, so it can never satisfy a type comparison
            $$->set_id_type("array");
        }
        else
        {
            $$->set_id_type(found->get_id_type());
        }
        $$->set_symbol_type(found->get_symbol_type());
    }
    else
    {
        // sentinel type so later comparisons don't cascade into extra
        // spurious errors caused by this already-reported problem
        $$->set_id_type("error");
    }
}

		| ID LTHIRD expression RTHIRD 
		{
    	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;

    	outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;

    	symbol_info *temp = new symbol_info($1->getname(), "ID");
    	symbol_info *found = symbt_table->lookup(temp);

    	if(found == NULL)
    		{
        	outerr<<"At line no: "<<lines<<" Undeclared variable "<<$1->getname()<<endl<<endl;

        	error_count++;
    		}
    	else
    	{
        	if(found->get_symbol_type() != "array")
        	{
            	outerr<<"At line no: "<<lines<<" variable is not of array type : "<<$1->getname()<<endl<<endl;

            	error_count++;
        	}

		if($3->get_id_type() != "error"
        	   && ($3->get_id_type() != "int" || found->get_id_type() != "int"))
        	{
            	outerr<<"At line no: "<<lines<<" array index is not of integer type : "<<$1->getname()<<endl<<endl;

            	error_count++;
        	}
    	}

    	$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","varbl");

    	if(found == NULL)
    	{
        	$$->set_id_type("error");
    	}

    	if(found != NULL)
    	{
        	$$->set_id_type(found->get_id_type());
        	$$->set_symbol_type(found->get_symbol_type());
    	}
	}
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"expr");

			$$->set_id_type($1->get_id_type());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

			 if($1->get_id_type() != "error" && $3->get_id_type() != "error"
			    && $1->get_id_type() != "array" && $3->get_id_type() != "array"
			    && $1->get_id_type() != "void" && $3->get_id_type() != "void"
			    && $1->get_id_type() != $3->get_id_type())
    		{
        	// float assigned to int
        	if($1->get_id_type() == "int" && $3->get_id_type() == "float")
        		{
            	outerr<<"At line no: "<<lines<<" Warning: Assignment of float value to int variable"<<endl<<endl;
        		}
        	// int assigned to float: implicit widening, not an error
        	else if($1->get_id_type() == "float" && $3->get_id_type() == "int")
        		{
        		}
        	else
        	{
            	outerr<<"At line no: "<<lines<<" Type mismatch in assignment"<<endl<<endl;

            error_count++;
        	}
    	}

			$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");

			$$->set_id_type($1->get_id_type());
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"lgc_expr");
			$$->set_id_type($1->get_id_type());
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"lgc_expr");
			$$->set_id_type("int");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"rel_expr");
			$$->set_id_type($1->get_id_type());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");
			$$->set_id_type("int");
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"simp_expr");
			$$->set_id_type($1->get_id_type());
			
	      }
		| simple_expression ADDOP term
		{
    		outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
    		outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;

    		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");

    		if($1->get_id_type() == "error" || $3->get_id_type() == "error")
    		{
        	$$->set_id_type("error");
    		}
    		else if($1->get_id_type() == "float" || $3->get_id_type() == "float")
    		{
        	$$->set_id_type("float");
    		}
    		else
    		{
        	$$->set_id_type("int");
    		}
		}
		;
					
term :	unary_expression 
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"term");

			$$->set_id_type($1->get_id_type());
			
	 }
   | term MULOP unary_expression
{
    outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
    outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;

	 if($2->getname() == "%")
    {
        if($1->get_id_type() != "error" && $3->get_id_type() != "error"
           && ($1->get_id_type() != "int" || $3->get_id_type() != "int"))
        {
            outerr<<"At line no: "<<lines<<" Operands of modulus must be integers"<<endl<<endl;

            error_count++;
        }
    }

	if($2->getname() == "/" || $2->getname() == "%")
    {
        if($3->getname() == "0" || $3->getname() == "0.0")
        {
            outerr<<"At line no: "<<lines<<" Division or modulus by zero"<<endl<<endl;

            error_count++;
        }
    }


    $$ = new symbol_info(
        $1->getname()+$2->getname()+$3->getname(),"term");

    if($1->get_id_type() == "error" || $3->get_id_type() == "error")
    {
        $$->set_id_type("error");
    }
    else if($1->get_id_type() == "float" || $3->get_id_type() == "float")
    {
        $$->set_id_type("float");
    }
    else
    {
        $$->set_id_type("int");
    }
	}
    ;

unary_expression : ADDOP unary_expression  
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname(),"un_expr");
			$$->set_id_type($2->get_id_type());
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->getname(),"un_expr");
			$$->set_id_type("int");
	     }
		 | factor_info  
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor_info  "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"un_expr");
			$$->set_id_type($1->get_id_type());
	     }
		 ;
factor_info : factor	{
	    outlog<<"At line no: "<<lines<<" factor_info : factor "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr_info");
		$$->set_id_type($1->get_id_type());
	}	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_id_type($1->get_id_type());
	}
	| ID LPAREN argument_list RPAREN
{
    	outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;

    	outlog<<$1->getname()<<"("<<$3->getname()<<")"<<endl<<endl;

    	symbol_info *temp = new symbol_info($1->getname(), "ID");
    	symbol_info *found = symbt_table->lookup(temp);

    	if(found == NULL)
    	{
        	outerr<<"At line no: "<<lines<<" Undeclared function: "<<$1->getname()<<endl<<endl;

        	error_count++;
    	}
    	else if(found->get_symbol_type() != "function")
    	{
        	outerr<<"At line no: "<<lines<<" "<<$1->getname()<<" is not a function"<<endl<<endl;

        	error_count++;
    	}
    	else
    	{
        if(argument_types.size() != found->get_parameter_types().size())
        {
        	outerr<<"At line no: "<<lines<<" Inconsistencies in number of arguments in function call: "<<$1->getname()<<endl<<endl;

			error_count++;
        }
        else
        {
            for(int i = 0; i < argument_types.size(); i++)
            {
                if(argument_types[i] != "error"
                   && argument_types[i] != found->get_parameter_types()[i])
                {
                    outerr<<"At line no: "<<lines<<" argument "<<i+1<<" type mismatch in function call: "<<$1->getname()<<endl<<endl;

                    error_count++;
                }
            }
        }
    }

    $$ = new symbol_info($1->getname()+"("+$3->getname()+")","fctr");

    if(found != NULL &&
       found->get_symbol_type() == "function")
    {
        $$->set_id_type(found->get_return_type());
    }
    else
    {
        $$->set_id_type("error");
    }
    argument_types.clear();
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->getname()+")","fctr");
		$$->set_id_type($2->get_id_type());
	}
	| CONST_INT 
	{
    	outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
    	outlog<<$1->getname()<<endl<<endl;
        
    	$$ = new symbol_info($1->getname(),"fctr");
    	$$->set_id_type("int");
	}
	| CONST_FLOAT
	{
    	outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
    	outlog<<$1->getname()<<endl<<endl;
        
    	$$ = new symbol_info($1->getname(),"fctr");
    	$$->set_id_type("float");

	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"++","fctr");
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"--","fctr");
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;

				argument_types.push_back($3->get_id_type());
						
				$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;

				argument_types.push_back($1->get_id_type());
						
				$$ = new symbol_info($1->getname(),"arg");
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
    if(argc != 2)
    {
        cout << "Usage: " << argv[0] << " input_file" << endl;
        return 0;
    }

    yyin = fopen(argv[1], "r");

    outlog.open("22201563_22299135_log.txt", ios::trunc);
    outerr.open("22201563_22299135_error.txt", ios::trunc);

    if(yyin == NULL)
    {
        cout<<"Couldn't open file"<<endl;
        return 0;
    }

    lines = 1;
    error_count = 0;

    symbt_table = new symbol_table(10, outlog);

    yyparse();

    outlog << endl<< "Total lines: " << lines << endl;

    outlog << "Total errors: " << error_count << endl;

    outerr << "Total errors: " << error_count << endl;

    outlog.close();
    outerr.close();

    fclose(yyin);

    delete symbt_table;

    return 0;
}