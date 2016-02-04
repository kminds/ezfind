#!/bin/bash
command -v curl >/dev/null 2>&1 || { echo >&2 "Curl is required. Aborting."; exit 1; }

DOWNLOAD_URI_SOLR=http://apache.belnet.be/lucene/solr/5.4.1/solr-5.4.1.tgz
TEMP_ARCHIVE=solr-5.4.1.tgz
# suggested TARGET_ROOT_DIR='/opt/app/solr'
TARGET_ROOT_DIR='.'

TARGET_DATA_DIR=${TARGET_ROOT_DIR}/server/solr

# Override default config values if custom configuration file is present
if [[ -f config.in.sh ]]
then
   . config.in.sh
fi


if [[ -f $TEMP_ARCHIVE ]];
then
    echo "Using existing archive .."
else
    echo "Downloading solr archive from $DOWNLOAD_URI .."
    curl -L $DOWNLOAD_URI_SOLR > $TEMP_ARCHIVE
fi

echo ".. preparing target installation directory and extracting .. "
mkdir -p $TARGET_ROOT_DIR
tar -xzf $TEMP_ARCHIVE -C $TARGET_ROOT_DIR --strip-components=1

echo ".. copying configsets (templates) to destination .."
mkdir -p $TARGET_DATA_DIR

cp -r configsets/* $TARGET_DATA_DIR/configsets

echo "Done."
