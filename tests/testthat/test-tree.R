# ec_tree and ec_lineage are the two charts built straight from the structure
# projections. What matters: the nesting is faithful, one subplan keeps one
# colour, the labels carry formatted figures, and the margins clear them.

test_that("ec_tree nests the plan tree in pre-order", {
  o <- opt(ec_tree(nested_plan()))
  root <- o$series[[1]]$data[[1]]
  expect_identical(root$name, "Q3 topline")
  expect_length(root$children, 1)
  tv <- root$children[[1]]
  expect_identical(tv$name, "TV")
  expect_identical(tv$children[[1]]$name, "TV | NBC")
  expect_null(tv$children[[1]]$children)
  expect_equal(root$value, 205)   # TV 80 -> 125 through two attachments
  expect_equal(tv$value, 125)
})

test_that("a flat plan is a single node with no children", {
  o <- opt(ec_tree(flat_plan()))
  expect_length(o$series[[1]]$data, 1)
  expect_null(o$series[[1]]$data[[1]]$children)
  expect_identical(o$series[[1]]$data[[1]]$name, "base")
})

test_that("labels and tooltips carry formatted figures, not raw numbers", {
  o <- opt(ec_tree(nested_plan()))
  root <- o$series[[1]]$data[[1]]
  expect_identical(root$label$formatter, "{k|Q3 topline}\n{v|205}")
  expect_match(root$tooltip$formatter, "3 line items")
  tv <- root$children[[1]]
  expect_identical(tv$label$formatter, "{k|TV}\n{v|125}")
  expect_match(tv$tooltip$formatter, "<b>TV detail</b>")
  expect_match(tv$tooltip$formatter, "to review")
})

test_that("a plan tree shows approval dates and never a revision", {
  # A revision is derived from a set's lineage; a subplan tree is not a set,
  # so it has a date to show and nothing else.
  o <- opt(ec_tree(approved_topline()))
  root <- o$series[[1]]$data[[1]]
  expect_match(root$tooltip$formatter, "approved &middot; 2026-06-30<br>",
               fixed = TRUE)
  expect_no_match(root$tooltip$formatter, "Rev")
  # Approved with no date recorded: the status alone, no dangling separator.
  nbc <- opt(ec_tree(nested_plan()))$series[[1]]$data[[1]]$children[[1]]$children[[1]]
  expect_match(nbc$tooltip$formatter, "approved<br>", fixed = TRUE)
})

test_that("lineage gives an approved scenario its revision, date and currency", {
  spec <- ec_lineage(approved_chain_set())
  base <- opt(spec)$series[[1]]$data[[1]]
  kids <- vapply(base$children, function(k) k$name, character(1))
  up   <- base$children[[which(kids == "Search up")]]
  open <- base$children[[which(kids == "Social up")]]

  # base is Rev 1, but an approved scenario was derived from it since.
  expect_match(base$tooltip$formatter, "Rev 1 &middot; 2026-06-01<br>",
               fixed = TRUE)
  expect_null(base$symbol)
  # "Search up" is Rev 2 on its branch and nothing approved follows it.
  expect_match(up$tooltip$formatter,
               "Rev 2 &middot; 2026-06-15 &middot; current<br>", fixed = TRUE)
  expect_identical(up$symbol, "diamond")
  # Unapproved: no revision, no date, ordinary node.
  expect_no_match(open$tooltip$formatter, "Rev")
  expect_null(open$symbol)

  expect_identical(spec$meta$current, "Search up")
})

test_that("an unapproved set has no revisions and no current plan", {
  spec <- ec_lineage(chain_set())
  expect_no_match(as_json(spec), "Rev ")
  expect_no_match(as_json(spec), "diamond")
  expect_length(spec$meta$current, 0)
})

test_that("a key containing the separator survives the rich-text label", {
  # "{k|TV | NBC}" is legal rich text: content runs to the first "}".
  o <- opt(ec_tree(nested_plan()))
  nbc <- o$series[[1]]$data[[1]]$children[[1]]$children[[1]]
  expect_identical(nbc$label$formatter, "{k|TV | NBC}\n{v|75}")
})

test_that("a subplan and its descendants share one owner colour", {
  th <- viz_theme("light")
  o  <- opt(ec_tree(nested_plan()))
  root <- o$series[[1]]$data[[1]]
  tv   <- root$children[[1]]
  nbc  <- tv$children[[1]]
  expect_identical(root$itemStyle$color, th$accent)
  expect_identical(tv$itemStyle$color, th$owner[1])
  expect_identical(nbc$itemStyle$color, th$owner[1])   # inherits its branch
})

test_that("tree margins are sized to the labels", {
  s <- opt(ec_tree(nested_plan()))$series[[1]]
  expect_gt(s$left, 16)
  expect_gt(s$right, 24)
  # a longer plan name pushes the left margin out
  long <- opt(ec_tree(flat_plan(paste(rep("x", 40), collapse = ""))))
  expect_gt(long$series[[1]]$left, s$left)
})

test_that("ec_tree meta carries ids for wiring clicks", {
  p <- nested_plan()
  m <- ec_tree(p)$meta
  expect_identical(m$ids[1], p@id)
  expect_identical(m$keys[2], "TV")
  expect_named(m$owners, "TV")
})

# ---- lineage ------------------------------------------------------------------

test_that("ec_lineage builds the derivation forest, not a fan", {
  o <- opt(ec_lineage(chain_set()))
  expect_length(o$series[[1]]$data, 1)             # one root: base
  base <- o$series[[1]]$data[[1]]
  expect_identical(base$name, "base")
  kids <- vapply(base$children, function(k) k$name, character(1))
  expect_setequal(kids, c("Search up", "Social up"))
  up <- base$children[[which(kids == "Search up")]]
  expect_identical(up$children[[1]]$name, "then TV")   # the chain
})

test_that("lineage labels show spend and the delta against the real parent", {
  o <- opt(ec_lineage(chain_set()))
  base <- o$series[[1]]$data[[1]]
  expect_identical(base$label$formatter, "{k|base}\n{v|160}")   # root: no delta
  kids <- vapply(base$children, function(k) k$name, character(1))
  up <- base$children[[which(kids == "Search up")]]
  expect_match(up$label$formatter, "180  \\+20 \\(\\+13%\\)")
  # "then TV" is measured against "Search up" (180), not the baseline
  expect_match(up$children[[1]]$label$formatter, "170  -10 \\(-6%\\)")
})

test_that("the baseline is ringed and status drives node colour", {
  th <- viz_theme("light")
  o  <- opt(ec_lineage(chain_set()))
  base <- o$series[[1]]$data[[1]]
  expect_identical(base$itemStyle$borderColor, th$ink)
  kids <- vapply(base$children, function(k) k$name, character(1))
  other <- base$children[[which(kids == "Social up")]]
  expect_identical(other$itemStyle$borderColor, th$surface)
  chain <- base$children[[which(kids == "Search up")]]$children[[1]]
  expect_identical(chain$itemStyle$color, unname(th$status[["to review"]]))
})

test_that("scenarios with no parent in the set are separate roots", {
  b   <- flat_plan("base")
  s1  <- build_scenario(b, at_cell(Search = 60), name = "s1")
  set <- add_scenario(scenario_set(s1, "s1"), flat_plan("unrelated"))
  o   <- opt(ec_lineage(set))
  expect_length(o$series[[1]]$data, 2)
  expect_true(all(vapply(o$series[[1]]$data,
                         function(d) is.null(d$children), logical(1))))
})
