#!/bin/bash
# meme2txt: A bash wrapper for img2txt.py to super-impose text on ASCII images.
# Dependencies: img2txt.py, toilet (optional)
# Author: Dylan Madisetti <contact at dylanmadisetti.com>

# You know when you start prototyping something in bash, just to get a feel for
# the problem, even though bash probably isn't the right answer? At some point,
# you want to just finish the project, but you're too deep into writing regexes
# and building pipelines for your bash prototype- that you just decide to stick
# it through and finish writing the utility in bash. That's exactly what
# happened here. It works, but it uses an implements awful abuse of capture
# groups, and regexes. At least it's light weight.

# Example of use:
# meme2txt.sh mindblown.png --targetAspect=0.5 --meme "Memes with resolution" 10 25 \
#     "30m" --meme "$(toilet "Memes in text" -fsmblock)" 25 5 "34m"

# Limitations:
#  - Strange things will happen if multiple texts occupy the same line.
#  - Multiline can be distorted. Moving around the text generally fixes this.
#  - Using `toilet --metal` alters the background color.

ANSI_CAPTURE="(?:[\e]\[[^m\e]*[mK])?[^\e]?"
TRAILING="s/[ \t]*$//"
MARGIN=5

instruct() {
  >&2 echo "Usage:
  meme2txt <img2txt arguments> [--meme "text" column row [color]]"
}

colorize() {
  # Look up for colors. Default is black.
  local color;
  color=$1; shift
  if [ "$color" == "-" ]
  then
    echo -ne ""
  else
    case "$(echo "$color" | tr "[:upper:]" "[:lower:]")" in
      black)
        color=30m
        ;;
      red)
        color=31m
        ;;
      green)
        color=32m
        ;;
      yellow)
        color=33m
        ;;
      blue)
        color=34m
        ;;
      purple)
        color=35m
        ;;
      cyan)
        color=36m
        ;;
      white)
        color=37m
        ;;
    esac
    echo -ne "[${color}"
  fi
}

reset() {
  # If a color is set, restore to default text color for after print.
  local color=$1; shift
  if [ -z "$color" ]
  then
    echo -ne ""
  else
    echo -ne "[39m"
  fi
}

memeify() {
  # Returns a perl regex for find and replace.
  local length;
  local text;
  local line
  local offset;
  local color;
  local reset;

  length=$1; shift
  text=${1:-"Your meme text here"}; shift
  line=${1:-$MARGIN}; shift
  offset=${1:-$MARGIN}; shift
  color="$(colorize "${1:-30m}")"
  reset="$(reset "${color}")"

  # Just iterates over lines.
  while read -r subtext; do
    local chars;
    local limit;
    local replace;

    subtext="$(echo -ne "${subtext}" | sed "$TRAILING")"
    # Determine how many displayed characters there are
    chars=$(echo -ne "${subtext}" | grep -oP "$ANSI_CAPTURE" | wc -l)

    # If the text goes off the page, truncate the text.
    limit=$((offset + chars - length + MARGIN))
    if [ $limit -gt 0 ]
    then
      chars=$((length - offset - MARGIN))
      # We only want to truncate the displayed characters.
      subtext="$(echo -ne "${subtext}" | grep -oP "$ANSI_CAPTURE" | head -${chars} | tr -d "\n" | sed "$TRAILING")";
      chars=$(echo -ne "${subtext}" | grep -oP "$ANSI_CAPTURE" | wc -l)
    fi

    # Interleave capture groups between the text, such that the image formating
    # stays consistent. e.g. hello -> h$1e$2l$3l$3o$4
    subtext="$(echo -ne "${subtext}${reset}" | grep -oP "$ANSI_CAPTURE" | awk '{print "${"1 + NR"}"$s}' | tr -d '\n')"
    subtext="${color}${subtext:4}"

    # Build the respective capture groups for interleaving. Note that img2txt.py
    # uses only space for displayed characters. This should replace every space
    # with a respective character from the text.
    replace=$(head -c "$chars" < /dev/zero | tr '\0' ' ' | sed 's/ / \([^ ]*\)/g')

    # Echo out our regex for perl matching.
    echo "s/(([^ ]* ){${offset}})${replace}/\${1}${subtext}/ if \$. == ${line};"
    line=$((line + 1))
  done <<< "$text"
}

main(){
  local img=""
  local memeing=0
  local length=0
  local args=("$@")
  for index in $(seq 0 $(($# + 1)))
  do
    # All arguments between --meme and --meme are passed into memeify. We start
    # noting the index occurence of --meme so we can pass a slice to memeify.
    # This also captures the edgecase of the final --meme and the end.
    if [ "${args[index]}" == "--meme" ] || [ "$index" -eq $# ]
    then
      if [ $memeing -eq 0 ]
      then
        # We pass all arguments between invocation and the first meme
        # declaration into img2txt.py. ANSI must be specified for obvious
        # reasons, so we do that for free.
        img=$(img2txt.py --ansi "${@:1:$index}") || {
          instruct
          exit 1
        }
        # Determine the width of the image for text truncation.
        length=$(echo "${img}" | head -1 | grep -oP "$ANSI_CAPTURE" | wc -l)
      else
        # Replace select spaces with the text provided.
        img="$(echo -ne "$img" | perl -pe "$(memeify "${length}" "${@:$memeing+2:$index}")")" || exit 1
      fi
      # Note that a meme invocation has started.
      memeing=$index
    fi
  done

  # Finally echo out our image.
  echo -e "$img"
}

main "$@"
