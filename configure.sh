#!/bin/bash
#This script fetch streams from given location, cuts and stitch it with jq into csv. Once done it disects in based on first entry and create entry files 
#that can be consumed by report. Each file correspond to different stream

#directories
TMP_DIR=${TMP_DIR:-$(mktemp -d)}
INIT_DIR="$(pwd)"
OUTPUT_DIR="$INIT_DIR/config"

#files
TMP_JSON="$TMP_DIR/tmp.csv"

init_script(){
    clean
    mkdir "$TMP_DIR"
}

clean(){
    cd $INIT_DIR
    rm -rf $TMP_DIR
    #rm -rf $OUTPUT_DIR/*-input.txt
}

checkoutStreams(){
    rm -rf "$TMP_DIR/STREAM_REPO"
    if [ "$1" = "" ]; then
        return 0
    fi
    if [ "$2" = "" ]; then
        return 0
    fi
    
    echo ""
    echo "Checkout \"$1\""
    echo ""
    git clone $1 "$TMP_DIR/STREAM_REPO"
    cp "$TMP_DIR/STREAM_REPO/$2" "$TMP_DIR/"
    return 0
}

###################
#ACTION start here#
###################
if [ $# != 2 ]; then
    echo 1>&2 "Usage: $0 <GIT_STREAMS_REPO> <streams.json>"
    exit 1
fi
echo "#################################################"
echo " Initializing streams.json to csv parsing:"
echo " > $1"
echo "#################################################"
init_script
checkoutStreams $1 $2


#create tmp file which is conversion of JSON
# cat > jq
# jq filters: 
#1 select .streams array |
#2 from each entry select .name and codebase[] object, encapsulate in {}  - this create object and essentially for each entry in codebase, produce .name + .codebase[n] object
#3 select entries from previous filter, so we loose names
#4 send to @csv     

#sed - strip and replace " and ,
cat $TMP_DIR/$2 | jq  -r '.streams[] | { name, codebase:.codebases[] } | [.name,.codebase.component_name, .codebase.contacts[0], .codebase.repository_type, .codebase.repository_url, .codebase.codebase, .codebase.tag, .codebase.version, .codebase.gav,"","",.codebase.comment] | @csv' | sed -e 's/\,/;/g' -e 's/\"//g' >> $TMP_JSON

CP_STREAM=""
OUTPUT_FILE_NAME=""
while read component; do
# component content
#  CP_STREAM;undertow-io-undertow-js;sdouglas@redhat.com;GIT;https://github.com/undertow-io/undertow.js.git;1.0.x;1.0.2.Final;1.0.2.Final-redaht-599;io.undertow.js;$TAG_DIF_BRANCH;$LINES_OF_CODE;$COMMENT
#      0           1                        2              3                        4                        5       6                   7                 8              9             10            11
IFS=';' read -ra PIECES <<< "$component"
if [ "${PIECES[0]}" != "$CP_STREAM" ]; then
	CP_STREAM="${PIECES[0]}"
	OUTPUT_FILE_NAME="$OUTPUT_DIR/$CP_STREAM"-input.txt
fi
echo "${PIECES[1]};${PIECES[2]};${PIECES[3]};${PIECES[4]};${PIECES[5]};${PIECES[6]};${PIECES[7]};${PIECES[8]};${PIECES[9]};${PIECES[10]};${PIECES[11]}" >> $OUTPUT_FILE_NAME
done < $TMP_JSON

clean