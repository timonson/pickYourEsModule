#!/usr/bin/env bash
set -Eu

# Change the 'URLBASE' variable or use the second positional argument.
URLBASE='file:///home/timo/shared'
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

hasRightArgs() {
  if [ -z "$1" ] || [ -z "${2:-${URLBASE}}" ]; then
    printf "This script needs at least two arguments.\n"
    return 1
  fi
}

selectionApp="$(select_from "${SELECTIONAPPS[@]}")"
cwd="$(pwd)"

if [ "${1}" == "-f" ]; then
  shift
  hasRightArgs $@ || exit 1
  cd ${1}
  commitOrTag=
elif [ "${1}" == "-c" ]; then
  shift
  hasRightArgs $@ || exit 1
  cd ${1}
  commitOrTag="@$(git rev-parse --short HEAD)"
else
  hasRightArgs $@ || exit 1
  cd ${1}
  git fetch --tags
  commitOrTag="@$(git describe --tags $(git rev-list --tags --max-count=1))"
fi \
  || { printf "Could not define variable 'commitOrTag'.\n" && exit 1; }

cd "$cwd"

fullDirPath=$([ "${1}" ] && getAbsolutePathname "${1}") \
  || { printf "Path ${1} doesn't exist.\n" && exit 1; }

urlbase=$([ "${2:-${URLBASE}}${commitOrTag}" ] && printf "${2:-${URLBASE}}${commitOrTag}") \
  || { printf "Define the 'URLBASE' variable or call the script with the url base \
               second argument. Example: URLBASE=https://deno.land/std\n" && exit 1; }

denoOptions="${@:3}"

relativeModulePath=$(filterAndPrintFiles $fullDirPath \
  | pick "$selectionApp" "Select File") \
  || exit 0

moduleSelection=$(deno run -A --no-check $denoOptions "$(dirname $0)/getEsModules.js" "$fullDirPath/$relativeModulePath" \
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
