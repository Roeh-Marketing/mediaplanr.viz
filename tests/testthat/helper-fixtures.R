# One fixture family, shared by every test file. Deliberately small: the
# specs are checked for shape and content, and a six-week plan shows every
# structural case a sixty-week one would.

# mediaplanr is reached through its namespace rather than by attaching it:
# a helper's functions are called from the test environment, whose parent
# chain is this package's namespace, so `library()` here is not reliably in
# scope by the time a fixture actually runs.
mp <- asNamespace("mediaplanr")
media_plan_from_df    <- mp$media_plan_from_df
media_plan_from_flights <- mp$media_plan_from_flights
attach_subplan        <- mp$attach_subplan
build_scenario        <- mp$build_scenario
scenario_set          <- mp$scenario_set
add_scenario          <- mp$add_scenario
subplan_map           <- mp$subplan_map
ownership_map         <- mp$ownership_map
lineage               <- mp$lineage
status_levels         <- mp$status_levels

# Every plan is keyed by time, so the flat fixtures are single-week plans: one
# week keeps their totals simple and `line_item()` keys read "TV | 2026-07-06".
fix_week <- function() as.Date("2026-07-06")
cell <- function(...) paste(c(..., format(fix_week())), collapse = " | ")
at_cell <- function(...) {
  v <- c(...)
  stats::setNames(v, vapply(names(v), cell, character(1)))
}

# Single-week topline at channel grain; TV is 80 before any subplan.
flat_plan <- function(name = "base") {
  media_plan_from_df(
    data.frame(week = fix_week(), channel = c("TV", "Search", "Social"),
               planned_spend = c(80, 40, 40), stringsAsFactors = FALSE),
    grain = "channel", time = "week", name = name)
}

# TV detail at channel + partner; rolls up to 120.
tv_sub <- function(name = "TV detail") {
  media_plan_from_df(
    data.frame(week = fix_week(), channel = "TV", partner = c("NBC", "ESPN"),
               planned_spend = c(70, 50), stringsAsFactors = FALSE),
    grain = c("channel", "partner"), time = "week", name = name,
    status = "to review")
}

# NBC detail one level deeper; rolls up to 75.
nbc_sub <- function() {
  media_plan_from_df(
    data.frame(week = fix_week(), channel = "TV", partner = "NBC",
               daypart = c("prime", "day"),
               planned_spend = c(60, 15), stringsAsFactors = FALSE),
    grain = c("channel", "partner", "daypart"), time = "week",
    name = "NBC upfront", status = "approved")
}

# A two-level topline: base -> TV -> TV | NBC.
nested_plan <- function() {
  attach_subplan(flat_plan("Q3 topline"), attach_subplan(tv_sub(), nbc_sub()))
}

# A weekly topline with a weekly subplan, for the cadence-sensitive charts.
weekly_topline <- function() {
  weeks <- seq(as.Date("2026-04-06"), by = "week", length.out = 3)
  top <- media_plan_from_df(
    data.frame(week = rep(weeks, 2),
               channel = rep(c("TV", "Search"), each = 3),
               planned_spend = c(30, 30, 30, 20, 20, 20)),
    grain = "channel", time = "week", name = "weekly topline")
  sub <- media_plan_from_df(
    data.frame(week = rep(weeks, each = 2), channel = "TV",
               partner = rep(c("NBC", "ESPN"), 3),
               planned_spend = c(25, 15, 25, 15, 25, 15)),
    grain = c("channel", "partner"), time = "week", name = "TV weekly")
  attach_subplan(top, sub)
}

# A set with a chain (base -> up -> then) and a branch off the base.
chain_set <- function() {
  b  <- flat_plan("base")
  s1 <- build_scenario(b, at_cell(Search = 60), name = "Search up")
  s2 <- build_scenario(s1, at_cell(TV = 70), name = "then TV",
                       status = "to review")
  s3 <- build_scenario(b, at_cell(Social = 90), name = "Social up")
  add_scenario(add_scenario(add_scenario(scenario_set(b, "base"), s1), s2), s3)
}

# Approvals. mediaplanr records the date a plan was approved; its revision is
# derived from a set's lineage, so it only exists on a set.
revise <- mp$revise

# A topline approved on a known date, with an unapproved TV subplan.
approved_topline <- function() {
  top <- revise(flat_plan("Q3 topline"), status = "approved",
                approved_on = as.Date("2026-06-30"))
  attach_subplan(top, tv_sub())
}

# base (approved 1 Jun) -> "Search up" (approved 15 Jun), and an open
# "Social up" off the base. "Search up" is Rev 2 and current; base is Rev 1
# and no longer current, because an approved plan was derived from it.
approved_chain_set <- function() {
  b  <- revise(flat_plan("base"), status = "approved",
               approved_on = as.Date("2026-06-01"))
  s1 <- revise(build_scenario(b, at_cell(Search = 60), name = "Search up"),
               status = "approved", approved_on = as.Date("2026-06-15"))
  s2 <- build_scenario(b, at_cell(Social = 90), name = "Social up")
  add_scenario(add_scenario(scenario_set(b, "base"), s1), s2)
}

# The option a spec carries, parsed back from its JSON -- so tests assert on
# what a browser would actually receive, not on the R list.
opt <- function(spec) jsonlite::fromJSON(as_json(spec), simplifyVector = FALSE)
