
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
