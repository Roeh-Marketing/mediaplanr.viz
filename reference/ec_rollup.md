# Chart how a backed cell adds up

A waterfall for one cell of a topline: the subplan's line items stacking
up to the number the parent holds, with the parent's total as a final
bar. This is the reconciliation view — the picture behind *"channel TV
is planned in a subplan; edit the subplan and re-attach"*.

## Usage

``` r
ec_rollup(x, key = NULL, theme = "light")
```

## Arguments

- x:

  A `MediaPlan` holding at least one subplan.

- key:

  The cell to explain — a name from `names(x@subplans)`. Defaults to the
  first, so a plan with one subplan needs no argument.

- theme:

  A
  [`viz_theme()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/viz_theme.md)
  name or override list.

## Value

A
[`new_spec()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/new_spec.md)
of kind `"rollup"`.

## See also

[`ec_sunburst()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_sunburst.md),
[`mediaplanr::attach_subplan()`](https://roeh-marketing.github.io/mediaplanr/reference/attach_subplan.html)

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
ec_rollup(mediaplanr::attach_subplan(topline, tv))
#> <mediaplanr_spec> rollup
#>   from    roll_up(subplan)
#>   series  2
#>   size    2,039 bytes of JSON
#>   meta    key, categories
#> 
#>   as_widget() to draw it, as_json() to send it
```
