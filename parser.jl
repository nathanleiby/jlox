include("./expressions.jl")
include("./token.jl")
include("errors.jl")

function parseTokens(tokens)::Vector{Stmt}
    current = 1

    # helper functions

    function expression()::Expr
        return equality()
    end

    # TODO: variable type?
    # function match(tokens::Vararg{TokenType,N})
    function match(types...)
        for t in types
            if check(t)
                advance()
                return true
            end
        end
        return false
    end

    function check(tt::TokenType)
        if isAtEnd()
            return false
        end
        return peek().type == tt
    end

    function advance()
        if !isAtEnd()
            current += 1
        end
        return previous()
    end

    function isAtEnd()::Bool
        return peek().type == EOF
    end

    function peek()::Token
        # return tokens[current - 1]
        return tokens[current] # TODO
    end

    function previous()::Token
        # return tokens[current - 2]
        return tokens[current - 1]
    end

    function equality()::Expr
        expr = comparison()

        while (match(BANG_EQUAL, EQUAL_EQUAL))
            op = previous()
            right = comparison()
            expr = Binary(expr, op, right)
        end

        return expr
    end

    function comparison()::Expr
        expr = term()
        while (match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL))
            op = previous()
            right = term()
            expr = Binary(expr, op, right)
        end

        return expr
    end

    function term()::Expr
        expr = factor()

        while (match(MINUS, PLUS))
            op = previous()
            right = factor()
            expr = Binary(expr, op, right)
        end

        return expr
    end

    function factor()::Expr
        expr = unary()

        while match(SLASH, STAR)
            op = previous()
            right = unary()
            expr = Binary(expr, op, right)
        end

        return expr
    end

    function unary()::Expr
        if match(MINUS, BANG)
            op = previous()
            right = unary()
            return Unary(op, right)
        end

        return primary()
    end

    function primary()::Expr
        if match(FALSE)
            return Literal(false)
        elseif match(TRUE)
            return Literal(true)
        elseif match(NIL)
            return Literal(nothing)
        end

        if match(NUMBER, STRING)
            return Literal(previous().literal)
        end

        if match(LEFT_PAREN)
            expr = expression()
            consume(RIGHT_PAREN, "Expect ')' after expression.")
            return Grouping(expr)
        end

        error(peek(), "Expect expression.")
        throw("ParseError")
    end


    function consume(type::TokenType, message::String)
        if check(type)
            return advance()
        end

        error(peek(), message)
        throw("ParseError")
    end

    function error(token::Token, message::String)
        if token.type == EOF
            report(token.line, "at end", message)
        else
            report(token.line, " at $(token.lexeme)", message)
        end
    end

    function synchronize()
        advance()

        while !isAtEnd()
            if previous().type == SEMICOLON
                return
            end

            if in(peek().type, [CLASS, FUN, VAR, FOR, IF, WHILE, PRINT, RETURN])
                return
            end

            advance()
        end
    end

    # statements
    function statement()
        if (match(PRINT))
            return printStatement()
        end

        return expressionStatement()
    end

    function printStatement()
        value = expression()
        consume(SEMICOLON, "Expect ';' after value.")
        return PrintStmt(value)
    end

    function expressionStatement()
        expr = expression()
        consume(SEMICOLON, "Expect ';' after expression.")
        return ExpressionStmt(expr)
    end

    # core logic
    statements = []
    while !isAtEnd()
        s = statement()
        push!(statements, s)
    end

    return statements
end
