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
unaceBin=$1
destinationFolder=$2
shift 2

# Get the version information
if test "--version" = "$destinationFolder"; then
   "$unaceBin" --version | grep -v "^$" | head -2
   exit 0
fi

# Create the destination folder if doesn't exist yet
if test ! -d "$destinationFolder"; then
   mkdir -p "$destinationFolder"
   if test $? -ne 0; then exit 1; fi
fi
  
# Change working directory to the destination folder
cd "$destinationFolder"
if test $? -ne 0; then exit 1; fi

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
