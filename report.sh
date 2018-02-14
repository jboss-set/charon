#!/bin/bash
# sh does not seem to have array/split operator, other than awk?
# That is why bash is in action


#directory to which we will checkout git repos and do magic.
REPO_DIR=${REPO_DIR:-$(mktemp -d)}
INIT_DIR="$(pwd)"
OUTPUT_DIR="report"
OUTPUT_CODE_DIR="_code_"
OUTPUT_FILE_HTML="report.html"
OUTPUT_HANDLE="$OUTPUT_DIR/$OUTPUT_FILE_HTML"


REPORT_INIT="config/report_prefix.txt"
REPORT_END="config/report_footer.txt"
START=$(date +%s)


init_script(){
    clean
    mkdir "$OUTPUT_DIR"
    mkdir "$OUTPUT_DIR/$OUTPUT_CODE_DIR"
    mkdir "$REPO_DIR"
    cat $REPORT_INIT >> "$OUTPUT_HANDLE"
}

clean(){
    cd $INIT_DIR
    rm -rf $OUTPUT_DIR
    rm -rf $REPO_DIR
}

checkoutSVN(){
    rm -rf $REPO_DIR
    if [ "$1" = "" ]; then
        return 0
    elif [ "$2" = "" ]; then
        return 0
    fi
    
    echo ""
    echo "Checkout \"$1\""
    echo ""
    svn checkout $1/$2 $REPO_DIR
}

checkoutGIT(){
    rm -rf $REPO_DIR
    if [ "$1" = "" ]; then
        return 0
    fi
    echo ""
    echo "Checkout \"$1\""
    echo ""
    git clone $1 $REPO_DIR
    return 0
}

getLinesOfCode(){
    FILE="$OUTPUT_CODE_DIR/$1".txt
    cloc $REPO_DIR --quiet --report-file="$OUTPUT_DIR/$FILE"_
    #CLOC adds some trash in first line, remove it
    tail -n +2 "$OUTPUT_DIR/$FILE"_ >> "$OUTPUT_DIR/$FILE"
    rm "$OUTPUT_DIR/$FILE"_
    echo $FILE
}

getGITCommitsFromBranch(){

    if [ "$1" = "" ]; then
        return 0
    elif [ "$2" = "" ]; then
        return 0
    fi

    cd $REPO_DIR
    git checkout $1

    #NOTE: This will include "Merge commit " messages, something to tinker with
    git --no-pager log --pretty=oneline   tags/$2...origin/$1
    COMMIT_NUMBER=`git log --pretty=oneline   tags/$2...origin/$1 | wc -l`
    cd $INIT_DIR
    return $COMMIT_NUMBER
}

tableCreateRowStart(){
    echo "		<tr>" >> $OUTPUT_HANDLE
}
tableCreateRowEnd(){
    echo "		</tr>" >> $OUTPUT_HANDLE
}

tableCreateCell(){
    echo "			<td>$1</td>" >> $OUTPUT_HANDLE
}

tableCreateCellLink(){
    echo "			<td><a href=\"$1\" target=\"_blank\">Link</a></td>" >> $OUTPUT_HANDLE
}

reportEnd(){
    rm -rf $REPO_DIR
    cat $REPORT_END >> "$OUTPUT_HANDLE"
    END=$(date +%s)
    DIFF=$(( $END - $START ))
    echo "#################################################"
    echo " Finalized report, access:"
    echo " > $OUTPUT_HANDLE"
    echo " > Duration: `date -u -d @$DIFF +\"%T\"`"
    echo "#################################################"
}

###################
#ACTION start here#
###################
if [ $# != 1 ]; then
    echo 1>&2 "Usage: $0 <input_file.txt>"
    exit 1
fi
echo "#################################################"
echo " Initializing repository report:"
echo " > $1"
echo "#################################################"
init_script


while read component; do
# component content
# undertow-io-undertow-js;sdouglas@redhat.com;GIT;https://github.com/undertow-io/undertow.js.git;1.0.x;1.0.2.Final;1.0.2.Final-redaht-599;io.undertow.js;$TAG_DIF_BRANCH;$LINES_OF_CODE;$COMMENT
#     0                           1            2               3                                   4      5                6                      7             8              9           10
    IFS=';' read -ra PIECES <<< "$component"
    tableCreateRowStart
    tableCreateCell "${PIECES[0]}"
    tableCreateCell "${PIECES[1]}"
    tableCreateCell "${PIECES[2]}"
    tableCreateCellLink "${PIECES[3]}"
    tableCreateCell "${PIECES[4]}"
    tableCreateCell "${PIECES[5]}"
    tableCreateCell "${PIECES[6]}"
    tableCreateCell "${PIECES[7]}"

    if [ "${PIECES[2]}" = "SVN" ]; then
        checkoutSVN "${PIECES[3]}" "${PIECES[4]}"
        #There is no way to calculate tag diff for svn?
        tableCreateCell ""
        if [ -d "$REPO_DIR" ]; then
            loc=$(getLinesOfCode "${PIECES[0]}")
            [[ $loc =~ _code_\/.+\.txt ]]
            tableCreateCellLink "$BASH_REMATCH"
        else 
            tableCreateCell ""
        fi
    elif [ "${PIECES[2]}" = "GIT" ]; then
        checkoutGIT "${PIECES[3]}"
        if [ -d "$REPO_DIR" ]; then
            getGITCommitsFromBranch "${PIECES[4]}" "${PIECES[5]}"
            tableCreateCell "$?"
            loc=$(getLinesOfCode "${PIECES[0]}")
            #grep + regexp is required, since CLOC or shell adds some trash to 'loc'
            [[ $loc =~ _code_\/.+\.txt ]]
            # BASH_REMATCH contain result of above call
            tableCreateCellLink "$BASH_REMATCH"
        else
            tableCreateCell ""
            tableCreateCell ""
        fi
    
    else 
        tableCreateCell "${PIECES[8]}"
        tableCreateCellLink "${PIECES[9]}"
    fi
    #if [ ${#distro[@]} = 10 ]; then
        tableCreateCell "${PIECES[10]}"
    #fi
    
    tableCreateRowEnd
done < $1

reportEnd