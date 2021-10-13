include("./statements.jl")

function interpret(statements::Vector{Stmt})
    try
        for s in statements
            execute(s)
        end
    catch e
        throw(e) # TODO: hadRuntimeError
    end
end
