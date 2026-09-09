# The one non-ECharts render, and often the most useful.
#
# A dendrogram is the obvious picture of a subplan tree, but a planner's
# actual question is a table's question: which plan owns what, how big is it,
# and can I still edit it here? So the tree table is first-class rather than a
# fallback -- indented by depth, with the spend bar and the lock marker doing
# the work the tree's geometry would.

#' A subplan tree as an interactive table
#'
#' Every plan in the tree as a row, indented by depth: what it backs, its
#' grain and cadence, how big it is, and whether its rows are locked on the
#' plan above. Sorting, and a detail panel per row, come from `reactable`.
#'
#' @param x A `MediaPlan`, or the data frame [mediaplanr::subplan_map()]
#'   returns.
#' @param theme A [viz_theme()] name or override list.
#' @param ... Passed to `reactable::reactable()`, so any of its options —
#'   `defaultSorted`, `height`, `striped` — reach through.
#' @return A `reactable` htmlwidget.
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
#' tbl_tree(mediaplanr::attach_subplan(topline, tv))
#' @seealso [ec_tree()], [mediaplanr::subplan_map()]
#' @export
tbl_tree <- function(x, theme = "light", ...) {
  m  <- .as_projection(x, "MediaPlan", "subplan_map()", mediaplanr::subplan_map)
  th <- viz_theme(theme)
  if (!nrow(m)) stop("`x` has no rows to tabulate.", call. = FALSE)

  branches <- m$key[m$depth == 1L]
  cols     <- .owner_colours(branches, th)
  max_sp   <- max(m$spend, na.rm = TRUE)

  span <- function(txt, ...) {
    style <- paste(paste0(names(list(...)), ":", unlist(list(...))),
                   collapse = ";")
    htmltools::tags$span(txt, style = style)
  }

  plan_cell <- function(value, index) {
    bar_w <- max(4, round(90 * m$spend[index] / max(max_sp, 1)))
    colour <- if (m$depth[index] == 0L) th$accent else {
      k <- if (m$depth[index] == 1L) m$key[index] else
        m$key[max(which(m$depth[seq_len(index)] == 1L))]
      unname(cols[k])
    }
    htmltools::div(
      style = paste0("padding-left:", m$depth[index] * 20, "px"),
      htmltools::div(style = paste0(
        "display:inline-block;height:8px;width:", bar_w,
        "px;border-radius:2px;vertical-align:middle;margin-right:8px;",
        "background:", colour)),
      span(value, "font-weight" = "500"),
      if (m$revision[index] > 1L) {
        span(paste0(" Rev ", m$revision[index]),
             "font-family" = .font_mono, "font-size" = "11px",
             "color" = th$ink_3, "margin-left" = "6px")
      }
    )
  }

  backs_cell <- function(value, index) {
    if (is.na(value)) {
      return(span("\u2014", "color" = th$ink_3))
    }
    htmltools::tagList(
      span(value, "font-family" = .font_mono),
      span("locked", "font-size" = "11px", "color" = th$ink_3,
           "margin-left" = "8px")
    )
  }

  status_cell <- function(value) {
    if (!nzchar(value)) return(span("\u2014", "color" = th$ink_3))
    span(value, "font-family" = .font_mono, "font-size" = "11px",
         "padding" = "2px 7px", "border-radius" = "3px",
         "border" = paste0("1px solid ", .status_colour(value, th)),
         "color" = .status_colour(value, th))
  }

  detail <- function(index) {
    htmltools::div(
      style = paste0("padding:12px 16px;font-family:", .font_mono,
                     ";font-size:12px;color:", th$ink_2),
      htmltools::div(paste0("plan id   ", m$id[index])),
      htmltools::div(paste0("path      ",
                            if (nzchar(m$path[index])) m$path[index] else
                              "(topline)")),
      htmltools::div(paste0("subplans  ", m$subplans[index])),
      htmltools::div(paste0("rows      ", m$rows[index]))
    )
  }

  reactable::reactable(
    m[, c("name", "key", "grain", "cadence", "line_items", "spend", "status")],
    columns = list(
      name       = reactable::colDef("plan", cell = plan_cell, minWidth = 200),
      key        = reactable::colDef("backs", cell = backs_cell, minWidth = 140),
      grain      = reactable::colDef("grain", minWidth = 160),
      cadence    = reactable::colDef("cadence", minWidth = 90),
      line_items = reactable::colDef("line items", align = "right",
                                     minWidth = 90),
      spend      = reactable::colDef(
        "spend", align = "right", minWidth = 110,
        cell = function(v) .fmt(v),
        style = list(fontFamily = .font_mono, fontVariantNumeric = "tabular-nums")),
      status     = reactable::colDef("status", cell = status_cell,
                                     minWidth = 130)
    ),
    details = detail,
    sortable = TRUE, defaultSorted = NULL, compact = TRUE,
    borderless = TRUE, highlight = TRUE,
    theme = reactable::reactableTheme(
      color = th$ink, backgroundColor = th$surface,
      borderColor = th$grid, stripedColor = th$grid,
      highlightColor = th$grid,
      headerStyle = list(
        fontFamily = .font_mono, fontSize = "11.5px", letterSpacing = ".06em",
        textTransform = "uppercase", color = th$ink_3, fontWeight = 500,
        borderBottom = paste0("1px solid ", th$rule))
    ),
    ...
  )
}
