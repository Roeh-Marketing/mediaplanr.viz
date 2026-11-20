# The two charts that consume the structure projections directly: what hangs
# beneath a plan, and where a scenario came from. Both are ECharts `tree`
# series laid out left to right, because both are read as "this came from
# that" rather than as a hierarchy of size.
#
# Every label and tooltip is formatted HERE, in R, and travels as a literal
# string on the node. No JavaScript callbacks: a spec carrying function source
# is not JSON any more, and the whole argument for this package is that the
# spec is data -- readable by a frontend that has never run R, and by a model.

# Nest a pre-ordered depth listing into ECharts' children-of-children shape.
# subplan_map() guarantees pre-order, so a node's children are the immediately
# following rows one level deeper, and its subtree ends at the first row that
# is not deeper at all.
.nest_preorder <- function(m, i, make_node) {
  node <- make_node(i)
  kids <- list()
  j <- i + 1L
  while (j <= nrow(m) && m$depth[j] > m$depth[i]) {
    if (m$depth[j] == m$depth[i] + 1L) {
      res  <- .nest_preorder(m, j, make_node)
      kids <- c(kids, list(res$node))
      j    <- res$next_i
    } else {
      j <- j + 1L  # not reachable for well-formed input; skip rather than hang
    }
  }
  if (length(kids)) node$children <- kids
  list(node = node, next_i = j)
}

# A two-line rich label: the name, then a quieter figure under it. Rich text
# is "{style|content}" and content runs to the first "}", so a key containing
# a pipe -- "TV | NBC" -- passes through intact.
.rich_label <- function(name, figure) {
  paste0("{k|", name, "}\n{v|", figure, "}")
}

.rich_styles <- function(th) {
  list(
    k = list(fontFamily = .font_mono, fontSize = 12.5, color = th$ink,
             lineHeight = 17),
    v = list(fontFamily = .font_mono, fontSize = 11, color = th$ink_3)
  )
}

# A tree series, sized so its labels clear the plot on both sides. ECharts
# measures nothing for us, so the margins are computed from the label text.
.tree_series <- function(data, left_labels, right_labels, th,
                         symbol_size = 14) {
  label <- list(
    position = "left", verticalAlign = "middle", align = "right",
    rich = .rich_styles(th)
  )
  list(
    type = "tree", data = data, orient = "LR",
    top = "12%", bottom = "12%",
    left  = 16 + .label_px(left_labels),
    right = 24 + .label_px(right_labels),
    symbolSize = symbol_size,
    initialTreeDepth = -1,
    expandAndCollapse = TRUE,
    lineStyle = list(color = th$rule, width = 1.5, curveness = 0.5),
    label  = label,
    leaves = list(label = utils::modifyList(
      label, list(position = "right", align = "left")))
  )
}

#' Chart the subplan tree
#'
#' A left-to-right tree of the plans nested inside one plan: each node is a
#' plan, each edge the cell it backs. The root is the topline; a leaf is a
#' plan nobody has attached anything beneath.
#'
#' Nodes are coloured by **owner** — the depth-1 branch each belongs to — not
#' by status, so one subplan keeps one colour across [ec_tree()],
#' [ec_ownership()] and [ec_sunburst()], and the three read as one system.
#' Status appears in the tooltip. [ec_lineage()] is the chart that colours by
#' status, since scenarios have no owner.
#'
#' @param x A `MediaPlan`, or the data frame [mediaplanr::subplan_map()]
#'   returns.
#' @param theme A [viz_theme()] name or override list.
#' @return A [new_spec()] of kind `"tree"`. Its `meta` carries `ids` — the
#'   plan id of each node in pre-order — so an app can wire a click back to a
#'   plan, and `owners`, the colour assigned to each subplan key.
#' @examples
#' topline <- mediaplanr::media_plan_from_df(
#'   data.frame(week = as.Date("2026-07-06"), channel = c("TV", "Search"),
#'              planned_spend = c(100, 40)),
#'   grain = "channel", time = "week", name = "Q3 topline"
#' )
#' tv <- mediaplanr::media_plan_from_df(
#'   data.frame(week = as.Date("2026-07-06"), channel = "TV",
#'              partner = c("NBC", "ESPN"),
#'              planned_spend = c(70, 50)),
#'   grain = c("channel", "partner"), time = "week", name = "TV detail"
#' )
#' ec_tree(mediaplanr::attach_subplan(topline, tv))
#' @seealso [ec_lineage()], [tbl_tree()], [mediaplanr::subplan_map()]
#' @export
ec_tree <- function(x, theme = "light") {
  m  <- .as_projection(x, "MediaPlan", "subplan_map()", mediaplanr::subplan_map)
  th <- viz_theme(theme)
  if (!nrow(m)) stop("`x` has no rows to chart.", call. = FALSE)

  # Owner colours, assigned to the depth-1 branches in attach order. Deeper
  # nodes inherit from the branch they sit under, which in pre-order is the
  # nearest depth-1 row above them.
  branches <- m$key[m$depth == 1L]
  cols     <- .owner_colours(branches, th)
  owner_of <- rep(NA_character_, nrow(m))
  for (i in seq_len(nrow(m))) {
    owner_of[i] <- if (m$depth[i] == 0L) {
      NA_character_
    } else if (m$depth[i] == 1L) {
      m$key[i]
    } else {
      owner_of[max(which(m$depth[seq_len(i - 1L)] == 1L))]
    }
  }
  node_col <- ifelse(is.na(owner_of), th$accent, unname(cols[owner_of]))

  make_node <- function(i) {
    nm <- if (is.na(m$key[i])) m$name[i] else m$key[i]
    approval <- .approval_note(m$approved_on[i])
    list(
      name  = nm,
      value = m$spend[i],
      id    = m$id[i],
      itemStyle = list(color = node_col[i], borderColor = th$surface,
                       borderWidth = 2),
      label = list(formatter = .rich_label(nm, .fmt(m$spend[i]))),
      tooltip = list(formatter = paste0(
        "<b>", m$name[i], "</b><br><span style='font-family:", .font_mono,
        ";font-size:12px'>", m$grain[i], "<br>", m$cadence[i], " &middot; ",
        m$line_items[i], " line items<br>",
        if (nzchar(m$status[i])) m$status[i] else "&mdash;",
        if (nzchar(approval)) paste0(" &middot; ", approval),
        "<br>spend ", .fmt(m$spend[i]),
        "</span>"))
    )
  }
  root <- .nest_preorder(m, 1L, make_node)$node

  # The root's label sits left of its node; every other node's sits right.
  left  <- .rich_label(m$name[1], .fmt(m$spend[1]))
  right <- paste0(m$key[-1], "  ", .fmt(m$spend[-1]))

  option <- .option(th, series = list(.tree_series(list(root), left, right, th)))
  new_spec(option, kind = "tree", source = "subplan_map()",
           meta = list(ids = m$id, keys = m$key, owners = as.list(cols)))
}

#' Chart a scenario set's lineage
#'
#' A left-to-right derivation tree: each scenario sits beside the plan it was
#' actually derived from, with the spend change on the way there. A set whose
#' scenarios all came from the base is one fan; a chain — base, a scenario
#' from it, a scenario from *that* — reads as a chain, which is the thing
#' [mediaplanr::compare_scenarios()] cannot show, since it measures everything
#' against the baseline.
#'
#' Nodes are coloured by workflow **status**, and the baseline is ringed.
#' An approved scenario with no approved descendant -- the current approved
#' plan on its branch, as [mediaplanr::lineage()] marks it -- is drawn as a
#' diamond, and an approved scenario's tooltip gives its revision and approval
#' date, both derived by `lineage()`.
#' Scenarios whose parent is not in the set are roots, so a set of
#' independently authored plans draws as a forest rather than a lie.
#'
#' @param x A `ScenarioSet`, or the data frame [mediaplanr::lineage()]
#'   returns.
#' @param base_name Name of the baseline scenario, which is ringed. Taken from
#'   the set automatically; supply it when passing a data frame.
#' @param theme A [viz_theme()] name or override list.
#' @return A [new_spec()] of kind `"lineage"`. Its `meta` carries `ids` and
#'   `scenarios` in row order, and `current`: the scenarios that are the
#'   current approved plan on their branch.
#' @examples
#' base <- mediaplanr::media_plan_from_df(
#'   data.frame(week = as.Date("2026-07-06"), channel = c("TV", "Search"),
#'              planned_spend = c(80, 40)),
#'   grain = "channel", time = "week", name = "base"
#' )
#' s1  <- mediaplanr::build_scenario(
#'   base, list(target = list(channel = "Search"), total = 60), name = "Search up")
#' set <- mediaplanr::add_scenario(mediaplanr::scenario_set(base), s1)
#' ec_lineage(set)
#' @seealso [ec_tree()], [ec_compare()], [mediaplanr::lineage()]
#' @export
ec_lineage <- function(x, base_name = NULL, theme = "light") {
  if (inherits(x, "mediaplanr::ScenarioSet") && is.null(base_name)) {
    base_name <- x@base_name
  }
  l  <- .as_projection(x, "ScenarioSet", "lineage()", mediaplanr::lineage)
  th <- viz_theme(theme)
  if (!nrow(l)) stop("`x` has no scenarios to chart.", call. = FALSE)

  # "2,405,000  +90,000 (+4%)" -- spend, then what it cost to get here.
  figure <- .fmt(l$spend)
  has_d  <- !is.na(l$spend_vs_parent)
  figure[has_d] <- paste0(figure[has_d], "  ",
                          .fmt_delta(l$spend_vs_parent[has_d]))
  has_p <- has_d & !is.na(l$spend_pct_vs_parent)
  figure[has_p] <- paste0(figure[has_p], " (",
                          .pct(l$spend_pct_vs_parent[has_p]), ")")

  # The current approved plan -- the one the set is buying against -- is the
  # node a planner looks for first, so it is drawn as a diamond. A shape, not
  # a colour: colour already means status, and it is "approved" either way.
  current <- l$scenario[l$current %in% TRUE]

  node <- function(nm, seen = character(0)) {
    i <- which(l$scenario == nm)[1]
    approval <- .approval_note(l$approved_on[i], l$revision[i])
    out <- list(
      name = nm, value = l$spend[i], id = l$id[i],
      itemStyle = list(
        color = .status_colour(l$status[i], th), borderWidth = 2,
        borderColor = if (identical(nm, base_name)) th$ink else th$surface),
      label = list(formatter = .rich_label(nm, figure[i])),
      tooltip = list(formatter = paste0(
        "<b>", nm, "</b><br><span style='font-family:", .font_mono,
        ";font-size:12px'>",
        if (nzchar(l$status[i])) l$status[i] else "&mdash;",
        if (nzchar(approval)) paste0(" &middot; ", approval),
        if (nm %in% current) " &middot; current",
        "<br>spend ", .fmt(l$spend[i]),
        if (has_d[i]) paste0("<br>vs ", l$parent[i], " ",
                             .fmt_delta(l$spend_vs_parent[i])) else "",
        "</span>"))
    )
    # Set only when it applies: a NULL left in the list would serialise as {}.
    if (nm %in% current) out$symbol <- "diamond"
    # `seen` guards against a malformed parent cycle rather than recursing
    # until the stack goes.
    kids <- setdiff(l$scenario[!is.na(l$parent) & l$parent == nm], c(seen, nm))
    if (length(kids)) out$children <- lapply(kids, node, seen = c(seen, nm))
    out
  }
  roots <- l$scenario[is.na(l$parent)]
  data  <- lapply(roots, node)

  is_root <- l$scenario %in% roots
  series <- .tree_series(
    data,
    left_labels  = .rich_label(roots, figure[is_root]),
    right_labels = paste0(l$scenario, "  ", figure),
    th, symbol_size = 16)
  # A root with children has its label above the node, so the first edge does
  # not run through the text.
  series$label$position <- "top"
  series$label$align    <- "center"

  option <- .option(th, series = list(series))
  new_spec(option, kind = "lineage", source = "lineage()",
           meta = list(ids = l$id, scenarios = l$scenario,
                       base_name = base_name %||% NA_character_,
                       current = current))
}
