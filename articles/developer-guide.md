# Developer Guide

## Contributing

This project is currently under active development, and contributions
from the community are very welcome.

To maintain an inclusive environment for contributors from around the
world, and to ensure that discussions are understandable and
maintainable by as many developers as possible, please prefer using
English when opening issues, submitting pull requests, or participating
in development discussions.

## Computation-Intensive Documents

For computation-intensive vignettes, such as simulation tutorials,
please adopt a **local pre-compilation** approach to accelerate the
GitHub Pages build process.

A rule of thumb is that if your document’s code execution time exceeds
approximately 1 minute, you should consider using local pre-compilation.

### Local Pre-compilation

First, in the `vignettes/` directory, rename the Rmd file that requires
pre-compilation to `*.Rmd.orig`, for example `tutorial.Rmd.orig`.

Ensure that in the Rmd file, you configure the figure path to a
subdirectory under `vignettes/` with the same name, and prefer using
vector graphics formats (such as SVG) for better scaling. An example
configuration:

``` r
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "./developer-guide/",
  dev = "svg",
  fig.ext = "svg"
)
```

Then, in your local R environment, run the following code to generate
the final Rmd file:

``` r
old <- getwd()
setwd("vignettes")

knitr::knit(
  "tutorial.Rmd.orig",
  output = "tutorial.Rmd"
)

setwd(old)
```

### Add Document to `_pkgdown`

Once you have completed the pre-compilation process, ensure that the new
Rmd file is properly referenced in the `_pkgdown.yml` file. For example:

``` yaml
articles:
- title: Tutorials
  navbar: Tutorials
  contents:
  - another-document
  - tutorial
```

### Commit Changes

Afterwards, you can try building the pkgdown site locally to ensure
everything works correctly:

``` r
pkgdown::build_site()
```

After confirming that all content is correct, commit both the
`*.Rmd.orig` and the generated `*.Rmd` files.

Additionally, please do not manually modify the generated `*.Rmd` files.
We should assume that these files are automatically generated from their
corresponding `*.Rmd.orig` files.
