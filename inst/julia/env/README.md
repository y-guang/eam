# Julia Environment

This folder contains the necessary julia environment configuration. For developers, you need to activate the `inst/julia/env` environment to modify the julia environment. That is, if you try to modify the `system.file("julia/env", package = "eam")` it will not work because the `system.file` is a generated path and it will not be modified. 

So, in short, if you want to modify the julia environment, you need:

```r
juliaEval('using Pkg; Pkg.activate("inst/julia/env")')
juliaEval('Pkg.add("PackageName")')
```
