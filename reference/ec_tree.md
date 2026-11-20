# Chart the subplan tree

A left-to-right tree of the plans nested inside one plan: each node is a
plan, each edge the cell it backs. The root is the topline; a leaf is a
plan nobody has attached anything beneath.

## Usage

``` r
ec_tree(x, theme = "light")
```

## Arguments

- x:

  A `MediaPlan`, or the data frame
  [`mediaplanr::subplan_map()`](https://roeh-marketing.github.io/mediaplanr/reference/subplan_map.html)
  returns.

- theme:

  A
  [`viz_theme()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/viz_theme.md)
  name or override list.

## Value

A
[`new_spec()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/new_spec.md)
of kind `"tree"`. Its `meta` carries `ids` — the plan id of each node in
pre-order — so an app can wire a click back to a plan, and `owners`, the
colour assigned to each subplan key.

## Details

Nodes are coloured by **owner** — the depth-1 branch each belongs to —
not by status, so one subplan keeps one colour across `ec_tree()`,
[`ec_ownership()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_ownership.md)
and
[`ec_sunburst()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_sunburst.md),
and the three read as one system. Status appears in the tooltip.
[`ec_lineage()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_lineage.md)
is the chart that colours by status, since scenarios have no owner.

## See also

[`ec_lineage()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_lineage.md),
[`tbl_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/tbl_tree.md),
[`mediaplanr::subplan_map()`](https://roeh-marketing.github.io/mediaplanr/reference/subplan_map.html)

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
ec_tree(mediaplanr::attach_subplan(topline, tv))
#> <mediaplanr_spec> tree
#>   from    subplan_map()
#>   series  1
#>   size    2,028 bytes of JSON
#>   meta    ids, keys, owners
#> 
#>   as_widget() to draw it, as_json() to send it
```
