# The palette's job is to keep three roles apart -- accent, owner, status --
# and to exist in both a light and a dark variant, because a Shiny app
# toggles and a spec has to survive the toggle.

test_that("both palettes are complete and different", {
  l <- viz_theme("light")
  d <- viz_theme("dark")
  expect_setequal(names(l), names(d))
  expect_true(all(c("ink", "surface", "rule", "grid", "accent", "owner",
                    "topline", "status") %in% names(l)))
  expect_false(identical(l$accent, d$accent))
  expect_false(identical(l$ink, d$ink))
  expect_gte(length(l$owner), 4)
})

test_that("status covers mediaplanr's vocabulary plus unset", {
  for (th in list(viz_theme("light"), viz_theme("dark"))) {
    expect_true(all(status_levels() %in% names(th$status)))
    expect_true("" %in% names(th$status))
    expect_identical(.status_colour("approved", th), unname(th$status[["approved"]]))
    # an unknown status falls back to the unset colour rather than NA
    expect_identical(.status_colour("nonsense", th), .status_unset(th))
    expect_identical(.status_colour("", th), .status_unset(th))
    expect_false(is.na(.status_unset(th)))
  }
})

test_that("a list overrides one entry and keeps the rest", {
  t1 <- viz_theme(list(accent = "#B0004F"))
  expect_identical(t1$accent, "#B0004F")
  expect_identical(t1$ink, viz_theme("light")$ink)

  t2 <- viz_theme(list(base = "dark", accent = "#B0004F"))
  expect_identical(t2$accent, "#B0004F")
  expect_identical(t2$ink, viz_theme("dark")$ink)
})

test_that("a bad theme is refused by name", {
  expect_error(viz_theme("neon"), "should be one of")
  expect_error(viz_theme(list(base = "neon")), 'must be "light" or "dark"')
  expect_error(viz_theme(list(accnt = "#000")), "unknown theme entr")
  expect_error(viz_theme(42), "must be")
})

test_that("owner colours are stable per key and recycle past the ramp", {
  th <- viz_theme("light")
  c1 <- .owner_colours(c("TV", "Search"), th)
  expect_named(c1, c("TV", "Search"))
  expect_identical(unname(c1[["TV"]]), th$owner[1])
  many <- .owner_colours(paste0("k", 1:9), th)
  expect_length(many, 9)
  expect_identical(unname(many[[1]]), unname(many[[length(th$owner) + 1]]))
  expect_length(.owner_colours(character(0), th), 0)
})

test_that("a theme reaches the option it builds", {
  p <- nested_plan()
  expect_match(as_json(ec_tree(p, theme = "dark")),
               viz_theme("dark")$accent, fixed = TRUE)
  expect_match(as_json(ec_tree(p, theme = list(accent = "#B0004F"))),
               "#B0004F", fixed = TRUE)
})
