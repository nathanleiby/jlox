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

struct ReturnStmt <: Stmt
    keyword::Token
    value::Union{LoxExpr,Nothing}
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
