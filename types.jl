abstract type LoxExpr end
abstract type Stmt end

## TODO: Add Expr or Stmt to end of all types, for clarity

## expression types ##

mutable struct Assign <: LoxExpr
    name::Token
    value::LoxExpr
end

mutable struct Binary <: LoxExpr
    left::LoxExpr
    operator::Token
    right::LoxExpr
end

mutable struct Call <: LoxExpr
    callee::LoxExpr
    paren::Token
    arguments::Vector{LoxExpr}
end

mutable struct FnExpr <: LoxExpr
    name::Token
    params::Vector{Token}
    body::Vector{Stmt}
end

# GetExpr gets a field from an instance of a class
mutable struct GetExpr <: LoxExpr
    object::LoxExpr
    name::Token
end

# SetExpr sets a field on an instance of a class
mutable struct SetExpr <: LoxExpr
    object::LoxExpr
    name::Token
    value::LoxExpr
end

mutable struct Grouping <: LoxExpr
    expression::LoxExpr
end

mutable struct Literal <: LoxExpr
    value::Any
end

mutable struct Unary <: LoxExpr
    operator::Token
    right::LoxExpr
end


mutable struct Logical <: LoxExpr
    left::LoxExpr
    operator::Token
    right::LoxExpr
end

mutable struct Variable <: LoxExpr
    name::Token
end

mutable struct Block <: LoxExpr
    statements::Vector{Stmt}
end

## statement types ##

mutable struct BlockStmt <: Stmt
    statements::Vector{Stmt}
end

mutable struct ExpressionStmt <: Stmt
    expression::LoxExpr
end

mutable struct FnStmt <: Stmt
    name::Token
    params::Vector{Token}
    body::Vector{Stmt}
end

mutable struct ClassStmt <: Stmt
    name::Token
    methods::Vector{FnStmt}
end

mutable struct IfStmt <: Stmt
    condition::LoxExpr
    thenBranch::Stmt
    elseBranch::Union{Stmt,Nothing}
end

mutable struct PrintStmt <: Stmt
    expression::LoxExpr
end

mutable struct ReturnStmt <: Stmt
    keyword::Token
    value::Union{LoxExpr,Nothing}
end

mutable struct VarStmt <: Stmt
    name::Token
    initializer::Union{LoxExpr,Nothing}
end

mutable struct WhileStmt <: Stmt
    condition::LoxExpr
    body::Stmt
end

## Other
struct RuntimeError  <: Exception
    token::Token
    details::String
end

struct Return <: Exception
    value::Any
end

struct NativeFunction
    arity::Int
    callee::Function
end

struct LoxFunction
    declaration::FnStmt
    closure::Environment
end

mutable struct LoxClass
    name::String
end

mutable struct LoxInstance
    klass::LoxClass
    fields::Dict{String,Any}
end

function Base.get(instance::LoxInstance, name::Token)
    key = name.lexeme
    if haskey(instance.fields, key)
        return instance.fields[key]
    end

    throw(RuntimeError(name, "Undefined property '$key'."))
end
