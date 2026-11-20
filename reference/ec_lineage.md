# Chart a scenario set's lineage

A left-to-right derivation tree: each scenario sits beside the plan it
was actually derived from, with the spend change on the way there. A set
whose scenarios all came from the base is one fan; a chain — base, a
scenario from it, a scenario from *that* — reads as a chain, which is
the thing
[`mediaplanr::compare_scenarios()`](https://roeh-marketing.github.io/mediaplanr/reference/compare_scenarios.html)
cannot show, since it measures everything against the baseline.

## Usage

``` r
ec_lineage(x, base_name = NULL, theme = "light")
```

## Arguments

- x:

  A `ScenarioSet`, or the data frame
  [`mediaplanr::lineage()`](https://roeh-marketing.github.io/mediaplanr/reference/lineage.html)
  returns.

- base_name:

  Name of the baseline scenario, which is ringed. Taken from the set
  automatically; supply it when passing a data frame.

- theme:

  A
  [`viz_theme()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/viz_theme.md)
  name or override list.

## Value

A
[`new_spec()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/new_spec.md)
of kind `"lineage"`. Its `meta` carries `ids` and `scenarios` in row
order, and `current`: the scenarios that are the current approved plan
on their branch.

## Details

Nodes are coloured by workflow **status**, and the baseline is ringed.
An approved scenario with no approved descendant – the current approved
plan on its branch, as
[`mediaplanr::lineage()`](https://roeh-marketing.github.io/mediaplanr/reference/lineage.html)
marks it – is drawn as a diamond, and an approved scenario's tooltip
gives its revision and approval date, both derived by
[`lineage()`](https://roeh-marketing.github.io/mediaplanr/reference/lineage.html).
Scenarios whose parent is not in the set are roots, so a set of
independently authored plans draws as a forest rather than a lie.

## See also

[`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md),
[`ec_compare()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_compare.md),
[`mediaplanr::lineage()`](https://roeh-marketing.github.io/mediaplanr/reference/lineage.html)

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
ec_lineage(set)
#> <mediaplanr_spec> lineage
#>   from    lineage()
#>   series  1
#>   size    1,949 bytes of JSON
#>   meta    ids, scenarios, base_name, current
#> 
#>   as_widget() to draw it, as_json() to send it
```
