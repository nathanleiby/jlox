include("./statements.jl")
include("./environment.jl")
include("./token.jl")

abstract type LoxExpr end
abstract type Stmt end

## expression types ##

struct Assign <: LoxExpr
    name::Token
    value::LoxExpr
end

struct Binary <: LoxExpr
    left::LoxExpr
    operator::Token
    right::LoxExpr
end

struct Call <: LoxExpr
    callee::LoxExpr
    paren::Token
    arguments::Vector{LoxExpr}
end

struct FnExpr <: LoxExpr
    name::Token
    params::Vector{Token}
    body::Vector{Stmt}
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


struct Logical <: LoxExpr
    left::LoxExpr
    operator::Token
    right::LoxExpr
end

struct Variable <: LoxExpr
    name::Token
end

struct Block <: LoxExpr
    statements::Vector{Stmt}
end

## statement types ##

struct BlockStmt <: Stmt
    statements::Vector{Stmt}
end

struct ExpressionStmt <: Stmt
    expression::LoxExpr
end

struct FnStmt <: Stmt
    name::Token
    params::Vector{Token}
    body::Vector{Stmt}
end

struct IfStmt <: Stmt
    condition::LoxExpr
    thenBranch::Stmt
    elseBranch::Union{Stmt,Nothing}
end

struct PrintStmt <: Stmt
    expression::LoxExpr
end

struct VarStmt <: Stmt
    name::Token
    initializer::Union{LoxExpr,Nothing}
end

struct WhileStmt <: Stmt
    condition::LoxExpr
    body::Stmt
end

## Other
struct RuntimeError  <: Exception
    token::Token
    details::String
end

struct NativeCallable
    arity::Int
    callee::Function
end

struct LoxCallable
    declaration::FnStmt
end

# function arity(lc::LoxCallable)
#     return length(lc.declaration.params)
# end

function interpret(statements::Vector{Stmt})
    globals = Environment()
    environment = globals

    #################
    ## expressions ##
    #################

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

    function visit(expr::Call)
        callee = evaluate(expr.callee)
        args = []
        for arg in expr.arguments
            push!(args, evaluate(arg))
        end

        ctype = typeof(callee)
        if ctype != LoxCallable && ctype != NativeCallable
            throw(RuntimeError(expr.paren, "Can only call functions and classes."))
        end

        if length(args) != arity(callee)
            throw(RuntimeError(expr.paren, "Expected $(callee.arity) arguments but got $(length(args))."))
        end

        return call(callee, args)
    end

    function visit(var::Variable)
        return get(environment, var.name)
    end

    function visit(expr::Assign)
        value = evaluate(expr.value)
        assignenv(environment, expr.name, value)
        return value
    end

    function visit(expr::Logical)
        left = evaluate(expr.left)

        # check if we can short circuit
        if expr.operator.type == OR
            if isTruthy(left)
                return left
            end
        else # it's an AND
            if !isTruthy(left)
                return left
            end
        end

        return evaluate(expr.right)
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
        throw(RuntimeError(operator, ""))
    end

    function checkNumberOperands(operator::Token, left::Any, right::Any)
        if isa(left, Number) && isa(right, Number)
            return
        end
        throw(RuntimeError(operator, ""))
    end

    ################
    ## statements ##
    ################

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

    function visit(stmt::BlockStmt)
        executeBlock(stmt.statements, Environment(environment))
        return nothing
    end

    function visit(stmt::IfStmt)
        if isTruthy(evaluate(stmt.condition))
            execute(stmt.thenBranch)
        elseif stmt.elseBranch !== nothing
            execute(stmt.elseBranch)
        end
        return nothing
    end

    function visit(stmt::WhileStmt)
        while isTruthy(evaluate(stmt.condition))
            execute(stmt.body)
        end
        return nothing
    end

    function visit(stmt::FnStmt)
        fn = LoxCallable(stmt)
        defineenv(environment, stmt.name.lexeme, fn)
        return nothing
    end

    # TODO: This was the core logic before -- could we call there too?
    function executeBlock(statements::Vector{Stmt}, env::Environment)
        previous = environment
        try
            environment = env
            for s in statements
                execute(s)
            end
        catch err
            environment = previous
            throw(err)
        end

        environment = previous
    end

    #################
    ## Callables
    #################
    function call(callable::LoxCallable, args::Vector{Any})
        env = Environment(globals)
        for (idx, param) in enumerate(callable.declaration.params)
            defineenv(env, param.lexeme, args[idx])
        end

        executeBlock(callable.declaration.body, env)
        return nothing
    end

    function arity(callable::LoxCallable)
        return length(callable.declaration.params)
    end

    function call(callable::NativeCallable, args::Vector{Any})
        return callable.callee(args)
    end

    function arity(callable::NativeCallable)
        return callable.arity
    end

    ######################
    # Core
    ######################

    ## Setup Global fns
    defineenv(globals, "clock", NativeCallable(0, time))

    ## Main logic
    try
        for s in statements
            execute(s)
        end
    catch e
        throw(e) # TODO: hadRuntimeError
    end
end
