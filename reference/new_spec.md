# A chart specification

The object every `ec_*()` function returns: a list holding an Apache
ECharts `option`, plus the kind of chart it is and the `mediaplanr`
projection it was built from. Print it for a summary,
[`as_json()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/as_json.md)
it for a frontend,
[`as_widget()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/as_json.md)
it for Shiny or a notebook.

## Usage

``` r
new_spec(option, kind, source, meta = list())
```

## Arguments

- option:

  The ECharts option, as a named list.

- kind:

  Short name of the chart kind, e.g. `"tree"`.

- source:

  The projection it was built from, e.g. `"subplan_map()"`.

- meta:

  Optional named list of extra facts a caller may want — node ids,
  category order — carried alongside rather than inside the option.

## Value

An object of class `mediaplanr_spec`.

## Examples

``` r
new_spec(list(series = list()), kind = "tree", source = "subplan_map()")
#> <mediaplanr_spec> tree
#>   from    subplan_map()
#>   series  0
#>   size    13 bytes of JSON
#> 
#>   as_widget() to draw it, as_json() to send it
```
