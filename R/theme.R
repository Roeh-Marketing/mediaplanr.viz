# Colour and type, brand-neutral by default.
#
# Three separate roles, never mixed: an ACCENT for the plan's own marks, an
# OWNER ramp for subplan keys (categorical -- who owns this cell), and STATUS
# colours for the workflow vocabulary mediaplanr already fixes
# (status_levels()). Keeping them apart is what stops "approved" and "TV"
# from accidentally being the same green.
#
# Every palette exists in a light and a dark variant, because a Shiny app
# toggles and a spec must survive the toggle.

.palettes <- list(
  light = list(
    ink     = "#18212B", ink_2 = "#4A5563", ink_3 = "#7C8794",
    surface = "#FFFFFF", rule  = "#D5DBE2", grid  = "#E1E6EB",
    accent  = "#0F7B85",
    owner   = c("#0F7B85", "#C4741C", "#4C6FA5", "#8A6BA8", "#2E8B57", "#B2564B"),
    topline = "#8B95A5",
    # Named with setNames because "" is not a legal name literal in c().
    status  = stats::setNames(c("#7C8794", "#C4741C", "#2E8B57", "#B4BCC6"),
                              c("in development", "to review", "approved", ""))
  ),
  dark = list(
    ink     = "#E4E9EE", ink_2 = "#AEB7C2", ink_3 = "#7C8794",
    surface = "#1B232D", rule  = "#2E3946", grid  = "#2A3441",
    accent  = "#3FB4BE",
    owner   = c("#3FB4BE", "#E0924A", "#7C9BD1", "#B192D0", "#4FBF7A", "#DE7C6F"),
    topline = "#6F7A8A",
    status  = stats::setNames(c("#8B95A5", "#E0924A", "#4FBF7A", "#5C6673"),
                              c("in development", "to review", "approved", ""))
  )
)

#' The colours a spec is built with
#'
#' Every `ec_*()` function takes a `theme`. Pass `"light"` (default) or
#' `"dark"` for the built-in palettes, or a named list overriding any of their
#' entries — `mediaplanr.viz` ships no client's colours, so a brand palette is
#' supplied here rather than patched into the option afterwards.
#'
#' Three roles are kept deliberately separate. `accent` is the plan's own
#' colour. `owner` is a categorical ramp assigned to subplan keys in the order
#' they are attached, so the same subplan is the same colour in every chart of
#' one plan. `status` maps [mediaplanr::status_levels()] — plus `""` for
#' unset — to semantic colours, and is never reused for anything else.
#'
#' @param theme `"light"`, `"dark"`, or a named list of overrides. A list may
#'   set `base` to say which palette it starts from; without it, light.
#' @return A named list: `ink`, `ink_2`, `ink_3`, `surface`, `rule`, `grid`,
#'   `accent`, `owner` (a character vector), `topline`, and `status` (a named
#'   character vector).
#' @examples
#' viz_theme("dark")$accent
#' viz_theme(list(accent = "#B0004F"))$accent
#' @export
viz_theme <- function(theme = "light") {
  if (is.character(theme)) {
    theme <- match.arg(theme, names(.palettes))
    return(.palettes[[theme]])
  }
  if (!is.list(theme)) {
    stop('`theme` must be "light", "dark", or a named list of overrides.',
         call. = FALSE)
  }
  base <- .palettes[[theme$base %||% "light"]]
  if (is.null(base)) {
    stop('`theme$base` must be "light" or "dark".', call. = FALSE)
  }
  theme$base <- NULL
  unknown <- setdiff(names(theme), names(base))
  if (length(unknown)) {
    stop("unknown theme entr(ies): ", paste(unknown, collapse = ", "),
         ". Known: ", paste(names(base), collapse = ", "), ".", call. = FALSE)
  }
  utils::modifyList(base, theme)
}

# The colour for each subplan key, assigned in attach order and recycled. The
# topline itself is not an owner -- it gets the neutral.
.owner_colours <- function(keys, th) {
  if (!length(keys)) return(stats::setNames(character(0), character(0)))
  stats::setNames(rep(th$owner, length.out = length(keys)), keys)
}

# An unrecognised status falls back to the unset colour rather than NA, so a
# plan carrying a status this palette has not been told about still draws.
# Looked up by position: `x[[""]]` is an error on a named vector, not a miss.
.status_colour <- function(status, th) {
  i <- match(status, names(th$status))
  i[is.na(i)] <- match("", names(th$status))
  unname(th$status[i])
}

# The colour for "no status set", by the same positional route.
.status_unset <- function(th) unname(th$status[match("", names(th$status))])

# Monospace for anything a reader compares digit by digit -- keys, spend,
# dates -- and the sans for prose. Matches mediaplanr's console output, where
# the same tables are read.
.font_mono <- "IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
.font_sans <- "IBM Plex Sans, system-ui, -apple-system, Segoe UI, sans-serif"

# Shared option scaffolding: text style and a tooltip that matches the theme.
.base_option <- function(th) {
  list(
    textStyle = list(fontFamily = .font_sans, color = th$ink),
    tooltip = list(
      backgroundColor = th$surface, borderColor = th$rule,
      textStyle = list(color = th$ink, fontFamily = .font_sans, fontSize = 13)
    )
  )
}

# Build an option: the theme's scaffolding, with `...` merged over it.
#
# MERGED, not concatenated. c() keeps both entries when a name repeats, and a
# list carrying two `tooltip`s serializes to a key called "tooltip.1" -- which
# ECharts rejects as an unknown component, taking the whole chart down. So
# every builder composes its option through here, and a builder that wants to
# adjust the tooltip passes just the keys it is changing.
.option <- function(th, ...) {
  utils::modifyList(.base_option(th), list(...))
}

# ECharts measures nothing for us: a tree's left and right margins have to
# clear the labels, and only R knows how long they are. Roughly 7.2px per
# monospace character at 12px.
.label_px <- function(text, size = 12) {
  if (!length(text)) return(0)
  max(nchar(text), na.rm = TRUE) * size * 0.6
}
