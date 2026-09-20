# Chart which cells a subplan owns

Line items down, periods across, each cell coloured by the plan that
owns its number: the topline's own cells in a neutral, each subplan's in
its own colour. Locked rows are grouped at the top, so the region a
planner cannot edit here reads as a block.

## Usage

``` r
ec_ownership(x, theme = "light")
```

## Arguments

- x:

  A `MediaPlan`, or the data frame
  [`mediaplanr::ownership_map()`](https://roeh-marketing.github.io/mediaplanr/reference/ownership_map.html)
  returns.

- theme:

  A
  [`viz_theme()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/viz_theme.md)
  name or override list.

## Value

A
[`new_spec()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/new_spec.md)
of kind `"ownership"`. Its `meta` carries `items` (the row order),
`periods` (the column order) and `owners`.

## Details

Owner colours match
[`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md)
and
[`ec_sunburst()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_sunburst.md)
for the same plan.

## See also

[`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md),
[`mediaplanr::ownership_map()`](https://roeh-marketing.github.io/mediaplanr/reference/ownership_map.html)

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
ec_ownership(mediaplanr::attach_subplan(topline, tv))
#> <mediaplanr_spec> ownership
#>   from    ownership_map()
#>   series  1
#>   size    1,680 bytes of JSON
#>   meta    items, periods, owners, time_col
#> 
#>   as_widget() to draw it, as_json() to send it
```
