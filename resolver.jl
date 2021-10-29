function resolveStatements(ss::Vector{Stmt})::Dict
    scopes = [] # TODO: use an explicit Stack
    locals = Dict{Ptr,Integer}()

    ##############
    # helpers
    ##############

    ## scopes

    function beginScope()
        # push!(scopes, Dict{String,Bool}())
        push!(scopes, Dict())
        return nothing
    end

    function endScope()
        pop!(scopes)
        return nothing
    end

    function peekScope()
        return last(scopes)
    end

    ## visit() methods

    function visit(stmt::BlockStmt)
        beginScope();
        resolve(stmt.statements);
        endScope();
    end

    function visit(stmt::VarStmt)
        declare(stmt.name)
        if stmt.initializer !== nothing
            resolve(stmt.initializer)
        end
        define(stmt.name)
        return nothing
    end

    function declare(name::Token)
        if length(scopes) == 0
            return
        end

        scope = peekScope()
        scope[name.lexeme] = false # false means "not ready yet"
    end

    function define(name::Token)
        if length(scopes) == 0
            return
        end

        scope = peekScope()
        scope[name.lexeme] = true # true means "ready"
    end

    function visit(expr::Variable)
        if length(scopes) > 0 && get(peekScope(), expr.name.lexeme, nothing) === false
            error("Can't read local variable in its own initializer.")
        end

        resolveLocal(expr, expr.name)
        return nothing
    end

    function resolveLocal(expr::LoxExpr, name::Token)
        for i in reverse(1:length(scopes))
            scope = scopes[i]
            q("scopes[$(i)] = $scope")
            if haskey(scope, name.lexeme)
                distance = length(scopes) - i
                q("resolving with dis=$distance")
                resolve(expr, distance)
                return
            end
        end
    end

    ## visit() methods for Stmt's

    function visit(expr::Assign)
        resolve(expr.value)
        resolveLocal(expr, expr.name)
        return nothing
    end

    function visit(stmt::FnStmt)
        declare(stmt.name)
        define(stmt.name)

        resolveFunction(stmt)
        return nothing
    end

    function resolveFunction(stmt::FnStmt)
        beginScope()
        for param in stmt.params
            declare(param)
            define(param)
        end
        resolve(stmt.body)
        endScope()
    end

    function visit(stmt::ExpressionStmt)
        resolve(stmt.expression)
        return nothing
    end

    function visit(stmt::IfStmt)
        resolve(stmt.condition)
        resolve(stmt.thenBranch)
        if stmt.elseBranch !== nothing
            resolve(stmt.elseBranch)
        end
        return nothing
    end

    function visit(stmt::PrintStmt)
        resolve(stmt.expression)
        return nothing
    end

    function visit(stmt::ReturnStmt)
        if stmt.value !== nothing
            resolve(stmt.value)
        end
        return nothing
    end

    function visit(stmt::WhileStmt)
        resolve(stmt.condition)
        resolve(stmt.body)
        return nothing
    end

    ## visit() methods for Expr's
    function visit(expr::Binary)
        resolve(expr.left)
        resolve(expr.right)
        return nothing
    end

    function visit(expr::Call)
        resolve(expr.callee)
        for arg in expr.arguments
            resolve(arg)
        end
        return nothing
    end

    function visit(expr::Grouping)
        resolve(expr.expression)
        return nothing
    end

    function visit(_::Literal)
        return nothing
    end

    function visit(expr::Logical)
        resolve(expr.left)
        resolve(expr.right)
        return nothing
    end

    function visit(expr::Unary)
        resolve(expr.right)
        return nothing
    end

    function resolve(statements::Vector{Stmt})
        for s in statements
            resolve(s)
        end
    end

    function resolve(stmt::Stmt)
        visit(stmt)
    end

    function resolve(expr::LoxExpr)
        visit(expr)
    end

    function resolve(expr::LoxExpr, depth::Integer)
        # needs to be an *exact* object equality (===, not just struct equality in Julia)
        # 1. use a pointer
        # 2. the structs themselves must be mutable, else pointer_from_objref doesn't work)
        ptr = pointer_from_objref(expr)
        locals[ptr] = depth
    end

    ##############
    # main logic
    ##############
    resolve(ss)

    return locals
end
