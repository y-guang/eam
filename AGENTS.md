# EAM(Evidence Accumulation Model) Agents Guide

## Framework

- docstring: roxygen2
- computation backend: Rcpp
- testing: testthat

## Code style

- Follow the tidyverse and modern style guide for all R code.
- Always use fully qualified namespace calls for all non-base functions, e.g., use dplyr::filter() instead of filter().
  - Exception: user-facing examples and vignettes (e.g., @examples sections) may omit namespaces for readability.
- Adhere strictly to CRAN policies, including documentation completeness, namespace hygiene, and other constraints.

## Dev instructions

- When first writing a function, without other specifications,
  - Provide only concise descriptions, and @param and @return tags.
- Comment only for readability and explain non-trivial logic. Avoid reply user in comments - assume user are senior R programmers, who can understand common logic.
