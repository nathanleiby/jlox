abstract type Stmt end

struct PrintStmt <: Stmt
    expression::Expr
end

struct ExpressionStmt <: Stmt
    expression::Expr
end

struct VarStmt <: Stmt
    name::Token
    expression::Expr
end

# TODO: Unused so far
struct RuntimeError  <: Exception
    token::Token
end

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
        # TODO: trim trailing .0, if neede
        return obj
    end

    return obj
end

function visit(stmt::PrintStmt)
    value = evaluate(stmt.expression)
    println(stringify(value));
    return nothing
end

function visit(stmt::VarStmt)
    # TODO
    val = evaluate(stmt.expression)
    return val
end
