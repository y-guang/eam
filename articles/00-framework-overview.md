# Overview of the EAM Framework

Evidence accumulation models (EAMs) are major approaches for modeling
responses and reaction times in cognitive tasks. The **eam** package
provide a simulation-based framework for simulating and fitting EAMs for
single- and multiple-response tasks.

Traditional single-response tasks are two-alternative forced choice
(2AFC) tasks such as lexical decision tasks, and random-dot motion
discrimination tasks, while multiple-response tasks are characterized by
the production of a sequence of responses within a single trial or
episode, as in free recall or verbal fluency tasks. The **eam** package
enables modeling responses from both types of tasks.

The **eam** package consists of two parts:

**a modular simulation engine** that allows users to flexibly customize
models and simulate data;

**a simulation-based inference module** for reliable parameter inference
without requiring a tractable likelihood.

In this section, we introduce these two components in detail and
demonstrate how they can be combined to build, simulate, and fit
customized evidence accumulation models.

## Modular simulation engine

The modular simulation engine is built upon the generalized evidence
accumulation framework, within which we assume that decision making is
characterized as a stochastic process in which evidence is continuously
collected over time. The accumulation unfolds in infinitesimal
increments $dt$, which can be approximated in practice with very small
time steps (for example, 1,). The moment-to-moment change in accumulated
evidence $x(t)$ can be expressed as a stochastic differential:

$$dx(t) = v \cdot dt + s \cdot \sigma,$$

where $v$ is the drift rate, $dt$ is a time step, $s$ is the noise
scaling parameter, and $\sigma$ is a diffusion noise term.

As the process unfolds, the accumulated evidence $x(t)$ continues to
evolve until it reaches the decision boundaries, at which point a
response is triggered and the corresponding RT is recorded. The distance
to reaching the boundary is jointly determined by two parameters: the
decision boundary ($a$) and the starting point ($z$).

As evidence accumulates, the process continues until $x(t) + z$ first
reaches either the upper boundary $a$ or falls below the lower boundary
0 (in two-boundary EAMs). The elapsed time from the start of
accumulation to this boundary crossing defines the decision time; adding
a non-decision time $t_{0}$ yields the observable RT.

The modular simulation engine is composed of ten modules (see figure
below):

**Number of accumulators**: the number of accumulators that race or
compete toward a decision boundary (e.g., one in DDM or LFM; multiple in
LBA, LCA, or RDM)

**Prior distribution of hyperparameters**: hierarchical priors
specifying mean, variance, and regression coefficients for core
parameters of the evidence-accumulation process including drift rate,
decision boundary, starting point/relative bias, non-decision time,
leakage parameter, strength of lateral inhibition, and stability
parameter.

**Between-trial variability**: specify the formulas for between-subject
or between-trial variability in parameters, also allowing linking
covariates to the subject- or trial-level parameters.

**Item-level formula**: linking each accumulator’s parameter to item
indexes or output positions to generate the accumulator-level parameter
values such as drift rate or decision boundary, also allowing linking
covariates to the item-level parameters.

**Type of noise**: family of diffusion noise (e.g., Gaussian vs. Lévy
$\alpha$-stable vs. deterministic ballistic).

**Simulation setting**: the configuration used for model simulation,
including model equations, number of conditions, number of trials per
condition, and other implementation parameters.

**Rules to record responses**: the criteria determining when and how
responses are recorded (e.g., first boundary crossing only, or the first
$n$ releases within a time limit).

**Time step**: the discrete increment used to approximate
continuous-time evidence accumulation (default at 1,).

**Noise setting**: the algorithmic specification of stochastic
increments (e.g., additive vs. multiplicative).

**Type of model**: the underlying architecture of evidence accumulation
(e.g., single-boundary vs. double-boundary vs. LCA accumulators).

By combining different modular components, the engine can simulate
responses and RTs from many representative EAMs (see the section [Models
in eam](https://y-guang.github.io/eam/articles/20-models-in-eam.md) for
the configurations of each representative EAM).

![Procedures of simulation engines in the eam
package](00-framework-overview/procedures.svg)

Procedures of simulation engines in the eam package

## Simulation-based inference module

The simulation-based inference module includes two major apporaches:
Approximate Bayesian Computation (ABC; Csilléry et al., 2012) and
Amortized Bayesian Inference (ABI; Sainsbury-Dale et al., 2024). These
methods can estimate the posteiror distribution of parameters via the
comparsion between simulated and observed data, bypassing the need for
likelihood functions.

### Approximate Bayesian Computation (ABC)

The Approximate Bayesian Computation (ABC) approximates the posterior
distribution by comparing summary statistics from simulated data
$y_{\text{sim}}$ and observed data $y_{\text{obs}}$:

$$p_{\varepsilon}\left( \theta \mid y_{\text{obs}} \right) \propto \pi(\theta)\, K_{\varepsilon}\!\left( \rho\!\left( S\left( y_{\text{sim}} \right),\, S\left( y_{\text{obs}} \right) \right) \right),$$

where $S( \cdot )$ denotes a vector of summary statistics,
$\rho( \cdot )$ is a distance function, and $K_{\varepsilon}$ is a
kernel with tolerance $\varepsilon$.

Here, the intractable likelihood is replaced by a kernel-weighted
similarity between summary statistics of simulated and observed data,
such that parameters producing simulations closer to the observed data
receive higher posterior weight, with the tolerance $\varepsilon$
controlling the approximation accuracy.

In the classical Rejection ABC algorithm, for each iteration
$i = 1,\ldots,N$: (1) draw $\theta_{i} \sim \pi(\theta)$; (2) simulate
$y_{\text{sim}} \sim M\left( \theta_{i} \right)$; (3) compute
$d_{i} = \rho\left( S\left( y_{\text{sim}} \right),S\left( y_{\text{obs}} \right) \right)$;
(4) accept $\theta_{i}$ if $d_{i} \leq \varepsilon$.

This produces the approximate posterior
$\pi_{\varepsilon}(\theta \mid y)$.

However, the Rejection ABC algorithm suffers from low acceptance rates
and a bias–variance trade-off in the tolerance $\varepsilon$. To address
this, Beaumont et al. (2002) proposed a local linear regression
adjustment:
$$\theta_{i} = \alpha + \left( S\left( y_{\text{sim}} \right) - S\left( y_{\text{obs}} \right) \right)^{T}\beta + \zeta_{i},$$
which is then adjusted toward $S\left( y_{\text{obs}} \right)$:
$$\theta_{i}^{*} = \theta_{i} - \left( S\left( y_{\text{sim}} \right) - S\left( y_{\text{obs}} \right) \right)^{T}\beta.$$
This adjustment allows simulated samples that would otherwise fall
outside the tolerance to be shifted into the acceptance region, which
increases the acceptance rate and reduces sensitivity to the choice of
$\epsilon$.

Following this direction, Ridge regression adjustment extends it by
projecting summary statistics into a high-dimensional RKHS using kernels
(e.g., Gaussian RBF), enabling nonlinear estimation of
${\mathbb{E}}\lbrack\theta \mid s\rbrack$. Blum et al. (2010) proposed a
nonlinear, heteroscedastic regression model:
$$\theta = m(s) + \sigma(s) \cdot \zeta,$$ with $m( \cdot )$ and
$\log\left( \sigma^{2}( \cdot ) \right)$ estimated using neural networks
with weight decay on accepted $\left( \theta_{i},s_{i} \right)$ pairs.
This correction improves robustness in high-dimensional summary spaces
and mitigates the curse of dimensionality.

### Amortized Bayesian Inference (ABI)

While methods such as ABC require running inference each time new ABI
allows one to first train a neural network that learns a mapping between
the parameter space and the data (or summary statistics), and then reuse
this learned mapping to directly infer parameters in subsequent analyses
without repeated optimization.

Existing implementations of amortized Bayesian inference (ABI) in this
package are neural Bayes estimators and neural posterior inference.

Neural Bayes estimators aim to find decision rules that minimize the
Bayes risk under a chosen loss
$L\left( \theta,\widehat{\theta}(Z) \right)$ and prior $\pi(\theta)$:
$$\min\limits_{\widehat{\theta}}\int_{\Theta}\int_{Z}L\left( \theta,\widehat{\theta}(Z) \right)\, p(Z \mid \theta)\,\pi(\theta)\, dZ\, d\theta,$$
where $\theta$ is the latent true parameter and $\widehat{\theta}(Z)$ is
the estimator produced from data (or summary statistics) $Z$. The loss
function may be chosen flexibly (e.g., quadratic, absolute, quantile
loss), leading to different Bayesian optimal decision rules (e.g.,
posterior mean, median, quantiles). By optimizing the loss function via
backpropagation and stochastic gradient descent using simulated
$(\theta,Z)$ pairs, neural Bayes estimators amortize the cost of
inference. Once trained, the network can be applied repeatedly to new
observed data to produce fast and accurate point estimates with
essentially zero additional inference cost.

Neural posterior estimators, on the other hand, aim to approximate the
entire posterior distribution $p(\theta \mid Z)$ by learning a mapping
from data to the parameters of a chosen distribution family
$\left. \kappa( \cdot ):Z\rightarrow K \right.$ through minimization of
the expected Kullback–Leibler divergence between the true posterior and
the approximating distribution:
$$\kappa^{*}( \cdot ) = \arg\min\limits_{\kappa{( \cdot )}}{\mathbb{E}}_{Z}\!\left\lbrack KL\!\left( p(\theta \mid Z)\;\parallel\; q\left( \theta;\kappa(Z) \right) \right) \right\rbrack,$$
where $\kappa^{*}( \cdot )$ is the trained neural estimator,
$q\left( \theta;\kappa(Z) \right)$ is the approximated posterior family,
and the expectation is taken over all possible realizations of $Z$.

## A standard workflow in the eam package

A standard procedure of simulation-based inference involves several
steps:

**First**, a generative model or simulator $M(\theta)$ is defined, which
specifies how observable data $y$ are generated from underlying
parameters $\theta$.

**Second**, parameters are sampled from a prior distribution
$\pi(\theta)$, reflecting prior beliefs or theoretical constraints.

**Third**, for each sampled parameter value, synthetic datasets
$y_{\text{sim}}$ are simulated from the model, producing pairs of
parameters and corresponding simulated observations.

**Fourth**, the similarity between simulated and observed data is
quantified—either by computing distance metrics between summary
statistics, as in Approximate Bayesian Computation (ABC) or Amortized
Bayesian Inference (ABI).

**Finally**, the approximate posterior distribution
$p\left( \theta \mid y_{\text{obs}} \right)$ is obtained by weighting or
sampling parameters according to this similarity or likelihood estimate.

![The standard workflow in the eam
package](00-framework-overview/workflow.svg)

The following sections provide a structured overview of the standard
simulation and inference workflow supported by the package.

**Section 1:** [Getting Started: A Minimal Working
Example](https://y-guang.github.io/eam/articles/10-minimal-working-example.md)
introduces the core functions of the package and provides a minimal
runnable example based on a three-parameter Drift Diffusion Model (DDM).

**Section 2:** [Models in
eam](https://y-guang.github.io/eam/articles/20-models-in-eam.md)
demonstrates how representative evidence accumulation models can be
specified within the package, and how they can be extended to
multi-response settings or intergeted with covariates.

**Section 3:** [An Empirical Example: Simulation-Based Inference for
Free
Recall](https://y-guang.github.io/eam/articles/30-empirical-example.md)
presents a real-world application using free recall data, illustrating
how the package can be applied to empirical datasets in practice.

Reference:

Beaumont, M. A., Zhang, W., & Balding, D. J. (2002). Approximate
Bayesian computation in population genetics. Genetics, 162 (4),
2025–2035. <https://doi.org/10.1093/genetics/162.4.2025>

Blum, M. G. B., & François, O. (2010). Non-linear regression models for
approximate Bayesian computation. Statistics and Computing, 20 (1),
63–73. <https://doi.org/10.1007/s11222-009-9116-0>

Csilléry, K., François, O., & Blum, M. G. B. (2012). abc: An R package
for approximate Bayesian computation (ABC). Methods in Ecology and
Evolution, 3 (3), 475–479.
<https://doi.org/10.1111/j.2041-210x.2011.00179.x>

Sainsbury-Dale, M., Zammit-Mangion, A., & Huser, R. (2024).
Likelihood-free parameter estimation with neural Bayes estimators. The
American Statistician, 78 (1), 1–14.
<https://doi.org/10.1080/00031305.2023.2275927>
