#!/bin/bash

# requires: jq, npm

if [ "$#" -eq 0 ]; then
  DIRS=(*/)
else
  DIRS=( "$@" )
fi
DIRS=${DIRS[@]}  #make it into an array


HOST=http://localhost:8080/api/apps
HOSTCRED="admin:district"


CWD=$(pwd)
for DIR in $DIRS ; do
    if [[ "${DIR: -1}" = "/" ]]; then 
	PKG=${DIR:0:${#DIR}-1}
    else
	PKG=$DIR
	DIR="${DIR}/"
    fi
    echo "Packaging Directory $DIR"
    cd $CWD/$DIR 
    touch manifest.webapp
    VERS=`npm version | grep $PKG | awk -F: '{print $2}'   | awk -F\' '{print $2}'`
    echo "Version ${VERS}"
    JQ="'to_entries |   map(if .key == \"version\"  then . + {\"value\":\"$VERS\"}   else .  end ) |  from_entries'"
    JQ_EXEC="cat $CWD/$DIR/manifest.webapp | jq $JQ > /tmp/$PKG.manifest.webapp"
    eval $JQ_EXEC
    if [ "$?" = "0" ]; then	
	diff /tmp/$PKG.manifest.webapp $CWD/$DIR/manifest.webapp > /dev/null
	if [ "$?" != "0" ]; then	
	    echo "Updating manifest.webapp in source directory"
	    cp /tmp/$PKG.manifest.webapp $CWD/$DIR/manifest.webapp
	fi
	ZIP=$PKG.zip
	FILES=`git ls-tree --full-tree --name-only -r HEAD  | grep -v gitignore  |grep -v $ZIP`
	echo "Packaging: ${FILES}"
	zip -r $CWD/$DIR/$ZIP $FILES  
	echo "Uploading $ZIP to $HOST"
	curl -vv -k -u $HOSTCRED -F file=@$CWD/$DIR/$ZIP $HOST
    else
	echo "Could not package $PKG"
    fi
done

