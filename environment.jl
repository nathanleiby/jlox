struct Environment
    Values::Dict
    Enclosing::Union{Environment,Nothing}
end

Environment() = Environment(Dict(), nothing)
Environment(enclosing::Environment) = Environment(Dict(), enclosing)


function defineenv(env::Environment, name::String, value)
    env.Values[name] = value
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

    if env.Enclosing !== nothing
        assignenv(env.Enclosing, name, value)
        return
    end

    throw(RuntimeError(name, "Undefined variable '$(name.lexeme)'."))
end

function Base.get(env::Union{Environment,Nothing}, name::Token)
    if haskey(env.Values, name.lexeme)
        return env.Values[name.lexeme]
    end

    if env.Enclosing !== nothing
        return get(env.Enclosing, name)
    end

    throw(RuntimeError(name, "Undefined variable '$(name.lexeme)'."))
end

function getat(env::Environment, distance::Integer, name::Token)
    return ancestor(env, distance).Values[name.lexeme]
end

function assignAt(env::Environment, distance::Integer, name::Token, value::Any)
    ancestor(env, distance).Values.put(name.lexeme, value);
end

function ancestor(env::Environment, distance::Integer)
    if distance == 0
        return env
    end
    return ancestor(env.Enclosing, distance - 1)
end
