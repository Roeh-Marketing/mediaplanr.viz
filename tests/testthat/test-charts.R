# The ownership grid, the table, and the three money charts.

# ---- ownership ----------------------------------------------------------------

test_that("ec_ownership puts locked rows first and colours by owner", {
  th <- viz_theme("light")
  s  <- ec_ownership(nested_plan())
  expect_identical(s$meta$items[1], "TV")               # the locked one
  expect_setequal(s$meta$items, c("TV", "Search", "Social"))
  expect_identical(s$meta$owners, c("topline", "TV"))
  pieces <- opt(s)$visualMap[[1]]$pieces
  expect_identical(pieces[[1]]$color, th$topline)
  expect_identical(pieces[[2]]$color, th$owner[1])
})

test_that("each ownership cell carries its own formatted label and tooltip", {
  o <- opt(ec_ownership(nested_plan()))
  d <- o$series[[1]]$data
  expect_length(d, 3)                                   # 3 line items, no weeks
  tv <- d[[which(vapply(d, function(c) c[[9]] == "TV", logical(1)))]]
  expect_equal(tv[[4]], 125)                            # raw spend
  expect_identical(tv[[6]], "125")                      # formatted
  expect_identical(tv[[7]], "TV detail")                # owner name
  expect_identical(tv[[8]], "locked")
  se <- d[[which(vapply(d, function(c) c[[9]] == "Search", logical(1)))]]
  expect_identical(se[[7]], "the topline")
  expect_identical(se[[8]], "editable")
})

test_that("a weekly plan gets one column per week", {
  s <- ec_ownership(weekly_topline())
  expect_length(s$meta$periods, 3)
  expect_identical(s$meta$week_col, "week")
  expect_length(opt(s)$series[[1]]$data, 2 * 3)         # 2 line items x 3 weeks
})

test_that("a timeless plan gets a single column", {
  s <- ec_ownership(flat_plan())
  expect_identical(s$meta$periods, "all")
  expect_true(is.na(s$meta$week_col))
})

test_that("big figures are abbreviated in the cell, exact in the tooltip", {
  weeks <- seq(as.Date("2026-04-06"), by = "week", length.out = 2)
  p <- media_plan_from_df(
    data.frame(week = weeks, channel = "TV", planned_spend = c(50000, 70000)),
    grain = c("channel", "week"), week = "week", name = "big")
  d <- opt(ec_ownership(p))$series[[1]]$data
  expect_identical(d[[1]][[5]], "50k")
  expect_identical(d[[1]][[6]], "50,000")
})

# ---- table --------------------------------------------------------------------

test_that("tbl_tree returns a reactable over the whole tree", {
  t <- tbl_tree(nested_plan())
  expect_s3_class(t, "reactable")
  expect_s3_class(t, "htmlwidget")
  expect_error(tbl_tree(42), "must be a MediaPlan")
})

test_that("tbl_tree accepts the projection and a theme", {
  expect_s3_class(tbl_tree(subplan_map(nested_plan())), "reactable")
  expect_s3_class(tbl_tree(nested_plan(), theme = "dark"), "reactable")
})

# ---- sunburst -----------------------------------------------------------------

test_that("ec_sunburst opens a backed cell into its subplan's line items", {
  o <- opt(ec_sunburst(nested_plan()))
  d <- o$series[[1]]$data
  nm <- vapply(d, function(n) n$name, character(1))
  expect_setequal(nm, c("TV", "Search", "Social"))
  tv <- d[[which(nm == "TV")]]
  expect_null(tv$value)                                  # summed from children
  kids <- vapply(tv$children, function(k) k$name, character(1))
  expect_setequal(kids, c("TV | NBC", "TV | ESPN"))
  # and one level deeper again
  nbc <- tv$children[[which(kids == "TV | NBC")]]
  expect_setequal(vapply(nbc$children, function(k) k$name, character(1)),
                  c("TV | NBC | prime", "TV | NBC | day"))
  search <- d[[which(nm == "Search")]]
  expect_equal(search$value, 40)                         # a leaf keeps its value
})

test_that("a sunburst branch keeps its owner colour all the way down", {
  th <- viz_theme("light")
  d  <- opt(ec_sunburst(nested_plan()))$series[[1]]$data
  nm <- vapply(d, function(n) n$name, character(1))
  tv <- d[[which(nm == "TV")]]
  expect_identical(tv$itemStyle$color, th$owner[1])
  expect_identical(tv$children[[1]]$itemStyle$color, th$owner[1])
})

test_that("an unbacked cell takes the topline neutral, never a default colour", {
  # An NA fill hands the wedge to ECharts' own palette, which would imply an
  # owner that does not exist.
  th <- viz_theme("light")
  d  <- opt(ec_sunburst(nested_plan()))$series[[1]]$data
  nm <- vapply(d, function(n) n$name, character(1))
  expect_identical(d[[which(nm == "Search")]]$itemStyle$color, th$topline)
  expect_identical(d[[which(nm == "Social")]]$itemStyle$color, th$topline)
  cols <- vapply(d, function(n) n$itemStyle$color %||% NA_character_,
                 character(1))
  expect_false(anyNA(cols))
})

test_that("every colour in every spec is one this package chose", {
  th <- viz_theme("light")
  mine <- c(th$accent, th$topline, th$owner, unname(th$status), th$ink,
            th$ink_2, th$ink_3, th$surface, th$rule, th$grid)
  for (s in list(ec_tree(nested_plan()), ec_sunburst(nested_plan()),
                 ec_ownership(nested_plan()), ec_rollup(nested_plan()),
                 ec_compare(chain_set()), ec_lineage(chain_set()))) {
    found <- unique(unlist(regmatches(
      as_json(s), gregexpr("#[0-9A-Fa-f]{6}", as_json(s)))))
    expect_true(all(found %in% mine),
                label = paste0("spec '", s$kind, "' uses ",
                               paste(setdiff(found, mine), collapse = ", ")))
  }
})

test_that("ec_sunburst needs the plan itself", {
  expect_error(ec_sunburst(subplan_map(nested_plan())), "must be a MediaPlan")
})

# ---- rollup -------------------------------------------------------------------

test_that("ec_rollup stacks the subplan's line items into the parent's number", {
  s <- ec_rollup(nested_plan(), "TV")
  expect_identical(s$meta$key, "TV")
  expect_identical(s$meta$categories,
                   c("TV | NBC", "TV | ESPN", "TV (topline)"))
  o <- opt(s)
  base <- unlist(o$series[[1]]$data)
  expect_equal(base, c(0, 75, 0))                  # each step starts where the
  tops <- vapply(o$series[[2]]$data, function(d) d$value, numeric(1))
  expect_equal(tops, c(75, 50, 125))               # last one ended
  expect_identical(o$series[[2]]$data[[3]]$label$formatter, "125")
  expect_match(o$series[[2]]$data[[3]]$tooltip$formatter, "the topline")
})

test_that("ec_rollup defaults to the only subplan and refuses a bad key", {
  p <- attach_subplan(flat_plan(), tv_sub())
  expect_identical(ec_rollup(p)$meta$key, "TV")
  expect_error(ec_rollup(p, "Search"), "Attached: TV")
  expect_error(ec_rollup(flat_plan()), "holds no subplans")
})

# ---- compare ------------------------------------------------------------------

test_that("ec_compare draws one line per line item across the scenarios", {
  s <- ec_compare(chain_set())
  expect_identical(s$meta$scenarios,
                   c("base", "Search up", "then TV", "Social up"))
  expect_setequal(s$meta$cells, c("TV", "Search", "Social"))
  o <- opt(s)
  expect_length(o$series, 3)
  se <- o$series[[which(vapply(o$series, function(x) x$name, character(1)) ==
                          "Search")]]
  expect_equal(unlist(se$data), c(40, 60, 60, 40))
  expect_identical(se$endLabel$formatter, "Search  40")
})

test_that("ec_compare aggregates a weekly set to line items", {
  top <- weekly_topline()
  s1  <- build_scenario(top, list(target = list(channel = "Search"),
                                  scale = 2), name = "search x2")
  set <- add_scenario(scenario_set(top, "base"), s1)
  s   <- ec_compare(set)
  expect_identical(s$meta$by, "channel")            # week dropped
  expect_setequal(s$meta$cells, c("TV", "Search"))
  o <- opt(s)
  se <- o$series[[which(vapply(o$series, function(x) x$name, character(1)) ==
                          "Search")]]
  expect_equal(unlist(se$data), c(60, 120))         # 3 weeks x 20, doubled
})

test_that("a locked cell reads flat across every scenario", {
  p   <- attach_subplan(flat_plan(), tv_sub())
  s1  <- build_scenario(p, c(Social = 90), name = "social up")
  set <- add_scenario(scenario_set(p, "base"), s1)
  o   <- opt(ec_compare(set))
  tv  <- o$series[[which(vapply(o$series, function(x) x$name, character(1)) ==
                           "TV")]]
  expect_equal(unlist(tv$data), c(120, 120))
})

test_that("ec_compare validates by and its input", {
  set <- chain_set()
  expect_error(ec_compare(set, by = "nope"), "not in the comparison")
  expect_error(ec_compare(42), "must be a ScenarioSet")
  expect_error(ec_compare(data.frame(a = 1)), "needs `scenario`")
})
