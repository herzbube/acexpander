#!/bin/sh
#
# Simple shell script front end to unace.
#
# This front end is necessary as long as the
# calling Cocoa code is not able to change
# the working directory to the directory
# containing the ACE archive file :-(

# Query first 2 positional parameters
unaceBin=$1
archiveDir=$2
shift 2

# Change working directory
cd "$archiveDir"
if test $? -ne 0; then exit $?; fi

debugMode=$1
shift 1

if test $debugMode = "1"; then
   echo "Debug mode on."
   echo "Number of arguments: $#"
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
