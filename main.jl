include("./token.jl")
include("./scanner.jl")
include("./parser.jl")

hadError = false

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
    println("Running file ", path, "...")
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
    for t in tokens
        println(t)
    end

    expr = parseTokens(tokens)

    # if (hadError) return;

    print(expr)

    # TODO: AstPrinter
    # System.out.println(new AstPrinter().print(expression));
end

main()

