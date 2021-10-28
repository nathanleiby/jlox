using JSON

SHOW_DEBUG = true

function q(a::Dict)
    if !SHOW_DEBUG then
        return
    end

    try
        println("[q] $(json(a, 4))")
    catch
        println("[q] $a")
    end
end

function q(a...)
    if !SHOW_DEBUG then
        return
    end
    println("[q]", a...)
end
