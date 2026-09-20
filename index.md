# mediaplanr.viz

Web charts for
[`mediaplanr`](https://github.com/Roeh-Marketing/mediaplanr) plans: the
subplan tree, who owns which cell, how a backed cell adds up, and where
a scenario came from.

## The spec is the product

Every function returns a **spec** — a plain R list holding an [Apache
ECharts](https://echarts.apache.org) `option`. Not a widget, not a plot
object.

``` r

library(mediaplanr)
library(mediaplanr.viz)

topline <- media_plan_from_df(
  data.frame(week = as.Date("2026-07-06"), channel = c("TV", "Search"),
             planned_spend = c(100000, 40000)),
  grain = "channel", time = "week", name = "Q3 topline"
)
tv <- media_plan_from_df(
  data.frame(week = as.Date("2026-07-06"), channel = "TV",
             partner = c("NBC", "ESPN"),
             planned_spend = c(70000, 50000)),
  grain = c("channel", "partner"), time = "week", name = "TV detail"
)

spec <- ec_tree(attach_subplan(topline, tv))
spec
#> <mediaplanr_spec> tree
#>   from    subplan_map()
#>   series  1
#>   size    2,505 bytes of JSON

as_widget(spec)   # draw it, in Shiny or a notebook
as_json(spec)     # send it, to anything that speaks JSON
```

That indirection is the point. The same list renders in Shiny, is
returned from an LLM tool call and drawn by a frontend that has never
run R, sits in a file next to
[`plan_to_json()`](https://roeh-marketing.github.io/mediaplanr/reference/plan_to_json.html)
output, and can be read — or edited — by anything that speaks JSON.
Nothing in a spec is a JavaScript callback: every label and tooltip is
formatted in R and travels as a literal string.

## It draws projections, not plans

`mediaplanr` owns the data work and exports it as projections —
[`subplan_map()`](https://roeh-marketing.github.io/mediaplanr/reference/subplan_map.html),
[`ownership_map()`](https://roeh-marketing.github.io/mediaplanr/reference/ownership_map.html),
[`lineage()`](https://roeh-marketing.github.io/mediaplanr/reference/lineage.html),
[`compare_scenarios()`](https://roeh-marketing.github.io/mediaplanr/reference/compare_scenarios.html),
[`calendarize()`](https://roeh-marketing.github.io/mediaplanr/reference/calendarize.html),
[`roll_up()`](https://roeh-marketing.github.io/mediaplanr/reference/roll_up.html).
This package only ever reads those, never a plan’s `@data`. So a change
to the plan model surfaces as a change to one table rather than to seven
charts, and every function takes the projection directly when you
already have one in hand:

``` r

ec_tree(plan)                 # convenience
ec_tree(subplan_map(plan))    # the same spec, from the table
```

If a picture needs a fact the projections do not carry, the fact belongs
upstream.
[`ownership_map()`](https://roeh-marketing.github.io/mediaplanr/reference/ownership_map.html)
arrived in `mediaplanr` exactly that way.

## What it draws

|  |  |
|----|----|
| [`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md) | The subplan tree: each node a plan, each edge the cell it backs |
| [`tbl_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/tbl_tree.md) | The same tree as a sortable table, with lock markers and spend bars |
| [`ec_ownership()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_ownership.md) | Line items × weeks, coloured by who owns the number |
| [`ec_sunburst()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_sunburst.md) | Spend by nesting, one ring per level |
| [`ec_rollup()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_rollup.md) | How one backed cell adds up — the reconciliation view |
| [`ec_compare()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_compare.md) | How spend moves across a set of scenarios |
| [`ec_lineage()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_lineage.md) | Where each scenario came from, and what it cost to get there |

Colour carries meaning and the roles stay apart: an **accent** for the
plan’s own marks, an **owner** ramp so one subplan is one colour in
every chart, and **status** colours reserved for
[`mediaplanr::status_levels()`](https://roeh-marketing.github.io/mediaplanr/reference/status_levels.html).
Pass `theme = "dark"`, or a list of overrides, to any of them — the
package ships no client’s palette.

See
[`vignette("gallery")`](https://roeh-marketing.github.io/mediaplanr.viz/articles/gallery.md)
for all seven on one worked plan.

## Installation

``` r

# install.packages("pak")
pak::pak("Roeh-Marketing/mediaplanr.viz")
```

## Related

- [`mediaplanr`](https://github.com/Roeh-Marketing/mediaplanr) — the
  plan model these charts read. It stays graphics-free on purpose; this
  package is where the dependencies live.
