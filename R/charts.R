# The three charts about money rather than structure: where the spend sits in
# the nesting, how one cell's number is arrived at, and how it moves across a
# set of scenarios.

#' Chart spend by nesting
#'
#' A sunburst, one ring per level: the plan's own line items in the inner
#' ring, and any cell backed by a subplan opening into that subplan's line
#' items further out. A cell nobody has attached anything beneath is a leaf.
#'
#' This is the shape of the plan's money, where [ec_tree()] is the shape of
#' its ownership. Branch colours match [ec_tree()] and [ec_ownership()].
#'
#' Unlike the other builders this one needs the `MediaPlan` itself — it walks
#' into the subplans to build each ring, which no single projection carries.
#'
#' @param x A `MediaPlan`.
#' @param theme A [viz_theme()] name or override list.
#' @return A [new_spec()] of kind `"sunburst"`.
#' @examples
#' topline <- mediaplanr::media_plan_from_df(
#'   data.frame(channel = c("TV", "Search"), planned_spend = c(100, 40)),
#'   grain = "channel", name = "Q3 topline"
#' )
#' tv <- mediaplanr::media_plan_from_df(
#'   data.frame(channel = "TV", partner = c("NBC", "ESPN"),
#'              planned_spend = c(70, 50)),
#'   grain = c("channel", "partner"), name = "TV detail"
#' )
#' ec_sunburst(mediaplanr::attach_subplan(topline, tv))
#' @seealso [ec_tree()], [ec_rollup()]
#' @export
ec_sunburst <- function(x, theme = "light") {
  if (!inherits(x, "mediaplanr::MediaPlan")) {
    stop("`x` must be a MediaPlan: a sunburst walks into the subplans, so ",
         "no single projection carries it.", call. = FALSE)
  }
  th   <- viz_theme(theme)
  cols <- .owner_colours(names(x@subplans), th)

  ring <- function(p, colour) {
    li <- setdiff(mediaplanr::line_item_grain(p), mediaplanr::flight_cols())
    d  <- p@data
    if (!length(li) || !nrow(d)) return(list())
    k <- mediaplanr::line_item(d, li)
    lapply(unique(k), function(key) {
      spend <- sum(d[["planned_spend"]][k == key])
      # A cell nobody has attached a subplan to belongs to the topline, so it
      # takes the neutral. Falling through to NA here would hand the wedge to
      # ECharts' own default palette -- colours this package never chose, and
      # which would say "different owner" where there is none.
      col <- colour %||% if (key %in% names(cols)) {
        unname(cols[key])
      } else {
        th$topline
      }
      node  <- list(name = key, value = spend,
                    itemStyle = list(color = col, borderColor = th$surface,
                                     borderWidth = 2),
                    tooltip = list(formatter = paste0(
                      "<b>", key, "</b><br><span style='font-family:",
                      .font_mono, ";font-size:12px'>", .fmt(spend),
                      "</span>")))
      if (key %in% names(p@subplans)) {
        node$children <- ring(p@subplans[[key]], col)
        node$value    <- NULL   # ECharts sums the children
      }
      node
    })
  }
  data <- ring(x, NULL)
  if (!length(data)) {
    stop("`x` has no line items to chart: its grain is only its time column.",
         call. = FALSE)
  }

  option <- .option(
    th,
    series = list(list(
      type = "sunburst", data = data, radius = c("15%", "90%"),
      label = list(rotate = "radial", fontFamily = .font_mono, fontSize = 11,
                   color = "rgba(255,255,255,.95)", minAngle = 8),
      emphasis = list(focus = "ancestor"), nodeClick = "rootToNode",
      levels = list(
        list(),
        list(r0 = "15%", r = "48%", label = list(rotate = 0, fontSize = 12.5)),
        list(r0 = "48%", r = "72%"),
        list(r0 = "72%", r = "90%", label = list(fontSize = 10)))
    ))
  )
  new_spec(option, kind = "sunburst", source = "the plan tree",
           meta = list(owners = as.list(cols)))
}

#' Chart how a backed cell adds up
#'
#' A waterfall for one cell of a topline: the subplan's line items stacking up
#' to the number the parent holds, with the parent's total as a final bar.
#' This is the reconciliation view — the picture behind *"channel TV is
#' planned in a subplan; edit the subplan and re-attach"*.
#'
#' @param x A `MediaPlan` holding at least one subplan.
#' @param key The cell to explain — a name from `names(x@subplans)`. Defaults
#'   to the first, so a plan with one subplan needs no argument.
#' @param theme A [viz_theme()] name or override list.
#' @return A [new_spec()] of kind `"rollup"`.
#' @examples
#' topline <- mediaplanr::media_plan_from_df(
#'   data.frame(channel = c("TV", "Search"), planned_spend = c(100, 40)),
#'   grain = "channel", name = "Q3 topline"
#' )
#' tv <- mediaplanr::media_plan_from_df(
#'   data.frame(channel = "TV", partner = c("NBC", "ESPN"),
#'              planned_spend = c(70, 50)),
#'   grain = c("channel", "partner"), name = "TV detail"
#' )
#' ec_rollup(mediaplanr::attach_subplan(topline, tv))
#' @seealso [ec_sunburst()], [mediaplanr::attach_subplan()]
#' @export
ec_rollup <- function(x, key = NULL, theme = "light") {
  if (!inherits(x, "mediaplanr::MediaPlan")) {
    stop("`x` must be a MediaPlan.", call. = FALSE)
  }
  have <- names(x@subplans)
  if (!length(have)) {
    stop("`x` holds no subplans, so no cell has a rollup to show. ",
         "attach_subplan() one first.", call. = FALSE)
  }
  key <- key %||% have[1]
  if (!is.character(key) || length(key) != 1L || !key %in% have) {
    stop("no subplan at that key. Attached: ", paste(have, collapse = ", "),
         ".", call. = FALSE)
  }
  th  <- viz_theme(theme)
  col <- unname(.owner_colours(have, th)[key])

  sub <- x@subplans[[key]]
  li  <- setdiff(mediaplanr::line_item_grain(sub), mediaplanr::flight_cols())
  r   <- mediaplanr::roll_up(sub, li)@data
  r   <- r[order(-r[["planned_spend"]]), , drop = FALSE]
  vals <- r[["planned_spend"]]

  # A waterfall is a stacked bar whose lower series is invisible: each step
  # starts where the last one ended, and the total starts at zero.
  base   <- c(cumsum(c(0, vals[-length(vals)])), 0)
  labels <- c(mediaplanr::line_item(r, li), paste0(key, " (topline)"))
  is_tot <- c(rep(FALSE, length(vals)), TRUE)
  tops   <- c(vals, sum(vals))

  option <- .option(
    th,
    grid = list(left = 76, right = 24, top = 28, bottom = 36),
    xAxis = list(
      type = "category", data = as.list(labels),
      axisLabel = list(fontFamily = .font_mono, fontSize = 12, color = th$ink,
                       interval = 0),
      axisLine = list(lineStyle = list(color = th$rule)),
      axisTick = list(show = FALSE)),
    yAxis = list(
      type = "value",
      axisLabel = list(fontFamily = .font_mono, fontSize = 11, color = th$ink_3),
      splitLine = list(lineStyle = list(color = th$grid)))
    ,
    series = list(
      list(type = "bar", stack = "w", barWidth = 44,
           itemStyle = list(color = "transparent"),
           emphasis = list(itemStyle = list(color = "transparent")),
           tooltip = list(show = FALSE),
           data = as.list(base)),
      # Each bar carries its own already-formatted label and tooltip, so the
      # option stays free of callbacks.
      list(type = "bar", stack = "w",
           data = lapply(seq_along(tops), function(i) list(
             value = tops[i],
             itemStyle = list(color = col, opacity = if (is_tot[i]) 1 else 0.75,
                              borderRadius = 2),
             label = list(formatter = .fmt(tops[i])),
             tooltip = list(formatter = paste0(
               "<b>", labels[i], "</b><br><span style='font-family:",
               .font_mono, ";font-size:12px'>", .fmt(tops[i]),
               if (is_tot[i]) " (the topline's number for this cell)" else "",
               "</span>")))),
           label = list(show = TRUE, position = "top", fontFamily = .font_mono,
                        fontSize = 11.5, color = th$ink_2))
    ),
    tooltip = list(trigger = "item")
  )
  new_spec(option, kind = "rollup", source = "roll_up(subplan)",
           meta = list(key = key, categories = labels))
}

#' Chart how spend moves across a set of scenarios
#'
#' A slope chart: one line per line item, one position per scenario. The
#' picture of [mediaplanr::compare_scenarios()] at cell level — a cut is a
#' line falling, an addition a line rising from zero, and a cell owned by a
#' subplan is flat by construction, because no scenario can edit it.
#'
#' @param x A `ScenarioSet`, or the data frame
#'   [mediaplanr::compare_scenarios()] returns at `level = "cell"`.
#' @param by Columns identifying a line to draw. Defaults to the set's line
#'   item grain — the grain without its week — so a weekly set draws one line
#'   per line item rather than one per cell-week. Required when `x` is a data
#'   frame with no obvious line item columns.
#' @param theme A [viz_theme()] name or override list.
#' @return A [new_spec()] of kind `"compare"`.
#' @examples
#' base <- mediaplanr::media_plan_from_df(
#'   data.frame(channel = c("TV", "Search"), planned_spend = c(80, 40)),
#'   grain = "channel", name = "base"
#' )
#' s1  <- mediaplanr::build_scenario(base, c(Search = 60), name = "Search up")
#' set <- mediaplanr::add_scenario(mediaplanr::scenario_set(base), s1)
#' ec_compare(set)
#' @seealso [ec_lineage()], [mediaplanr::compare_scenarios()]
#' @export
ec_compare <- function(x, by = NULL, theme = "light") {
  if (inherits(x, "mediaplanr::ScenarioSet")) {
    if (is.null(by)) {
      base <- x@scenarios[[x@base_name]]
      by <- setdiff(mediaplanr::line_item_grain(base), mediaplanr::flight_cols())
    }
    scen_order <- names(x@scenarios)
    cmp <- mediaplanr::compare_scenarios(x, "cell")
  } else if (is.data.frame(x)) {
    cmp <- x
    if (!"scenario" %in% names(cmp) || !"planned_spend" %in% names(cmp)) {
      stop("`x` must be the data frame compare_scenarios(set, \"cell\") ",
           "returns: it needs `scenario` and `planned_spend`.", call. = FALSE)
    }
    scen_order <- unique(cmp$scenario)
    if (is.null(by)) {
      by <- setdiff(names(cmp)[vapply(cmp, function(v) {
        is.character(v) || is.factor(v)
      }, logical(1))], "scenario")
    }
  } else {
    stop("`x` must be a ScenarioSet or the data frame ",
         "`compare_scenarios(set, \"cell\")` returns.", call. = FALSE)
  }
  miss <- setdiff(by, names(cmp))
  if (length(miss)) {
    stop("`by` names column(s) not in the comparison: ",
         paste(miss, collapse = ", "), ".", call. = FALSE)
  }
  if (!length(by)) {
    stop("nothing to group by: name the line item column(s) in `by`.",
         call. = FALSE)
  }
  th <- viz_theme(theme)

  cells <- mediaplanr::line_item(cmp, by)
  keys  <- unique(cells)
  cols  <- .owner_colours(keys, th)

  series <- lapply(keys, function(k) {
    vals <- vapply(scen_order, function(s) {
      sum(cmp[["planned_spend"]][cells == k & cmp$scenario == s])
    }, numeric(1))
    # endLabel draws once, at the series end, so its text can simply BE the
    # final figure rather than a template over it.
    list(name = k, type = "line", symbolSize = 7,
         data = as.list(unname(vals)),
         lineStyle = list(width = 2, color = unname(cols[k])),
         itemStyle = list(color = unname(cols[k]), borderColor = th$surface,
                          borderWidth = 1.5),
         emphasis = list(focus = "series"),
         endLabel = list(show = TRUE, fontFamily = .font_mono,
                         fontSize = 11.5, color = th$ink_2,
                         offset = list(8, 0),
                         formatter = paste0(k, "  ",
                                            .fmt(vals[length(vals)]))))
  })

  option <- .option(
    th,
    grid = list(left = 76, right = 40 + .label_px(keys) + 60, top = 28,
                bottom = 36),
    xAxis = list(
      type = "category", data = as.list(scen_order), boundaryGap = FALSE,
      axisLabel = list(fontFamily = .font_mono, fontSize = 12, color = th$ink),
      axisLine = list(lineStyle = list(color = th$rule)),
      axisTick = list(show = FALSE),
      splitLine = list(show = TRUE, lineStyle = list(color = th$grid,
                                                     type = "dashed"))),
    yAxis = list(
      type = "value",
      axisLabel = list(fontFamily = .font_mono, fontSize = 11, color = th$ink_3),
      splitLine = list(lineStyle = list(color = th$grid))),
    series = series,
    tooltip = list(trigger = "axis")
  )
  new_spec(option, kind = "compare", source = "compare_scenarios(set, \"cell\")",
           meta = list(scenarios = scen_order, cells = keys, by = by))
}
