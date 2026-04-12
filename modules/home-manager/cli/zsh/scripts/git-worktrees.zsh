# Git worktree helpers.
# Usage:
#   gwt <branch-name>
#   gwtd <branch-name>
#   gwtl

gwt() {
  if [[ -z "$1" ]]; then
    echo "Usage: gwt <branch-name>" >&2
    return 1
  fi

  local branch="$1"
  git worktree add "../${branch}" -b "${branch}" && \
    echo "Created worktree at ../${branch}" && \
    cd "../${branch}"
}

gwtd() {
  if [[ -z "$1" ]]; then
    echo "Usage: gwtd <branch-name>" >&2
    return 1
  fi

  local branch="$1"
  if gum confirm "Delete worktree ${branch}?"; then
    git worktree remove "../${branch}" && git branch -d "${branch}"
  else
    echo "Cancelled"
  fi
}

gwtl() {
  git worktree list
}
