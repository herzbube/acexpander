MYNAME=$(basename $0)
TMPFILE=/tmp/$MYNAME.tmp
ACEEXPANDER_DIR=AceExpander
WORKDIR=$(dirname $0)/..

if test $# -ne 1; then
   echo "No version given"
   exit 1
fi
VERSION=$1
ACEEXPANDER_DISTRIBUTE_DIR=aceexpander-$VERSION
ACEEXPANDER_DISTRIBUTE_FILE=aceexpander-$VERSION.tar

cd $WORKDIR
if test ! -d "$ACEEXPANDER_DIR"; then
   echo "Directory $ACEEXPANDER_DIR not found in $WORKDIR"
   exit 1
fi

mv $ACEEXPANDER_DIR $ACEEXPANDER_DISTRIBUTE_DIR
if test $? -ne 0; then
   echo "Error mv $ACEEXPANDER_DIR $ACEEXPANDER_DISTRIBUTE_DIR"
   exit 1
fi

find $ACEEXPANDER_DISTRIBUTE_DIR -type f | \
   egrep -v "(CVS|.DS_Store|$MYNAME|$ACEEXPANDER_DISTRIBUTE_DIR/build|$ACEEXPANDER_DISTRIBUTE_DIR/Archive|$ACEEXPANDER_DISTRIBUTE_DIR/Testfiles)" \
   >$TMPFILE
if test ! -s $TMPFILE; then
   mv $ACEEXPANDER_DISTRIBUTE_DIR $ACEEXPANDER_DIR
   echo "No files to distribute"
   exit 1
fi

tar cf $ACEEXPANDER_DISTRIBUTE_FILE $(cat $TMPFILE)
if test $? -ne 0; then
   mv $ACEEXPANDER_DISTRIBUTE_DIR $ACEEXPANDER_DIR
   echo "Error tarring"
   exit 1
fi

gzip $ACEEXPANDER_DISTRIBUTE_FILE
if test $? -ne 0; then
   mv $ACEEXPANDER_DISTRIBUTE_DIR $ACEEXPANDER_DIR
   echo "Error zipping"
   exit 1
fi

mv $ACEEXPANDER_DISTRIBUTE_DIR $ACEEXPANDER_DIR
