# A subplan tree as an interactive table

Every plan in the tree as a row, indented by depth: what it backs, its
grain and cadence, how big it is, and whether its rows are locked on the
plan above. Sorting, and a detail panel per row, come from `reactable`.

## Usage

``` r
tbl_tree(x, theme = "light", ...)
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

- ...:

  Passed to
  [`reactable::reactable()`](https://glin.github.io/reactable/reference/reactable.html),
  so any of its options — `defaultSorted`, `height`, `striped` — reach
  through.

## Value

A `reactable` htmlwidget.

## See also

[`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md),
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
tbl_tree(mediaplanr::attach_subplan(topline, tv))

{"x":{"tag":{"name":"Reactable","attribs":{"data":{"name":["Q3 topline","TV detail"],"key":[null,"TV"],"grain":["channel + week","channel + partner + week"],"cadence":["weekly","weekly"],"line_items":[2,2],"spend":[160,120],"status":["",""]},"columns":[{"id":".details","name":"","type":null,"sortable":false,"resizable":false,"filterable":false,"searchable":false,"width":45,"align":"center","details":[{"name":"div","attribs":{"style":{"padding":"12px 16px","font-family":"IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace","font-size":"12px","color":"#4A5563"}},"children":[{"name":"div","attribs":{},"children":["plan id   plan_20261120005939_03a2f0"]},{"name":"div","attribs":{},"children":["path      (topline)"]},{"name":"div","attribs":{},"children":["subplans  1"]},{"name":"div","attribs":{},"children":["rows      2"]}]},{"name":"div","attribs":{"style":{"padding":"12px 16px","font-family":"IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace","font-size":"12px","color":"#4A5563"}},"children":[{"name":"div","attribs":{},"children":["plan id   plan_20261120005939_a16ea3"]},{"name":"div","attribs":{},"children":["path      TV"]},{"name":"div","attribs":{},"children":["subplans  0"]},{"name":"div","attribs":{},"children":["rows      2"]}]}]},{"id":"name","name":"plan","type":"character","cell":[{"name":"div","attribs":{"style":{"padding-left":"0px"}},"children":[{"name":"div","attribs":{"style":{"display":"inline-block","height":"8px","width":"90px","border-radius":"2px","vertical-align":"middle","margin-right":"8px","background":"#0F7B85"}},"children":[]},{"name":"span","attribs":{"style":{"font-weight":"500"}},"children":["Q3 topline"]}]},{"name":"div","attribs":{"style":{"padding-left":"20px"}},"children":[{"name":"div","attribs":{"style":{"display":"inline-block","height":"8px","width":"68px","border-radius":"2px","vertical-align":"middle","margin-right":"8px","background":"#0F7B85"}},"children":[]},{"name":"span","attribs":{"style":{"font-weight":"500"}},"children":["TV detail"]}]}],"minWidth":200},{"id":"key","name":"backs","type":"character","cell":[{"name":"span","attribs":{"style":{"color":"#7C8794"}},"children":["—"]},{"name":"Fragment","attribs":[],"children":[{"name":"span","attribs":{"style":{"font-family":"IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace"}},"children":["TV"]},{"name":"span","attribs":{"style":{"font-size":"11px","color":"#7C8794","margin-left":"8px"}},"children":["locked"]}]}],"minWidth":140},{"id":"grain","name":"grain","type":"character","minWidth":160},{"id":"cadence","name":"cadence","type":"character","minWidth":90},{"id":"line_items","name":"line items","type":"numeric","minWidth":90,"align":"right"},{"id":"spend","name":"spend","type":"numeric","cell":["160","120"],"minWidth":110,"align":"right","style":{"fontFamily":"IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace","fontVariantNumeric":"tabular-nums"}},{"id":"status","name":"status","type":"character","cell":[{"name":"span","attribs":{"style":{"color":"#7C8794"}},"children":["—"]},{"name":"span","attribs":{"style":{"color":"#7C8794"}},"children":["—"]}],"minWidth":130}],"highlight":true,"borderless":true,"compact":true,"theme":{"color":"#18212B","backgroundColor":"#FFFFFF","borderColor":"#E1E6EB","stripedColor":"#E1E6EB","highlightColor":"#E1E6EB","headerStyle":{"fontFamily":"IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace","fontSize":"11.5px","letterSpacing":".06em","textTransform":"uppercase","color":"#7C8794","fontWeight":500,"borderBottom":"1px solid #D5DBE2"}},"dataKey":"fac656d7fd8abdc7dfcf8f779e51bb88"},"children":[]},"class":"reactR_markup"},"evals":[],"jsHooks":[]}
```
