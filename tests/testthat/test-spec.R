# The spec is the product, so the contract worth pinning is about the spec
# itself: it is a list, it round-trips through JSON unchanged, it carries no
# JavaScript, and it converts to a widget.

test_that("new_spec holds an option, a kind and a source", {
  s <- new_spec(list(series = list()), kind = "tree", source = "subplan_map()")
  expect_s3_class(s, "mediaplanr_spec")
  expect_identical(s$kind, "tree")
  expect_identical(s$source, "subplan_map()")
  expect_identical(s$meta, list())
  expect_error(new_spec("not a list", "k", "s"))
})

test_that("printing a spec says what it is, not what it contains", {
  out <- paste(capture.output(print(ec_tree(nested_plan()))), collapse = "\n")
  expect_match(out, "<mediaplanr_spec> tree")
  expect_match(out, "from    subplan_map\\(\\)")
  expect_match(out, "series  1")
  expect_match(out, "bytes of JSON")
  # the option itself is not dumped
  expect_false(grepl("itemStyle", out))
})

test_that("as_json emits parseable JSON and keeps full precision", {
  p <- media_plan_from_df(
    data.frame(channel = "TV", planned_spend = 1234567.89),
    grain = "channel", name = "precise")
  j <- as_json(ec_tree(p))
  expect_type(j, "character")
  expect_no_error(jsonlite::fromJSON(j))
  expect_match(j, "1234567.89", fixed = TRUE)
  expect_match(as_json(ec_tree(p), pretty = TRUE), "\n")
  expect_error(as_json(list()), "must be a mediaplanr_spec")
})

test_that("no spec carries a JavaScript callback", {
  # The whole argument for spec-first is that the option is data. A function
  # in it would make the JSON unusable to anything that will not eval().
  set <- chain_set()
  p   <- nested_plan()
  specs <- list(ec_tree(p), ec_lineage(set), ec_ownership(p),
                ec_sunburst(p), ec_rollup(p), ec_compare(set))
  for (s in specs) {
    j <- as_json(s)
    expect_false(grepl("function", j, fixed = TRUE),
                 label = paste0("spec '", s$kind, "' contains 'function'"))
  }
})

test_that("no option repeats a top-level key", {
  # c()-ing the theme scaffolding together with an override produced two
  # `tooltip` entries, which serialize to a key called "tooltip.1". ECharts
  # rejects that as an unknown component and the whole chart fails to draw --
  # silently, since setOption throws where nobody is looking.
  set <- chain_set()
  p   <- nested_plan()
  specs <- list(ec_tree(p), ec_lineage(set), ec_ownership(p),
                ec_sunburst(p), ec_rollup(p), ec_compare(set))
  for (s in specs) {
    expect_equal(anyDuplicated(names(s$option)), 0,
                 label = paste0("spec '", s$kind, "' duplicate top-level key"))
    expect_false(any(grepl("\\.[0-9]+$", names(opt(s)))),
                 label = paste0("spec '", s$kind, "' has a disambiguated key"))
  }
})

test_that("a builder's tooltip override keeps the theme's tooltip styling", {
  o <- opt(ec_compare(chain_set()))
  expect_identical(o$tooltip$trigger, "axis")
  expect_identical(o$tooltip$backgroundColor, viz_theme("light")$surface)
})

test_that("as_widget produces an echarts4r widget", {
  w <- as_widget(ec_tree(nested_plan()))
  expect_s3_class(w, "echarts4r")
  expect_s3_class(w, "htmlwidget")
  expect_error(as_widget(list()), "must be a mediaplanr_spec")
})

test_that("every builder accepts its projection as well as the object", {
  p   <- nested_plan()
  set <- chain_set()
  expect_identical(as_json(ec_tree(p)), as_json(ec_tree(subplan_map(p))))
  expect_identical(as_json(ec_ownership(p)),
                   as_json(ec_ownership(ownership_map(p))))
  expect_identical(as_json(ec_lineage(set)),
                   as_json(ec_lineage(lineage(set), base_name = "base")))
  expect_error(ec_tree(42), "must be a MediaPlan")
  expect_error(ec_lineage(42), "must be a ScenarioSet")
})
