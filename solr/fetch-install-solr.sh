#!/bin/bash
command -v curl >/dev/null 2>&1 || { echo >&2 "Curl is required. Aborting."; exit 1; }

DOWNLOAD_URI_SOLR=http://www.eu.apache.org/dist/lucene/solr/5.4.0/solr-5.4.0.tgz
TEMP_ARCHIVE=/tmp/solr-archive.tgz
# suggested TARGET_ROOT_DIR='/opt/app/solr'
TARGET_ROOT_DIR='.'

TARGET_DATA_DIR=${TARGET_ROOT_DIR}/server/solr


if [ -f $TEMP_ARCHIVE ];
then
    echo "Using existing archive .."
else
    echo "Downloading solr archive from $DOWNLOAD_URI .."
    curl -L $DOWNLOAD_URI_SOLR > $TEMP_ARCHIVE
fi

echo "Preparing target installation directory and extracting .. "
mkdir -p $TARGET_ROOT_DIR
tar -xzf /tmp/solr-archive.tgz -C $TARGET_ROOT_DIR --strip-components=1

echo "Preparing data directories and installing default configsets .."
mkdir -p $TARGET_DATA_DIR

cp -r configsets/* $TARGET_DATA_DIR/configsets
