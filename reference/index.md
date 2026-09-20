# Package index

## Structure

What hangs beneath a plan. The tree is the shape of its ownership; the
table is the same thing a planner can sort and open; the grid says which
cells are locked and by whom. One subplan keeps one colour across all
three.

- [`ec_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_tree.md)
  : Chart the subplan tree
- [`tbl_tree()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/tbl_tree.md)
  : A subplan tree as an interactive table
- [`ec_ownership()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_ownership.md)
  : Chart which cells a subplan owns

## Money

Where the spend sits in the nesting, how one backed cell arrives at its
number, and how it moves across a set of scenarios.

- [`ec_sunburst()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_sunburst.md)
  : Chart spend by nesting
- [`ec_rollup()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_rollup.md)
  : Chart how a backed cell adds up
- [`ec_compare()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_compare.md)
  : Chart how spend moves across a set of scenarios

## Lineage

Where a scenario came from. Each one measured against the plan it was
actually derived from, which is what makes a chain read as a chain.

- [`ec_lineage()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/ec_lineage.md)
  : Chart a scenario set's lineage

## The spec

Every chart function returns a spec – a plain list holding an ECharts
option. Send it as JSON, or draw it as a widget.

- [`new_spec()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/new_spec.md)
  : A chart specification
- [`as_json()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/as_json.md)
  [`as_widget()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/as_json.md)
  : Convert a spec to JSON or to a widget
- [`viz_theme()`](https://roeh-marketing.github.io/mediaplanr.viz/reference/viz_theme.md)
  : The colours a spec is built with
