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

mutable struct ThisExpr <: LoxExpr
    keyword::Token
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

mutable struct SuperExpr <: LoxExpr
    keyword::Token
    method::Token
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
    superclass::Union{Variable,Nothing}
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
    isInitializer::Bool
end

mutable struct LoxClass
    name::String
    superclass::Union{LoxClass,Nothing}
    methods::Dict{String,LoxFunction}
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

    method = findMethod(instance.klass, key)
    if method !== nothing
        boundMethod = bind(method, instance)
        return boundMethod
    end

    throw(RuntimeError(name, "Undefined property '$key'."))
end

function findMethod(klass::LoxClass, name::String)
    m = get(klass.methods, name, nothing)
    if m !== nothing
        return m
    end

    if klass.superclass !== nothing
        return findMethod(klass.superclass, name)
    end

    return nothing
end

function findMethod(klass::LoxClass, name::Token)
    return findMethod(klass, name.lexeme)
end

function bind(f::LoxFunction, instance::LoxInstance)
    env = Environment(f.closure)
    defineenv(env, "this", instance)
    return LoxFunction(f.declaration, env, f.isInitializer)
end

@enum FunctionType begin
    NONE
    FUNCTION
    INITIALIZER
    METHOD
end

@enum ClassType begin
    CLASSTYPE_NONE
    CLASSTYPE_CLASS
    CLASSTYPE_SUBCLASS
end
