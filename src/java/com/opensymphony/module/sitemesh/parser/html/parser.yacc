

/********** TOKEN DEFINITIONS *********/

%token SLASH WHITESPACE EQUALS QUOTE
%token <sval> WORD TEXT QUOTED    /* string contains text */
%token <ival> LT GT               /* int contains position */
%type <sval> unquoted
%%



/********** GRAMMAR *********/

document:
    node document |
    empty ;

node:
    LT WORD attributes GT                                         { tokenizer.parsedTag(Tag.OPEN,  $2, $1, $4 + 1); } |
    LT SLASH WORD attributes GT                                   { tokenizer.parsedTag(Tag.CLOSE, $3, $1, $5 + 1); } |
    LT WORD attributes SLASH GT                                   { tokenizer.parsedTag(Tag.EMPTY, $2, $1, $5 + 1); } |
    LT whitespace GT                                              { } |
    TEXT                                                          { tokenizer.parsedText($1);           } ;

attributes:
    attributes WORD whitespace EQUALS whitespace unquoted whitespace { tokenizer.parsedAttribute($2, $6  , false); } | /* a=b   */
    attributes WORD whitespace EQUALS whitespace QUOTED   whitespace { tokenizer.parsedAttribute($2, $6  , true);  } | /* a="b" */
    attributes WORD whitespace                                       { tokenizer.parsedAttribute($2, null, false); } | /* a     */
    whitespace ;

unquoted:  /* This is needed to deal with the annoying special case <a something=nasty/slash> */
    unquoted WORD  { $$ = $1 + $2; } |
    unquoted SLASH { $$ = $1 + "/"; } |
    empty          { $$ = ""; };

whitespace:
    WHITESPACE whitespace |
    empty ;

empty:
    /* this space intentionally left blank */ ;



/********** ADDITIONAL JAVA TO MIX INTO PARSER *********/
%%
private HTMLTagTokenizer tokenizer;

public Parser(HTMLTagTokenizer tokenizer, java.io.Reader input) {
    super(input);
    this.tokenizer = tokenizer;
}

public int yylex() {
    try {
        final int result = super.yylex();
        yylval = new Value();
        yylval.sval = yytext();
        yylval.ival = position();
        yylval.line = line();
        yylval.column = column();
        return result;
    }
    catch(java.io.IOException e) {
        return 0;
    }
}

public void yyerror(String error) {
    Value value = val_peek(0);
    reportError(error, value.line, value.column);
}

protected void reportError(String message, int line, int column) {
    tokenizer.error(message, line, column);
}

private class Value {
    String sval;
    int ival;
    int line;
    int column;
}