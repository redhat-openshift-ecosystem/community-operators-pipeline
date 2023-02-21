#!/bin/bash
NPRS=${1-5000}
REPO=${2-"redhat-openshift-ecosystem/community-operators-pipeline"}
ADMINS=${ADMINS-"Allda mporrato mvalarh J0zi"}

SCRIPT_DIR="$(dirname $(readlink -m $0))"
DOC_DIR="$(dirname $(dirname $(dirname $(readlink -m $0))))"/docs

ORG=$(echo $REPO | cut -d '/' -f 1)
PROJ=$(echo $REPO | cut -d '/' -f 2)

rm -f results.json
echo "$SCRIPT_DIR/measure-operator-flow.py -l $NPRS -o results.json -r $REPO -a $ADMINS"
$SCRIPT_DIR/measure-operator-flow.py -l $NPRS -o results.json -r $REPO -a $ADMINS || true
if [ ! -f results.json ];then
  status=$(curl -s -w "%{http_code}\\n" https://${ORG}.github.io/${PROJ}/images/stats/results.json -s -o /dev/null)
  echo "$status"
  [ "$status" == "200" ] && curl https://${ORG}.github.io/${PROJ}/images/stats/results.json -O
fi
[ -f results.json ] || cp $DOC_DIR/images/stats/results.json .
$SCRIPT_DIR/ana.py
[ -d $DOC_DIR/images/stats ] || mkdir -p $DOC_DIR/images/stats
mv *.pdf *.png results.json $DOC_DIR/images/stats/
