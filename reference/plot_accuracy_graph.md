# Plot accuracy graph (internal)

Plot accuracy graph (internal)

## Usage

``` r
plot_accuracy_graph(
  accuracy_df,
  x = "item_idx",
  y = "accuracy",
  facet_x = c(),
  facet_y = c()
)
```

## Arguments

- accuracy_df:

  Data frame with accuracy values

- x:

  Variable for x-axis

- y:

  Variable for y-axis (default: "accuracy")

- facet_x:

  Variables for faceting columns

- facet_y:

  Variables for faceting rows

## Value

A ggplot2 object
