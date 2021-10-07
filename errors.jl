function error(line::Int, message::String)
    report(line, "", message)
end

function report(line::Int, where::String, message::String)
    println("[line ", line, "] Error", where, ": ", message)
    hadError = true
end
