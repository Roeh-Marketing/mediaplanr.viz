# Chart how spend moves across a set of scenarios

A slope chart: one line per line item, one position per scenario. The
picture of
[`mediaplanr::compare_scenarios()`](https://roeh-marketing.github.io/mediaplanr/reference/compare_scenarios.html)
at cell level — a cut is a line falling, an addition a line rising from
zero, and a cell owned by a subplan is flat by construction, because no
scenario can edit it.

## Usage

``` r
ec_compare(x, by = NULL, theme = "light")
```

## Arguments

- x:

  A `ScenarioSet`, or the data frame
  [`mediaplanr::compare_scenarios()`](https://roeh-marketing.github.io/mediaplanr/reference/compare_scenarios.html)
  returns at `level = "cell"`.

- by:

  Columns identifying a line to draw. Defaults to the set's line item
  grain — the grain without its time column — so a weekly set draws one
  line per line item rather than one per cell-week. Required when `x` is
  a data frame with no obvious line item columns.

- theme:

  A
  [`viz_theme()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/viz_theme.md)
  name or override list.

## Value

A
[`new_spec()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/new_spec.md)
of kind `"compare"`.

## See also

[`ec_lineage()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_lineage.md),
[`mediaplanr::compare_scenarios()`](https://roeh-marketing.github.io/mediaplanr/reference/compare_scenarios.html)

## Examples

``` r
base <- mediaplanr::media_plan_from_df(
  data.frame(week = as.Date("2026-07-06"), channel = c("TV", "Search"),
             planned_spend = c(80, 40)),
  grain = "channel", time = "week", name = "base"
)
s1  <- mediaplanr::build_scenario(
  base, list(target = list(channel = "Search"), total = 60), name = "Search up")
set <- mediaplanr::add_scenario(mediaplanr::scenario_set(base), s1)
ec_compare(set)
#> <mediaplanr_spec> compare
#>   from    compare_scenarios(set, "cell")
#>   series  2
#>   size    1,677 bytes of JSON
#>   meta    scenarios, cells, by
#> 
#>   as_widget() to draw it, as_json() to send it
```
