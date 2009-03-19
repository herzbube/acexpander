#!/bin/sh
#
# Simple shell script front end to unace.
#
# This front end is necessary as long as the calling Cocoa code is not able
# to
# a) create the destination folder where the contents of the ACE archive
#    file should be expanded to
# b) change the application's working directory to this destination folder

# Query first 2 positional parameters
unaceBin="$1"
if test ! -x "$unaceBin"; then
  echo "Unace binary not found, or is not an executable: $unaceBin" >&2
  exit 1
fi
shift 1

case "$1" in
  --version)
    # Get the version information
    "$unaceBin" --version | grep -v "^$" | head -2
    exit 0
    ;;
  --folder)
    destinationFolder="$2"
    shift 2
    # Create the destination folder if doesn't exist yet
    if test ! -d "$destinationFolder"; then
      mkdir -p "$destinationFolder"
      if test $? -ne 0; then exit 1; fi
    fi
    # Change working directory to the destination folder
    cd "$destinationFolder"
    if test $? -ne 0; then exit 1; fi
    ;;
esac

debugMode=$1
shift 1

if test $debugMode = "1"; then
   echo "Debug mode on."
   echo "unace binary: $unaceBin"
   echo "Destination folder: $destinationFolder"
   echo "Number of remaining parameters: $#"
   i=0
   for param in "$@"; do
      i=$(expr $i + 1)
      echo "Value for parameter $i: $param"
   done
fi

# Execute unace with the remaining positional parameters
# Quote from "man sh":
#    $@ expands to the positional parameters, starting from
#    one. When the expansion occurs within double-quotes, each
#    positional parameter expands as a separate argument.
"$unaceBin" "$@"
