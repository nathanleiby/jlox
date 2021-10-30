include("./statements.jl")
include("./environment.jl")
include("./token.jl")
include("./types.jl")

function interpret(statements::Vector{Stmt}, locals::Dict)
    globals = Environment()
    environment = globals

    #################
    ## expressions ##
    #################

    function evaluate(expr::LoxExpr)
        q("Evaluate: $expr")
        visit(expr)
    end

    function visit(literal::Literal)
        q("Visit literal: $literal")
        return literal.value
    end

    function visit(expr::GetExpr)
        obj = evaluate(expr.object)
        if isa(obj, LoxInstance)
            return get(obj, expr.name)
        end

        throw(RuntimeError(expr.name, "Only instances have properties"))
    end

    function visit(expr::SetExpr)
        obj = evaluate(expr.object)
        if ! isa(obj, LoxInstance)
            throw(RuntimeError(expr.name, "Only instances have fields"))
        end

        val = evaluate(expr.value)
        obj.fields[expr.name.lexeme] = val
        return val
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
        q("expr= $expr")
        callee = evaluate(expr.callee)
        q("callee = $callee")
        args = []
        for arg in expr.arguments
            push!(args, evaluate(arg))
        end

        ctype = typeof(callee)
        if ctype != LoxFunction && ctype != NativeFunction && ctype != LoxClass
            q("ctype = $ctype")
            throw(RuntimeError(expr.paren, "Can only call functions and classes."))
        end

        if length(args) != arity(callee)
            throw(RuntimeError(expr.paren, "Expected $(callee.arity) arguments but got $(length(args))."))
        end

        return call(callee, args)
    end

    function visit(expr::Variable)
        return lookupVariable(expr.name, expr)
    end

    function lookupVariable(name::Token, expr::LoxExpr)
        distance = get(locals, pointer_from_objref(expr), nothing)
        if distance !== nothing
            # get from locals
            return getat(environment, distance, name)
        end

        # get from globals
        return get(globals, name)
    end

    function visit(expr::Assign)
        value = evaluate(expr.value)

        distance = get(locals, pointer_from_objref(expr), nothing)
        if distance !== nothing
            assignAt(environment, distance, expr.name, value)
        else
            assignenv(globals, expr.name, value)
        end

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

    function visit(expr::ThisExpr)
        return lookupVariable(expr.keyword, expr)
    end

    ################
    ## statements ##
    ################

    function execute(stmt::Stmt)
        visit(stmt)
    end

    function visit(stmt::ClassStmt)
        defineenv(environment, stmt.name, nothing)
        methods = Dict{String,LoxFunction}()
        for m in stmt.methods
            isInitializer = m.name.lexeme == "init"
            fn = LoxFunction(m, environment, isInitializer)
            methods[m.name.lexeme] = fn
        end

        klass = LoxClass(stmt.name.lexeme, methods)
        assignenv(environment, stmt.name, klass)
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
        elseif isa(obj, LoxClass)
            return obj.name
        elseif isa(obj, LoxInstance)
            return "$(obj.klass.name) instance"
        end

        return obj
    end

    function visit(stmt::PrintStmt)
        value = evaluate(stmt.expression)
        println(stringify(value))
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
        fn = LoxFunction(stmt, environment, false)
        defineenv(environment, stmt.name.lexeme, fn)
        return nothing
    end

    function visit(stmt::ReturnStmt)
        value = nothing
        if stmt.value !== nothing
            value = evaluate(stmt.value)
        end

        # When we execute a return statement, we’ll use an exception to unwind
        # the interpreter past the visit methods of all of the containing
        # statements back to the code that began executing the body.
        throw(Return(value))
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
    function call(callable::LoxFunction, args::Vector{Any})
        env = Environment(callable.closure)
        for (idx, param) in enumerate(callable.declaration.params)
            defineenv(env, param.lexeme, args[idx])
        end

        try
            executeBlock(callable.declaration.body, env)
        catch executeException
            if isa(executeException, Return)
                if (callable.isInitializer)
                    return getat(callable.closure, 0, "this")
                end
                return executeException.value
            end
            throw(executeException)
        end

        if callable.isInitializer
            # `init()` always returns `this`
            return getat(callable.closure, 0, "this")
        end
        return nothing
    end

    function arity(callable::LoxFunction)
        return length(callable.declaration.params)
    end

    function call(callable::NativeFunction, args::Vector{Any})
        return callable.callee(args)
    end

    function arity(callable::NativeFunction)
        return callable.arity
    end

    function call(callable::LoxClass, args::Vector{Any})
        instance = LoxInstance(callable, Dict{String,Any}())
        initializer = get(callable.methods, "init", nothing)
        if initializer !== nothing
            boundMethod = bind(initializer, instance)
            call(boundMethod, args)
        end
    return instance
    end

    function arity(callable::LoxClass)
        initializer = get(callable.methods, "init", nothing)
        if initializer !== nothing
            return arity(initializer)
        end
        return 0
    end

    ######################
    # Core
    ######################

    ## Setup Global fns
    defineenv(globals, "clock", NativeFunction(0, time))

    ## Main logic
    try
        for s in statements
            execute(s)
        end
    catch e
        throw(e) # TODO: hadRuntimeError
    end
end
