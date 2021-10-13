include("errors.jl")

function scanTokens(source::String)
    # properties
    start = 1
    current = 1
    line = 1
    tokens = []

    # helpers
    function advance()
        c = source[current]
        current += 1
        return c
    end

    function addToken(tt::TokenType)
        addToken(tt, missing)
    end

    function addToken(tt::TokenType, literal::Any)
        text = source[start:current - 1]
        push!(tokens, Token(tt, text, literal, line))
    end

    function scanStringToken()
        while peek() != '"' && !isAtEnd()
            if peek() == '\n'
                line += 1
            end
            advance()
        end

        if isAtEnd()
            error(line, "Unterminated string.")
        end

        # consume the closing ""
        advance()
        value = source[start + 1:current - 2]
        addToken(STRING, value);
    end

    function scanNumberToken()
        while isdigit(peek())
            advance()
        end

        if peek() == '.' && isdigit(peekNext())
            # consume the .
            advance()

            while isdigit(peek())
                advance()
            end
        end

        value = parse(Float64, source[start:current - 1])
        addToken(NUMBER, value)
    end

    function isAlphaNumeric(c)
        return isletter(c) || isdigit(c)
    end

    function scanIdentifierToken()
        while isAlphaNumeric(peek())
            advance()
        end
        text = source[start:current - 1]
        type = get(keywords, text, IDENTIFIER)
        # addToken(type, text);
        addToken(type)
    end

    function match(c::Char)::Bool
        if isAtEnd()
            return false
        elseif source[current] != c
            return false
        end

        current += 1
        return true
    end

    function peek()::Char
        if isAtEnd()
            return '\0' # TODO: is working?
        else
            return source[current]
        end
    end

    function peekNext()::Char
        if current + 1 >= len(source)
            return '\0'
        else
            return source[current + 1]
        end
    end

    function isAtEnd()
        return current >= length(source)
    end

    function scanToken()
        c = advance();
        if c == '('
            addToken(LEFT_PAREN)
        elseif c == ')'
            addToken(RIGHT_PAREN)
        elseif c == '{'
            addToken(LEFT_BRACE)
        elseif c == '}'
            addToken(RIGHT_BRACE)
        elseif c == ','
            addToken(COMMA)
        elseif c == '.'
            addToken(DOT)
        elseif c == '-'
            addToken(MINUS)
        elseif c == '+'
            addToken(PLUS)
        elseif c == ';'
            addToken(SEMICOLON)
        elseif c == '*'
            addToken(STAR)
        elseif c == '!'
            addToken(match('=') ? BANG_EQUAL : BANG)
        elseif c == '='
            addToken(match('=') ? EQUAL_EQUAL : EQUAL)
        elseif c == '<'
            addToken(match('=') ? LESS_EQUAL : LESS)
        elseif c == '>'
            addToken(match('=') ? GREATER_EQUAL : GREATER)
        elseif c == '/'
            if match('/')
                while (peek() != '\n' && !isAtEnd())
                    advance()
                end
            else
                addToken(SLASH);
            end
        elseif c == ' ' || c == '\r' || c == '\t'
            # ignore whitespace
        elseif c == '\n'
            line += 1
        elseif c == '"'
            scanStringToken()
        elseif isdigit(c)
            scanNumberToken()
        elseif isletter(c)
            scanIdentifierToken()
        else
            error(line, "Unexpected character: $c")
        end
    end

    # main logic
    while (!isAtEnd())
        start = current;
        scanToken();
    end

    eof = Token(EOF, "", nothing, line)
    push!(tokens, eof)

    return tokens
end
