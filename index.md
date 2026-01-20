# eam

eam is a simulation-based evidence accumulation models for analyzing
responses and reaction times in single- and multi-response tasks. The
package includes simulation engines for five representative models: the
Diffusion Decision Model (DDM), Leaky Competing Accumulator (LCA),
Linear Ballistic Accumulator (LBA), Racing Diffusion Model (RDM), and
Lévy Flight Model (LFM), and extends these frameworks to multi-response
settings.

The package supports user-defined functions for item-level
parameterization and the incorporation of covariates, enabling flexible
customization and the development of new model variants based on
existing architectures. Inference is performed using simulation-based
methods, including Approximate Bayesian Computation (ABC) and Amortized
Bayesian Inference (ABI), which allow parameter estimation without
requiring tractable likelihood functions.

In addition to core inference tools, the package provides modules for
parameter recovery, posterior predictive checks, and model comparison.
Overall, it facilitates the study of a wide range of cognitive processes
in tasks involving perceptual decision making, memory retrieval, and
value-based decision making.

## Links

- [Documentation (for users)](https://y-guang.github.io/eam/):
  User-facing documentation with tutorials, usage examples, and model
  overviews.
- [Development repository (for
  developers)](https://github.com/y-guang/eam): GitHub repository for
  source code, development discussions, and issue/PR tracking. The main
  branch reflects the development version, and tags are used for stable
  releases.
- [CRAN page](https://CRAN.R-project.org/package=eam): The official CRAN
  page for the eam package.

## Features

- ⚙️ High-Performance Backend
  - **Pure C++ core** with fast vectorization-friendly algorithms
    designed. 100x speedup compared with naive python implementations.
  - Memory-efficient computation, enabling more than **10 million**
    trials on a standard desktop machine.
  - Parallel execution with near-linear speed-up across multiple CPU
    cores.
- 🧩 Modern API
  - Flexible architecture: composable api, defines several formulas, you
    can easily customize your own models.
  - modern R api：Built around modern R conventions, it provides a
    declarative, tidy-style interface.
  - Unified data pipeline: provides a consistent set of data
    manipulation and summarization utilities for seamless simulation,
    evaluation, and visualization.
