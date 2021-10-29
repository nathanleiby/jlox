include("./token.jl")
include("./scanner.jl")
include("./parser.jl")
include("./interpreter.jl")
include("./expressions.jl")
include("./errors.jl")
include("./debug.jl")
include("./resolver.jl")

function main()
    if length(ARGS) > 1
        println("Usage: jlox [script]");
        System.exit(64);
    elseif length(ARGS) == 1
      runFile(ARGS[])
    else
      runPrompt()
    end
end

function runFile(path)
    # println("Running file ", path, "...")
    open(path, "r") do f
        data = read(f, String)
        run(data)
    end
end

function runPrompt()
    while true
        print("> ")
        line = readline()
        if line == ""
            continue
        end
        run(line)
        print("\n")
    end
end

function run(source::String)
    tokens = scanTokens(source);
    # for t in tokens
    #     println(t)
    # end

    q("==>> Stage 1: Parse <<==")
    statements = parseTokens(tokens)

    # TODO:
    # if (hadError) return;
    for s in statements
        q(s)
    end

    q("==>> Stage 2: Resolve <<==")
    locals, resolveError = resolveStatements(statements)
    q(locals)

    if resolveError
        return
    end

    # print(expr)
    q("==>> Stage 3: Interpret <<==")
    interpret(statements, locals)

    # TODO: AstPrinter
    # System.out.println(new AstPrinter().print(expression));
end

main()
