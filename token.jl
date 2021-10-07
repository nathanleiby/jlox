@enum TokenType begin
    LEFT_PAREN
    RIGHT_PAREN
    LEFT_BRACE
    RIGHT_BRACE
    COMMA
    DOT
    MINUS
    PLUS
    SEMICOLON
    SLASH
    STAR

    BANG
    BANG_EQUAL
    EQUAL
    EQUAL_EQUAL
    GREATER
    GREATER_EQUAL
    LESS
    LESS_EQUAL

    IDENTIFIER
    STRING
    NUMBER

    AND
    CLASS
    ELSE
    FALSE
    FUN
    FOR
    IF
    NIL
    OR
    PRINT
    RETURN
    SUPER
    THIS
    TRUE
    VAR
    WHILE


    EOF
end

struct Token
    type::TokenType
    lexeme::String
    literal::Any
    line::Int
end

keywords = Dict(
    "and" => AND
    ,"class" =>  CLASS
    ,"else" => ELSE
    ,"false" =>  FALSE
    ,"for" => FOR
    ,"fun" => FUN
    ,"if" =>  IF
    ,"nil" => NIL
    ,"or" =>  OR
    ,"print" =>  PRINT
    ,"return" => RETURN
    ,"super" =>  SUPER
    ,"this" => THIS
    ,"true" => TRUE
    ,"var" => VAR
    ,"while" =>  WHILE
)
