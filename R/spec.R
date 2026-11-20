# The unit of output is a SPEC, not a widget and not a plot object.
#
# A spec is a plain nested list that serializes to an Apache ECharts `option`.
# That is what makes this package web-first: the same list renders in Shiny
# through echarts4r, can be returned from a tool call and drawn by a frontend
# that has never heard of R, sits next to plan_to_json() output in a file, and
# can be read -- and edited -- by anything that speaks JSON.
#
# Widgets are a thin conversion over the spec (as_widget()), never the product.

#' A chart specification
#'
#' The object every `ec_*()` function returns: a list holding an Apache
#' ECharts `option`, plus the kind of chart it is and the `mediaplanr`
#' projection it was built from. Print it for a summary, [as_json()] it for a
#' frontend, [as_widget()] it for Shiny or a notebook.
#'
#' @param option The ECharts option, as a named list.
#' @param kind Short name of the chart kind, e.g. `"tree"`.
#' @param source The projection it was built from, e.g. `"subplan_map()"`.
#' @param meta Optional named list of extra facts a caller may want — node
#'   ids, category order — carried alongside rather than inside the option.
#' @return An object of class `mediaplanr_spec`.
#' @examples
#' new_spec(list(series = list()), kind = "tree", source = "subplan_map()")
#' @export
new_spec <- function(option, kind, source, meta = list()) {
  stopifnot(is.list(option), is.character(kind), is.character(source))
  structure(list(option = option, kind = kind, source = source, meta = meta),
            class = "mediaplanr_spec")
}

#' @export
print.mediaplanr_spec <- function(x, ...) {
  n <- length(x$option$series %||% list())
  cat("<mediaplanr_spec> ", x$kind, "\n", sep = "")
  cat("  from    ", x$source, "\n", sep = "")
  cat("  series  ", n, "\n", sep = "")
  cat("  size    ", format(nchar(as_json(x)), big.mark = ","), " bytes of JSON\n",
      sep = "")
  if (length(x$meta)) {
    cat("  meta    ", paste(names(x$meta), collapse = ", "), "\n", sep = "")
  }
  cat("\n  as_widget() to draw it, as_json() to send it\n")
  invisible(x)
}

#' Convert a spec to JSON or to a widget
#'
#' Two ways out of a [new_spec()]. `as_json()` gives the ECharts option as a
#' JSON string — hand it to a frontend, a tool call, or a file, and pass it
#' straight to `echarts.setOption()`. `as_widget()` wraps it in an
#' `echarts4r` htmlwidget for Shiny, R Markdown and Quarto.
#'
#' @param x A `mediaplanr_spec`.
#' @param pretty Whether to indent the JSON. Default `FALSE`, since the usual
#'   destination is a machine.
#' @param height,width Widget dimensions, passed to `echarts4r::e_charts()`.
#'   `NULL` fills the container.
#' @param ... Unused.
#' @return `as_json()` a JSON string; `as_widget()` an `echarts4r` htmlwidget.
#' @examples
#' p <- mediaplanr::media_plan_from_df(
#'   data.frame(week = as.Date("2026-07-06"), channel = c("TV", "Search"),
#'              planned_spend = c(80, 40)),
#'   grain = "channel", time = "week", name = "Q3"
#' )
#' substr(as_json(ec_tree(p)), 1, 60)
#' @export
as_json <- function(x, pretty = FALSE, ...) {
  if (!inherits(x, "mediaplanr_spec")) {
    stop("`x` must be a mediaplanr_spec.", call. = FALSE)
  }
  # digits = NA keeps full double precision: a spend figure must not be
  # rounded on its way to a chart.
  as.character(jsonlite::toJSON(x$option, auto_unbox = TRUE, null = "null",
                                na = "null", digits = NA, pretty = pretty))
}

#' @rdname as_json
#' @export
as_widget <- function(x, height = NULL, width = NULL, ...) {
  if (!inherits(x, "mediaplanr_spec")) {
    stop("`x` must be a mediaplanr_spec.", call. = FALSE)
  }
  # e_charts() wants data; the spec IS the chart, so an empty frame plus
  # e_list() of the option is the honest path.
  w <- echarts4r::e_charts(data.frame(), height = height, width = width)
  echarts4r::e_list(w, x$option, append = FALSE)
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# Format a spend figure for a label. Thousands separated, no decimals: plans
# are read in whole currency units.
.fmt <- function(x) formatC(x, format = "f", big.mark = ",", digits = 0)

# A signed delta, e.g. "+90,000" / "-144,000".
.fmt_delta <- function(x) {
  ifelse(is.na(x), NA_character_,
         paste0(ifelse(x > 0, "+", ifelse(x < 0, "-", "")), .fmt(abs(x))))
}

# A whole-number percent, rounded half AWAY FROM ZERO -- 12.5% reads as 13%,
# the convention every planner's spreadsheet uses. R's round() is half-to-even
# and would say 12%, which invites the question "twelve point what?".
.pct <- function(x) {
  p <- abs(x) * 100
  paste0(ifelse(x >= 0, "+", "-"), floor(p + 0.5), "%")
}

# What a plan's approval says, e.g. "Rev 2 · 2026-11-12", or "" when there is
# nothing to say. mediaplanr (>= 0.2.0) stores no revision on a plan: a
# revision is a plan's place among the approved plans on its branch, so only
# lineage() can derive it. A plan on its own (subplan_map()) carries just the
# date it was approved, and an unapproved plan has neither.
.approval_note <- function(approved_on, revision = NA_integer_,
                           sep = " &middot; ") {
  parts <- c(if (!is.na(revision)) paste0("Rev ", revision),
             if (!is.na(approved_on)) format(approved_on))
  paste(parts, collapse = sep)
}

# Every ec_* takes either the mediaplanr object or the projection it draws
# from -- so a caller who has already joined model output onto a projection
# can still draw it. S7 classes carry their qualified name in class(), so this
# needs no S7 dependency.
.as_projection <- function(x, class, projection, fn) {
  if (is.data.frame(x)) return(x)
  if (inherits(x, paste0("mediaplanr::", class))) return(fn(x))
  stop("`x` must be a ", class, " or the data frame `", projection,
       "` returns.", call. = FALSE)
}
