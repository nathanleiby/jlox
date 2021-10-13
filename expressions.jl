abstract type Expr end

struct Binary <: Expr
    left::Any
    operator::Token
    right::Any
end

struct Grouping <: Expr
    expression::Expr
end

struct Literal <: Expr
    value::Any
end

struct Unary <: Expr
    operator::Token
    right::Any
end

struct Variable <: Expr
    value::Token
end

function evaluate(expr::Expr)
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
    q("TODO")
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
