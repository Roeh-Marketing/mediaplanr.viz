# Who owns which cell, drawn as a grid.
#
# This is the picture behind the read-only rule: a cell backed by a subplan is
# somebody else's number, and an edit here will be refused. Colour carries the
# owner, so the locked region is a block a planner reads at a glance rather
# than a property they have to query cell by cell.

# ownership_map() returns the plan's line item columns, its week column when
# it has one, then a fixed tail. The week column is the Date among the
# columns that are not part of that tail.
.ownership_week_col <- function(o) {
  tail_cols <- c("key", "owner", "owner_name", "locked", "planned_spend")
  cand <- setdiff(names(o), tail_cols)
  wk <- cand[vapply(o[cand], function(v) inherits(v, "Date"), logical(1))]
  if (length(wk)) wk[1] else NA_character_
}

#' Chart which cells a subplan owns
#'
#' Line items down, periods across, each cell coloured by the plan that owns
#' its number: the topline's own cells in a neutral, each subplan's in its own
#' colour. Locked rows are grouped at the top, so the region a planner cannot
#' edit here reads as a block.
#'
#' Owner colours match [ec_tree()] and [ec_sunburst()] for the same plan.
#'
#' @param x A `MediaPlan`, or the data frame [mediaplanr::ownership_map()]
#'   returns.
#' @param theme A [viz_theme()] name or override list.
#' @return A [new_spec()] of kind `"ownership"`. Its `meta` carries `items`
#'   (the row order), `periods` (the column order) and `owners`.
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
#' ec_ownership(mediaplanr::attach_subplan(topline, tv))
#' @seealso [ec_tree()], [mediaplanr::ownership_map()]
#' @export
ec_ownership <- function(x, theme = "light") {
  o  <- .as_projection(x, "MediaPlan", "ownership_map()",
                       mediaplanr::ownership_map)
  th <- viz_theme(theme)
  if (!nrow(o)) stop("`x` has no cells to chart.", call. = FALSE)

  wk <- .ownership_week_col(o)
  periods <- if (is.na(wk)) "all" else format(sort(unique(o[[wk]])), "%b %d")
  p_idx   <- if (is.na(wk)) rep(1L, nrow(o)) else
    match(format(o[[wk]], "%b %d"), periods)

  # Locked rows first, grouped by owner in attach order; then the topline's.
  owned  <- unique(stats::na.omit(o$owner))
  free   <- setdiff(unique(o$key), owned)
  items  <- c(owned, sort(free))
  cols   <- .owner_colours(owned, th)
  owners <- c("topline", owned)
  o_idx  <- match(ifelse(is.na(o$owner), "topline", o$owner), owners)

  # Cell labels are short or the grid becomes unreadable; thousands only once
  # the figures are big enough that "0k" cannot happen.
  short <- if (max(o$planned_spend, na.rm = TRUE) >= 10000) {
    paste0(round(o$planned_spend / 1000), "k")
  } else {
    .fmt(o$planned_spend)
  }

  # Everything a label or tooltip needs travels with the cell, already
  # formatted, so the option needs no JavaScript to render.
  data <- lapply(seq_len(nrow(o)), function(i) {
    list(p_idx[i] - 1L, match(o$key[i], items) - 1L, o_idx[i] - 1L,
         o$planned_spend[i], short[i], .fmt(o$planned_spend[i]),
         if (is.na(o$owner[i])) "the topline" else o$owner_name[i],
         if (o$locked[i]) "locked" else "editable",
         o$key[i], periods[p_idx[i]])
  })

  option <- .option(
    th,
    grid = list(left = 24 + .label_px(items), right = 16, top = 12,
                bottom = 28 + if (is.na(wk)) 0 else 34),
    xAxis = list(
      type = "category", data = as.list(periods),
      axisLabel = list(fontFamily = .font_mono, fontSize = 11,
                       color = th$ink_2, interval = 0,
                       rotate = if (length(periods) > 6) 40 else 0),
      axisLine = list(lineStyle = list(color = th$rule)),
      axisTick = list(show = FALSE), splitArea = list(show = FALSE)),
    yAxis = list(
      type = "category", data = as.list(items), inverse = TRUE,
      axisLabel = list(fontFamily = .font_mono, fontSize = 12, color = th$ink),
      axisLine = list(show = FALSE), axisTick = list(show = FALSE)),
    visualMap = list(list(
      show = FALSE, type = "piecewise", dimension = 2,
      pieces = lapply(seq_along(owners), function(i) list(
        value = i - 1L,
        color = if (owners[i] == "topline") th$topline else unname(cols[owners[i]])))
    )),
    series = list(list(
      type = "heatmap", data = data,
      itemStyle = list(borderColor = th$surface, borderWidth = 2,
                       borderRadius = 2),
      label = list(show = TRUE, fontFamily = .font_mono, fontSize = 10,
                   color = "rgba(255,255,255,.92)", formatter = "{@[4]}"),
      emphasis = list(itemStyle = list(shadowBlur = 6,
                                       shadowColor = "rgba(0,0,0,.25)")))),
    tooltip = list(
      formatter = paste0("<b>{@[8]}</b> &middot; {@[9]}<br>",
                         "<span style='font-family:", .font_mono,
                         ";font-size:12px'>{@[5]}<br>owner: {@[6]} ({@[7]})",
                         "</span>"))
  )
  new_spec(option, kind = "ownership", source = "ownership_map()",
           meta = list(items = items, periods = periods, owners = owners,
                       week_col = wk))
}
