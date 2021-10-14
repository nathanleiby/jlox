include("./statements.jl")
include("./environment.jl")
include("./token.jl")

## expression types ##
abstract type LoxExpr end

struct Assign <: LoxExpr
    name::Token
    value::LoxExpr
end

struct Binary <: LoxExpr
    left::LoxExpr
    operator::Token
    right::LoxExpr
end

struct Grouping <: LoxExpr
    expression::LoxExpr
end

struct Literal <: LoxExpr
    value::Any
end

struct Unary <: LoxExpr
    operator::Token
    right::LoxExpr
end

struct Variable <: LoxExpr
    name::Token
end

## statement types ##

abstract type Stmt end

struct PrintStmt <: Stmt
    expression::LoxExpr
end

struct ExpressionStmt <: Stmt
    expression::LoxExpr
end

struct VarStmt <: Stmt
    name::Token
    initializer::LoxExpr
end

struct RuntimeError  <: Exception
    token::Token
    details::String
end


function interpret(statements::Vector{Stmt})
    environment = Environment(Dict())

    ## expressions ##

    function evaluate(expr::LoxExpr)
        visit(expr)
    end

    function visit(literal::Literal)
        return literal.value
    end

    function visit(group::Grouping)
        return evaluate(group.expression)
    end

    function visit(unary::Unary)
        right = evaluate(unary.right)
        t = unary.operator.type
        if t == MINUS
            checkNumberOperand(unary.operator, right)
            return -right
        elseif t == BANG
        return !isTruthy(right)
        end

        throw("unreachable")
    end

    function visit(var::Variable)
        return get(environment, var.name)
    end

    function visit(expr::Assign)
        value = evaluate(expr.value)
        assignenv(environment, expr.name, value)
        return value
    end

    function visit(binary::Binary)
        left = evaluate(binary.left)
        right = evaluate(binary.right)

        t = binary.operator.type
        if t == MINUS
            return left - right
        elseif t == SLASH
        return left / right
    elseif t == STAR
        return left * right
    elseif t == PLUS
        if isa(left, Number) && isa(right, Number)
            return left + right
        elseif isa(left, String) && isa(right, String)
            return "$left$right"
        else
            throw("Operands must be numbers")
        end
    elseif t == GREATER
        checkNumberOperands(binary.operator, left, right)
        return left > right
    elseif t == GREATER_EQUAL
        checkNumberOperands(binary.operator, left, right)
        return left >= right
    elseif t == LESS
        checkNumberOperands(binary.operator, left, right)
        return left < right
    elseif t == LESS_EQUAL
        checkNumberOperands(binary.operator, left, right)
        return left <= right
    elseif t == BANG_EQUAL
        checkNumberOperands(binary.operator, left, right)
        return !isEqual(left, right)
    elseif t == EQUAL_EQUAL
        checkNumberOperands(binary.operator, left, right)
        return isEqual(left, right)
        end

        throw("unreachable")
    end

    function isTruthy(value::Bool)
        return value
    end

    function isTruthy(value::Any)
        return value !== nothing
    end

    function isEqual(a, b)
    # TODO: is this sufficient? I think Julia equality may be same idea as in Lox
        return a == b
    end

    function checkNumberOperand(operator::Token, operand::Any)
        if isa(operand, Number)
            return
        end
        throw(RuntimeError(operator))
    end

    function checkNumberOperands(operator::Token, left::Any, right::Any)
        if isa(left, Number) && isa(right, Number)
            return
        end
        throw(RuntimeError(operator))
    end

    ## statements ##

    function execute(stmt::Stmt)
        visit(stmt)
    end

    function visit(stmt::ExpressionStmt)
        evaluate(stmt.expression)
        return nothing
    end

    function stringify(obj)
        if obj === nothing
            return "nil"
        elseif isa(obj, Number)
            if obj - floor(obj) == 0
                return Integer(floor(obj))
            end
        end

        return obj
    end

    function visit(stmt::PrintStmt)
        value = evaluate(stmt.expression)
        println(stringify(value));
        return nothing
    end

    function visit(stmt::VarStmt)
        value = stmt.initializer !== nothing ? evaluate(stmt.initializer) : nothing
        defineenv(environment, stmt.name, value)
        return nothing
    end

    ## Core logic
    try
        for s in statements
            execute(s)
        end
    catch e
        throw(e) # TODO: hadRuntimeError
    end
end
