- some global types get injected (including `Expr`)
- using common var names has pitfalls in Julia (e.g. `get` is in `Base`, which is injected into env)
- lack of classes is annoying, if I made things pure but then later the abstraction becomes stateful (e.g. adding `environment` .. now my expressions and statements must be in a class but weren't before)
