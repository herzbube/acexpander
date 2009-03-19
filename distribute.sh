#!/bin/bash
#
# Creates a .tar.gz file that contains the source distribution of AceXpander.
# Note: the project directory is temporarily renamed.

MYNAME=$(basename $0)
TMPFILE=/tmp/$MYNAME.tmp
ACEXPANDER_DIR=acexpander
WORKDIR=$(dirname $0)/..

if test $# -ne 1; then
   echo "No version given"
   exit 1
fi
VERSION=$1
ACEXPANDER_DISTRIBUTE_DIR=acexpander-$VERSION
ACEXPANDER_DISTRIBUTE_FILE=acexpander-$VERSION.tar

cd $WORKDIR
if test ! -d "$ACEXPANDER_DIR"; then
   echo "Directory $ACEXPANDER_DIR not found in $WORKDIR"
   exit 1
fi

mv $ACEXPANDER_DIR $ACEXPANDER_DISTRIBUTE_DIR
if test $? -ne 0; then
   echo "Error mv $ACEXPANDER_DIR $ACEXPANDER_DISTRIBUTE_DIR"
   exit 1
fi

find $ACEXPANDER_DISTRIBUTE_DIR -type f | \
   egrep -v "(CVS|.svn|.DS_Store|$MYNAME|$ACEXPANDER_DISTRIBUTE_DIR/build|$ACEXPANDER_DISTRIBUTE_DIR/Archive|$ACEXPANDER_DISTRIBUTE_DIR/Testfiles|$ACEXPANDER_DISTRIBUTE_DIR/Graphics)" \
   >$TMPFILE
ls $ACEXPANDER_DISTRIBUTE_DIR/Graphics/*.icns >>$TMPFILE
if test ! -s $TMPFILE; then
   mv $ACEXPANDER_DISTRIBUTE_DIR $ACEXPANDER_DIR
   echo "No files to distribute"
   exit 1
fi

tar cf $ACEXPANDER_DISTRIBUTE_FILE $(cat $TMPFILE)
if test $? -ne 0; then
   mv $ACEXPANDER_DISTRIBUTE_DIR $ACEXPANDER_DIR
   echo "Error tarring"
   exit 1
fi

gzip $ACEXPANDER_DISTRIBUTE_FILE
if test $? -ne 0; then
   mv $ACEXPANDER_DISTRIBUTE_DIR $ACEXPANDER_DIR
   echo "Error zipping"
   exit 1
fi

mv $ACEXPANDER_DISTRIBUTE_DIR $ACEXPANDER_DIR
