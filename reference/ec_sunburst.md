# Chart spend by nesting

A sunburst, one ring per level: the plan's own line items in the inner
ring, and any cell backed by a subplan opening into that subplan's line
items further out. A cell nobody has attached anything beneath is a
leaf.

## Usage

``` r
ec_sunburst(x, theme = "light")
```

## Arguments

- x:

  A `MediaPlan`.

- theme:

  A
  [`viz_theme()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/viz_theme.md)
  name or override list.

## Value

A
[`new_spec()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/new_spec.md)
of kind `"sunburst"`.

## Details

This is the shape of the plan's money, where
[`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md)
is the shape of its ownership. Branch colours match
[`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md)
and
[`ec_ownership()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_ownership.md).

Unlike the other builders this one needs the `MediaPlan` itself — it
walks into the subplans to build each ring, which no single projection
carries.

## See also

[`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md),
[`ec_rollup()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_rollup.md)

## Examples

``` r
topline <- mediaplanr::media_plan_from_df(
  data.frame(week = as.Date("2026-07-06"), channel = c("TV", "Search"),
             planned_spend = c(100, 40)),
  grain = "channel", time = "week", name = "Q3 topline"
)
tv <- mediaplanr::media_plan_from_df(
  data.frame(week = as.Date("2026-07-06"), channel = "TV",
             partner = c("NBC", "ESPN"),
             planned_spend = c(70, 50)),
  grain = c("channel", "partner"), time = "week", name = "TV detail"
)
ec_sunburst(mediaplanr::attach_subplan(topline, tv))
#> <mediaplanr_spec> sunburst
#>   from    the plan tree
#>   series  1
#>   size    1,766 bytes of JSON
#>   meta    owners
#> 
#>   as_widget() to draw it, as_json() to send it
```
