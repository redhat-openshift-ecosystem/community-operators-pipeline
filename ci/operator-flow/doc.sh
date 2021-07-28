#!/bin/bash
NPRS=${1-5000}
REPO=${2-"redhat-openshift-ecosystem/community-operators-pipeline"}
ADMINS=${ADMINS-"mvalarh J0zi"}

SCRIPT_DIR="$(dirname $(readlink -m $0))"
DOC_DIR="$(dirname $(dirname $(dirname $(readlink -m $0))))"/docs

$SCRIPT_DIR/measure-operator-flow.py -l $NPRS -o results.json -r $REPO -a $ADMINS
$SCRIPT_DIR/ana.py
[ -d $DOC_DIR/images/stats ] || mkdir -p $DOC_DIR/images/stats
cp *.pdf *.png $DOC_DIR/images/stats
