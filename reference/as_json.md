# Convert a spec to JSON or to a widget

Two ways out of a
[`new_spec()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/new_spec.md).
`as_json()` gives the ECharts option as a JSON string — hand it to a
frontend, a tool call, or a file, and pass it straight to
`echarts.setOption()`. `as_widget()` wraps it in an `echarts4r`
htmlwidget for Shiny, R Markdown and Quarto.

## Usage

``` r
as_json(x, pretty = FALSE, ...)

as_widget(x, height = NULL, width = NULL, ...)
```

## Arguments

- x:

  A `mediaplanr_spec`.

- pretty:

  Whether to indent the JSON. Default `FALSE`, since the usual
  destination is a machine.

- ...:

  Unused.

- height, width:

  Widget dimensions, passed to
  [`echarts4r::e_charts()`](https://echarts4r.john-coene.com/reference/init.html).
  `NULL` fills the container.

## Value

`as_json()` a JSON string; `as_widget()` an `echarts4r` htmlwidget.

## Examples

``` r
p <- mediaplanr::media_plan_from_df(
  data.frame(week = as.Date("2026-07-06"), channel = c("TV", "Search"),
             planned_spend = c(80, 40)),
  grain = "channel", time = "week", name = "Q3"
)
substr(as_json(ec_tree(p)), 1, 60)
#> [1] "{\"textStyle\":{\"fontFamily\":\"IBM Plex Sans, system-ui, -apple"
```
