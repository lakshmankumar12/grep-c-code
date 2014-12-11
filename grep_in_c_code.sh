#!/bin/bash

usage()
{
  echo "$1 .. grep regex and also report the c-function its found in .."
  echo "      It prepares a grepOp file that is loaded at this pwd in vim's quickfix window"
  echo ""
  echo "Usage: $1 <sub-dir> <regexp>"
  echo ""
  echo " <sub-dir>      look only this sub-dir"
  echo " <regexp>       the regexp"
  exit 1;
}

while getopts "x:p:h" opt; do
  case $opt in
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage $0
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

if [ -z "$1" ] ; then
  echo "Supply a dir. Use ./ if u want entire pwd!"
  usage $0
fi

SUBDIR=$1
shift

if [ -z "$1" ] ; then
  echo "Supply a Regexp!"
  usage $0
fi

REGEX=$1
shift

# assumptions (dumb, but works most of the time and is fairly efficient!):
#   1. A function-start is simply a line with a { at column-1
#   2. A function-name is simply that matches [[:alnum:]]\+[::space:]]*( in it.
#   3. The current-function-name is the latest function-name preceding a function-start

a=$(find . -name '*.[ch]')

for i in $a ; do 

  gawk -v re=$REGEX -v file=$i '

  BEGIN {
    CURR_FUNCTION="Outside-context"
    CURR_FUNCTION_LINE=0
    FUNCTION="None-found"
    FUNCTION_LINE=0
  }

  /^\{/ {
   CURR_FUNCTION = FUNCTION
   next
  }

  /^\}/ {
   CURR_FUNCTION = "Outside-context"
   CURR_FUNCTION_LINE = FUNCTION_LINE
   next
  }

  /[[:alnum:]]+[[:space:]]*\(/ { # mind you.. this can match even-function-calls.
    a=$0;
    match(a,"[[:alnum:]]+[[:space:]]*\\(",arr);
    FUNCTION=arr[0]
    FUNCTION_LINE=NR
  }

  $0 ~ re {
    printf "%s:%d:in-function %s at line %d: %s\n",file,NR,CURR_FUNCTION,CURR_FUNCTION_LINE,$0
  } ' $i

done

