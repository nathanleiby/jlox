hadError = false

function main()
    if length(ARGS) > 1
        println("Usage: jlox [script]");
        System.exit(64);
    elseif length(ARGS) == 1
      runFile(ARGS[])
    else
      runPrompt()
    end
end

function runFile(path)
    open(path, "r") do f
        data = read(f, String)
        run(data)
    end
end

function runPrompt()
    while true
        print("> ")
        line = readline()
        if line == ""
            continue
        end
        run(line)
        print("\n")
    end
end

function run(source::String)
    tokens = scanTokens(source);
    for t in tokens
        println(t)
    end
end

function scanTokens(source::String)
    return ['a', 'b', 'c']
end

function error(line::Int, message::String)
    report(line, "", message)
end

function report(line::Int, where::String, message::String)
    println("[line" + line + "] Error" + where + ": " + message)
    hadError = true
end

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


main()

