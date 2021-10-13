struct Environment
    Values::Dict
end

function defineenv(env::Environment, name::String, value)
    if name == ""
        throw("InternalError:defineenv(): name not set")
    end

    # Currently, this works...
    #     var a = "before";
    #     print a; // "before".
    #     var a = "after";
    #     print a; // "after".
    env.Values[name] = value
end

function Base.get(env::Environment, token::Token)
    if haskey(env.Values, token.lexeme)
        return env.Values[token.lexeme]
    end
    throw(RuntimeError(token, "Undefined variable '" + token.lexeme + "'."))
end
