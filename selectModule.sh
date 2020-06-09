#!/usr/bin/env bash
set -Eu

# Change the 'DIR' variable or use the first positional argument.
# An optional second positional argument overwrites the 'URLBASE' variable.
DIR=
URLBASE=https://deno.land/std
EXCLUDEDREGEX='prettier \.d\. _test playground testdata bundle'
SELECTIONAPPS=("rofi -i -dmenu" dmenu)
COPYAPPS=("xclip -selection clipboard" xsel)
# for deno:
export NO_COLOR=true

exclude() {
  local file=$1 && shift
  for pattern; do
    string+=" -e $pattern"
  done
  printf "$file" | grep -i $string > /dev/null 2>&1 \
    && return 1 \
    || true
}

getExtension() {
  : "${1%/}"
  printf '%s\n' "${_##*.}"
}

filterAndPrintFiles() {
  for file in $1/*; do
    if [ -d "$file" ]; then
      filterAndPrintFiles "$file"
    else
      if [ ".$(getExtension "$file")" == ".ts" ] \
        || [ ".$(getExtension "$file")" == ".js" ] \
        && grep '^export' "$file" > /dev/null 2>&1 \
        && exclude "$file" $EXCLUDEDREGEX; then
        printf "${file##${fullDirPath}/}\n"
      fi
    fi
  done
}

select_from() {
  local cmd a c
  cmd='command -v'
  for a in "$@"; do
    case "$a" in
      -c)
        cmd="$2"
        shift 2
        ;;
    esac
  done
  for c in "$@"; do
    if $cmd "${c%% *}" &> /dev/null; then
      printf "$c"
      return 0
    fi
  done
  return 1
}

getAbsolutePathname() {
  cd "$(dirname "$1")" > /dev/null 2>&1 || return 1
  printf "$(pwd)/$(basename "$1")"
  cd "$OLDPWD"
}

pick() {
  local store
  store=$(${1:-rofi -dmenu} -p "${2:-Select}")
  [ "$store" ] && printf "$store" || return 1
}

selectionApp="$(select_from "${SELECTIONAPPS[@]}")"

if [ "${1:-}" == "-c" ]; then
  shift
  commit="@$(git -C ${1:-${DIR:-}} rev-parse --short HEAD)"
fi \
  || { printf "Could not define variable 'commit'.\n" && exit 1; }

fullDirPath=$([ "${1:-${DIR:-}}" ] && getAbsolutePathname "${1:-${DIR:-}}") \
  || { printf "Path ${1:-${DIR:-}} doesn't exist.\n" && exit 1; }

urlbase=$([ "${2:-${URLBASE:-}}${commit:-}" ] && printf "${2:-${URLBASE:-}}${commit:-}") \
  || { printf "Define the 'URLBASE' variable or call the script with the url base \
                              second argument. Example: URLBASE=https://deno.land/std\n" && exit 1; }

denoOptions="${@:3}"

relativeModulePath=$(filterAndPrintFiles $fullDirPath \
  | pick "$selectionApp" "Select File") \
  || exit 0

moduleSelection=$(deno run -A $denoOptions "$(dirname $0)/getEsModules.js" "$fullDirPath/$relativeModulePath" \
  | pick "$selectionApp" "Select Module") \
  || exit 0

url=${urlbase%/}/$relativeModulePath
selectedModule=$(printf $moduleSelection)
isDefault=$(printf "$moduleSelection" | cut -s -f 2 -d ' ')
[ -z "${isDefault:-}" ] \
  && importCmd="import { $selectedModule } from \"$url\";" \
  || importCmd="import $selectedModule from \"$url\";"

copyApp="$(select_from "${COPYAPPS[@]}")"

printf "$importCmd" | $copyApp
