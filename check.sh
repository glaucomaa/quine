#!/usr/bin/env bash
set -euo pipefail

if command -v tput >/dev/null 2>&1; then
  BOLD="$(tput bold 2>/dev/null || echo)"; DIM="$(tput dim 2>/dev/null || echo)"; RESET="$(tput sgr0 2>/dev/null || echo)"
  RED="$(tput setaf 1 2>/dev/null || echo)"; GREEN="$(tput setaf 2 2>/dev/null || echo)"; YELLOW="$(tput setaf 3 2>/dev/null || echo)"; BLUE="$(tput setaf 4 2>/dev/null || echo)"
else
  BOLD=""; DIM=""; RESET=""
  RED=""; GREEN=""; YELLOW=""; BLUE=""
fi

hr()  { printf "%s\n" "${DIM}------------------------------------------------------------${RESET}"; }
ok()  { printf "%s%s✔%s %s\n" "$GREEN" "$BOLD" "$RESET" "$*"; }
bad() { printf "%s%s✘%s %s\n" "$RED"   "$BOLD" "$RESET" "$*"; }
inf() { printf "%s%s•%s %s\n" "$BLUE"  "$BOLD" "$RESET" "$*"; }

_snapshot_cwd_files() {
  local out="$1"
  for f in ./*; do
    [[ -f "$f" ]] && printf '%s\n' "${f#./}"
  done | LC_ALL=C sort -u >"$out"
}

_cleanup_new_files_from_lists() {
  local before_list="$1" after_list="$2" keep_regex="${3:-^$}"

  comm -13 "$before_list" "$after_list" | while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ "$f" =~ $keep_regex ]]; then
      continue
    fi
    rm -f -- "$f" 2>/dev/null || true
  done
}

check_quine() {
  local label="$1" src="$2" method="$3" compiler="${4:-}"

  [[ -f "$src" ]] || { bad "[$label] source not found: $src"; return 1; }
  
  if [[ -n "$compiler" ]] && ! command -v "$compiler" >/dev/null 2>&1; then
    inf "[$label] ${DIM}skipped (compiler not found: $compiler)${RESET}"
    return 3
  fi

  local before_list after_list
  before_list="$(mktemp)"
  after_list="$(mktemp)"

  local work bin out diffout compile_err
  work="$(mktemp -d)"
  bin="$work/a.out"
  out="${src}.out"
  diffout="${src}.diff"
  compile_err="$(mktemp)"

  cleanup() {
    [[ -n "${work:-}" ]] && rm -rf -- "$work" 2>/dev/null || true
    [[ -n "${before_list:-}" ]] && rm -f -- "$before_list" 2>/dev/null || true
    [[ -n "${after_list:-}" ]] && rm -f -- "$after_list" 2>/dev/null || true
    [[ -n "${compile_err:-}" ]] && rm -f -- "$compile_err" 2>/dev/null || true
  }
  trap cleanup RETURN

  _snapshot_cwd_files "$before_list"

  inf "[$label] ${DIM}$src${RESET}"

  local run_status=0
  (
    set -euo pipefail
    src="$src"
    bin="$bin"
    eval "$method"
  ) >"$out" 2>"$compile_err" || run_status=$?

  local status=0
  local keep_regex='^$'

  if [[ $run_status -ne 0 ]]; then
    bad "[$label] run/compile failed (exit $run_status)"
    if [[ -s "$compile_err" ]]; then
      local err_preview
      err_preview="$(head -1 "$compile_err" | head -c 80)"
      [[ -n "$err_preview" ]] && inf "  ${DIM}$err_preview${RESET}"
    fi
    rm -f -- "$out" "$compile_err" 2>/dev/null || true
    status=1
  else
    if cmp -s -- "$src" "$out"; then
      ok "[$label] quine OK"
      rm -f -- "$out" 2>/dev/null || true
      rm -f -- "$diffout" 2>/dev/null || true
      status=0
    else
      bad "[$label] mismatch"
      {
        echo "--- source: $src"
        echo "+++ output: $out"
        echo
        diff -u -- "$src" "$out" || true
      } >"$diffout"
      inf "diff saved to: ${DIM}$diffout${RESET}"
      rm -f -- "$out" 2>/dev/null || true

      local diff_base
      diff_base="$(basename -- "$diffout")"
      keep_regex="^${diff_base//./\\.}$"
      status=2
    fi
  fi

  _snapshot_cwd_files "$after_list"
  _cleanup_new_files_from_lists "$before_list" "$after_list" "$keep_regex"

  return "$status"
}

total=0
passed=0
failed=0
skipped=0

hr
run_check() {
  local result
  check_quine "$@" || true
  result=$?
  ((total++)) || true
  case $result in
    0) ((passed++)) || true ;;
    3) ((skipped++)) || true ;;
    *) ((failed++)) || true ;;
  esac
}

set +e
run_check "python"  "py.py"   'python3 "$src"'
run_check "c"       "c.c"     'clang -O2 -std=c11 -Wall -Wextra -Werror "$src" -o "$bin" && "$bin"' "clang"
run_check "cpp"     "cpp.cpp" 'clang++ -O2 -std=c++20 -Wall -Wextra -Werror "$src" -o "$bin" && "$bin"' "clang++"
run_check "rust"    "rs.rs"   'rustc -O "$src" -o "$bin" && "$bin"' "rustc"
run_check "golang"  "go.go"   'go build -o "$bin" "$src" && "$bin"' "go"
run_check "clojure" "clj.clj" 'clojure -M "$src"' "clojure"
run_check "bash"    "sh.sh"   'bash "$src"'
run_check "zig"     "zig.zig" 'zig run "$src"' "zig"
set -e
hr

printf "\n"
if [[ $passed -gt 0 ]]; then
  ok "Passed: $passed/$total"
fi
if [[ $failed -gt 0 ]]; then
  bad "Failed: $failed/$total"
fi
if [[ $skipped -gt 0 ]]; then
  inf "Skipped: $skipped/$total"
fi

exit $((failed > 0 ? 1 : 0))
