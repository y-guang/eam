# Summarise data by groups with optional pivoting

This function provides a flexible way to group data, compute summary
statistics, and reshape results. It works similar to
\`dplyr::summarise()\` but with added capabilities for pivoting results
wider.

## Usage

``` r
summarise_by(
  .data = NULL,
  ...,
  .by = c("condition_idx"),
  .wider_by = c("condition_idx")
)
```

## Arguments

- .data:

  A data frame to summarise, or NULL to create a reusable summary
  function

- ...:

  Summary expressions using dplyr-style syntax. Named arguments become
  column names in the output (e.g., \`mean_rt = mean(rt)\`).

- .by:

  Character vector of grouping column names. Default is "condition_idx".

- .wider_by:

  Character vector of columns to keep as identifiers when pivoting.
  Default is "condition_idx". Must be a subset of \`.by\`. When
  \`.wider_by\` differs from \`.by\`, the extra columns in \`.by\` will
  be spread across as column suffixes.

## Value

\- If \`.data\` is provided: A data frame with summarised results - If
\`.data\` is NULL: A function that can be applied to data later

## Details

You can use \`summarise_by()\` in two ways: 1. \*\*Direct use\*\*: Pass
your data directly and get results immediately 2.
\*\*Build-then-apply\*\*: Create reusable summary functions, combine
them with \`+\`, then apply to your data later

The build-then-apply approach is useful when you want to compute
different types of summaries (e.g., RT statistics and accuracy
statistics) and automatically join them together.

## Usage with ABC workflows

If you plan to use
[`build_abc_input`](https://y-guang.github.io/eam/reference/build_abc_input.md)
for ABC analysis, you must use `summarise_by()` to generate summary
statistics (or manually handle the arrow output format). This function
typically works together with
[`map_by_condition`](https://y-guang.github.io/eam/reference/map_by_condition.md)
to process simulation results. See
[`map_by_condition`](https://y-guang.github.io/eam/reference/map_by_condition.md)
for workflow examples.

## Examples

``` r
# Example 1: Direct use - pass data and get results immediately
trial_data <- data.frame(
  condition_idx = rep(1:2, each = 4),
  item_idx = rep(1:2, 4),
  rt = c(0.5, 0.6, 0.7, 0.8, 0.55, 0.65, 0.75, 0.85),
  accuracy = c(1, 1, 0, 1, 1, 0, 1, 1)
)

# Compute mean RT and accuracy by condition and item
result <- summarise_by(
  trial_data,
  mean_rt = mean(rt),
  mean_acc = mean(accuracy),
  .by = c("condition_idx", "item_idx"),
  .wider_by = "condition_idx"
)
# Result has columns: condition_idx, mean_rt_item_idx_1, mean_rt_item_idx_2, etc.
result
#> # A tibble: 2 × 5
#>   condition_idx mean_rt_item_idx_1 mean_rt_item_idx_2 mean_acc_item_idx_1
#>           <int>              <dbl>              <dbl>               <dbl>
#> 1             1               0.6                0.7                  0.5
#> 2             2               0.65               0.75                 1  
#> # ℹ 1 more variable: mean_acc_item_idx_2 <dbl>

# Example 2: Build-then-apply - create reusable summary functions
# Build separate summary functions for different statistics
rt_summary_pipe <- summarise_by(
  mean_rt = mean(rt),
  sd_rt = stats::sd(rt),
  .by = c("condition_idx", "item_idx"),
  .wider_by = "condition_idx"
)

acc_summary_pipe <- summarise_by(
  mean_acc = mean(accuracy),
  n_trials = length(accuracy),
  .by = c("condition_idx", "item_idx"),
  .wider_by = "condition_idx"
)

# Combine with + and apply to data
combined_summary_pipe <- rt_summary_pipe + acc_summary_pipe
result <- combined_summary_pipe(trial_data)
# Result has all summaries joined by condition_idx
result
#> # A tibble: 2 × 9
#>   condition_idx mean_rt_item_idx_1 mean_rt_item_idx_2 sd_rt_item_idx_1
#>           <int>              <dbl>              <dbl>            <dbl>
#> 1             1               0.6                0.7             0.141
#> 2             2               0.65               0.75            0.141
#> # ℹ 5 more variables: sd_rt_item_idx_2 <dbl>, mean_acc_item_idx_1 <dbl>,
#> #   mean_acc_item_idx_2 <dbl>, n_trials_item_idx_1 <int>,
#> #   n_trials_item_idx_2 <int>
```
