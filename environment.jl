struct Environment
    Values::Dict
end

function defineenv(env::Environment, name::Token, value)
    # Currently, this works...
    #     var a = "before";
    #     print a; // "before".
    #     var a = "after";
    #     print a; // "after".
    env.Values[name.lexeme] = value
end

function assignenv(env::Environment, name::Token, value)
    if haskey(env.Values, name.lexeme)
        env.Values[name.lexeme] = value
        return
    end
    throw(RuntimeError(name, "Undefined variable '$(name.lexeme)'."))
end

function Base.get(env::Environment, name::Token)
    if haskey(env.Values, name.lexeme)
        return env.Values[name.lexeme]
    end
    throw(RuntimeError(name, "Undefined variable '$(name.lexeme)'."))
end
