# The gallery

``` r

library(mediaplanr)
library(mediaplanr.viz)
```

Every chart here is drawn from one plan, so the pictures can be read
against each other. It is the shape a real engagement takes: a weekly
topline the whole team looks at, a TV team planning flighted buys by
partner, an NBC daypart plan beneath *that*, and a Search team working
Sunday-start weeks.

## The plan

``` r

weeks <- seq(as.Date("2026-04-06"), by = "week", length.out = 13)
shape <- c(0.6, 0.8, 1, 1.1, 1.2, 1.2, 1.1, 1, 1, 0.9, 0.8, 0.7, 0.6)
base_wk <- c(TV = 90000, Search = 45000, Social = 30000, Audio = 12000)

top_df <- expand.grid(week = weeks, channel = names(base_wk),
                      stringsAsFactors = FALSE)
top_df$planned_spend <- round(base_wk[top_df$channel] *
                                shape[match(top_df$week, weeks)])

topline <- media_plan_from_df(
  top_df, grain = "channel", time = "week",
  name = "Q2 2026 Brand Plan", advertiser = "Acme", planner = "R. Roe"
)
```

The TV team authors buys, not weeks, and works daily:

``` r

tv <- media_plan_from_flights(
  data.frame(
    channel = "TV", partner = c("NBC", "NBC", "ESPN", "Hulu"),
    flight_start = as.Date(c("2026-04-08", "2026-05-18", "2026-04-20", "2026-05-04")),
    flight_end   = as.Date(c("2026-05-10", "2026-06-28", "2026-06-14", "2026-06-21")),
    planned_spend = c(280000, 320000, 390000, 210000)
  ),
  grain = c("channel", "partner"), name = "TV Q2 buys",
  nickname = "TV detail", planner = "TV team", status = "to review"
)
```

NBC sits one level deeper again, by daypart, and Search runs on
Sunday-start weeks that
[`calendarize()`](https://roeh-marketing.github.io/mediaplanr/reference/calendarize.html)
bridges onto the topline’s Mondays:

``` r

nbc <- media_plan_from_df(
  data.frame(week = rep(seq(as.Date("2026-04-06"), by = "week", length.out = 12), each = 2),
             channel = "TV", partner = "NBC",
             daypart = rep(c("prime", "daytime"), 12),
             planned_spend = rep(c(38000, 12000), 12)),
  grain = c("channel", "partner", "daypart"), time = "week",
  name = "NBC upfront", status = "approved"
)

search <- media_plan_from_df(
  data.frame(week = rep(seq(as.Date("2026-04-05"), by = "week", length.out = 13), each = 2),
             channel = "Search", engine = rep(c("Google", "Bing"), 13),
             planned_spend = rep(c(41000, 6000), 13)),
  grain = c("channel", "engine"), time = "week",
  name = "Search Q2", nickname = "search", planner = "Search team"
)

plan <- revise(
  attach_subplan(attach_subplan(topline, attach_subplan(tv, nbc)), search),
  status = "approved", approved_on = as.Date("2026-03-30")
)
plan_tree(plan)
#> Q2 2026 Brand Plan  [approved 2026-03-30]                                       2,315,000
#> ├─ TV                                      TV Q2 buys   flighted  3 line items  1,200,000
#> │  ├─ TV | NBC                             NBC upfront  weekly    2 line items    600,000
#> │  └─ (editable)                                                  2 line items    600,000
#> ├─ Search                                  Search Q2    weekly    2 line items    611,000
#> └─ (editable)                                                     2 line items    504,000
```

## Structure

[`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md)
is the shape of ownership: each node a plan, each edge the cell it
backs.

``` r

as_widget(ec_tree(plan), height = "320px")
```

[`tbl_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/tbl_tree.md)
is the same tree a planner can sort and open. For day-to-day use it is
usually the more useful of the two — the lock marker answers *can I edit
this here?* without any geometry to read.

``` r

tbl_tree(plan)
```

[`ec_ownership()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_ownership.md)
puts the question on a grid: line items down, weeks across, coloured by
who owns the number. The locked block is what a scenario cannot touch.

``` r

as_widget(ec_ownership(plan), height = "300px")
```

Notice the left edge. Search plans Sunday-start weeks, so its spend
lands partly in the week *before* the topline’s first Monday —
[`calendarize()`](https://roeh-marketing.github.io/mediaplanr/reference/calendarize.html)
did that, and the grid shows it rather than hiding it.

## Money

``` r

as_widget(ec_sunburst(plan), height = "420px")
```

[`ec_rollup()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_rollup.md)
explains one cell: the TV subplan’s partner totals stacking into the
number the topline holds. This is the picture behind the error message
*“channel TV is planned in a subplan; edit the subplan and re-attach”*.

``` r

as_widget(ec_rollup(plan, "TV"), height = "320px")
```

## Scenarios

``` r

s1  <- build_scenario(plan, list(target = list(channel = "Social"), scale = 1.25),
                      name = "Social +25%", nickname = "social up")
s2  <- build_scenario(s1, list(target = list(channel = "Audio"), drop = TRUE),
                      name = "Social +25%, no Audio", nickname = "no audio",
                      status = "to review")
s3  <- build_scenario(plan, list(target = list(channel = "Audio"), total = 300000),
                      name = "Audio push", nickname = "audio push")
set <- add_scenario(add_scenario(add_scenario(scenario_set(plan, "base"), s1), s2), s3)

as_widget(ec_lineage(set), height = "320px")
```

[`ec_lineage()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_lineage.md)
measures each scenario against the plan it was **actually derived
from**, so the chain reads as a chain: *no audio* is −144,000 against
*social up*, not against the baseline.
[`compare_scenarios()`](https://roeh-marketing.github.io/mediaplanr/reference/compare_scenarios.html)
— and
[`ec_compare()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_compare.md)
below — measure everything against the baseline instead. Both are true;
they answer different questions.

The baseline is approved and nothing approved has been derived from it,
so it is the current approved plan — the plan being bought against — and
is drawn as a diamond. Its tooltip reads *Rev 1* with its approval date:
a revision is derived from the lineage, never stored on a plan.

``` r

as_widget(ec_compare(set), height = "320px")
```

TV and Search are flat across every scenario. That is not a coincidence
in the data: they are owned by subplans, and no scenario is allowed to
edit them.

## The spec is data

Every chart above is a list. Printing one says what it is rather than
dumping it:

``` r

spec <- ec_lineage(set)
spec
#> <mediaplanr_spec> lineage
#>   from    lineage()
#>   series  1
#>   size    2,921 bytes of JSON
#>   meta    ids, scenarios, base_name, current
#> 
#>   as_widget() to draw it, as_json() to send it
```

And it converts to JSON that any ECharts renderer accepts, with no
JavaScript in it:

``` r

cat(substr(as_json(spec, pretty = TRUE), 1, 400), "...")
#> {
#>   "textStyle": {
#>     "fontFamily": "IBM Plex Sans, system-ui, -apple-system, Segoe UI, sans-serif",
#>     "color": "#18212B"
#>   },
#>   "tooltip": {
#>     "backgroundColor": "#FFFFFF",
#>     "borderColor": "#D5DBE2",
#>     "textStyle": {
#>       "color": "#18212B",
#>       "fontFamily": "IBM Plex Sans, system-ui, -apple-system, Segoe UI, sans-serif",
#>       "fontSize": 13
#>     }
#>   },
#>   "series": [
#>     {
#>       "ty ...
```

That is the whole reason this package emits specs rather than plots. The
same list renders here, in a Shiny app, or in a frontend that has never
run R — and an agent holding a tool that returns
`as_json(ec_lineage(set))` has given its caller a chart, not a picture
of one.

## Theming

The palette keeps three roles apart: an accent for the plan’s own marks,
an owner ramp so one subplan is one colour in every chart, and status
colours reserved for
[`status_levels()`](https://roeh-marketing.github.io/mediaplanr/reference/status_levels.html).
Pass a name or a list of overrides.

``` r

str(viz_theme("dark")[c("accent", "topline")])
#> List of 2
#>  $ accent : chr "#3FB4BE"
#>  $ topline: chr "#6F7A8A"
as_widget(ec_tree(plan, theme = list(base = "dark", accent = "#B0004F")),
          height = "320px")
```
