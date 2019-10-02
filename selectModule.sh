#!/usr/bin/env bash
set -Eu

# Change the 'DIR' variable!
DIR=
URLBASE=https://deno.land/std
EXCLUDEDREGEX='prettier \.d\. _test playground testdata bundle'
SELECTIONAPPS=("rofi -i -dmenu" dmenu)
COPYAPPS=("xclip -selection clipboard" xsel)

exclude() {
  local file=$1 && shift
  for pattern; do
    string+=" -e $pattern"
  done
  printf "$file" | grep -i $string > /dev/null 2>&1 && return 1 || true
}

getExtension() {
  : "${1%/}"
  printf '%s\n' "${_##*.}"
}

printTypescriptFiles() {
  for file in $1/*; do
    if [ -d "$file" ]; then
      printTypescriptFiles "$file"
    else
      if [ ".$(getExtension "$file")" == ".ts" ] \
        || [ ".$(getExtension "$file")" == ".js" ] \
        && grep '^export' "$file" > /dev/null 2>&1 \
        && exclude "$file" $EXCLUDEDREGEX; then
        printf "${file##$dir/}\n"
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

dir=${1:-${DIR}}
[ -z $dir ] \
  && printf "Define the 'DIR' variable or call the script with the directory path as first argument.\n" \
  && exit 1
urlbase=${2:-${URLBASE}}
selectionApp="$(select_from "$SELECTIONAPPS")"
copyApp="$(select_from "$COPYAPPS")"
relativeModuleFile=$(printTypescriptFiles $dir | $selectionApp -p "Select File")
[ -z $relativeModuleFile ] && exit 0
url=${urlbase%/}/$relativeModuleFile
modules=$(deno -A $(dirname $0)/getEsModules.js "$dir/$relativeModuleFile")
module=$(printf "$modules" | $selectionApp -p "Select Module")
[ -z $module ] && exit 0
selectedModule=$(printf $module)
isDefault=$(printf "$module" | cut -s -f 2 -d ' ')
[ -z ${isDefault:-} ] \
  && importCmd="import { $selectedModule } from \"$url\";" \
  || importCmd="import $selectedModule from \"$url\";"
printf "$importCmd" | $copyApp
