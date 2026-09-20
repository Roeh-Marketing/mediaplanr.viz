# The colours a spec is built with

Every `ec_*()` function takes a `theme`. Pass `"light"` (default) or
`"dark"` for the built-in palettes, or a named list overriding any of
their entries — `mediaplanr.viz` ships no client's colours, so a brand
palette is supplied here rather than patched into the option afterwards.

## Usage

``` r
viz_theme(theme = "light")
```

## Arguments

- theme:

  `"light"`, `"dark"`, or a named list of overrides. A list may set
  `base` to say which palette it starts from; without it, light.

## Value

A named list: `ink`, `ink_2`, `ink_3`, `surface`, `rule`, `grid`,
`accent`, `owner` (a character vector), `topline`, and `status` (a named
character vector).

## Details

Three roles are kept deliberately separate. `accent` is the plan's own
colour. `owner` is a categorical ramp assigned to subplan keys in the
order they are attached, so the same subplan is the same colour in every
chart of one plan. `status` maps
[`mediaplanr::status_levels()`](https://roeh-marketing.github.io/mediaplanr/reference/status_levels.html)
— plus `""` for unset — to semantic colours, and is never reused for
anything else.

## Examples

``` r
viz_theme("dark")$accent
#> [1] "#3FB4BE"
viz_theme(list(accent = "#B0004F"))$accent
#> [1] "#B0004F"
```
