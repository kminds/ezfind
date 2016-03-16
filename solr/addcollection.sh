#!/bin/bash


SOURCE_MODE='LANGUAGE'

if [[ "$1" == "-h"  ||   ( -z $1  || -z $2 || !( -d solr.languages/$1 || -d $1 ) ) ]]
then

   if [[  ! -z $1 &&  ! "$1" == "-h" &&  ! -d solr.languages/$1 ]] 
   then
      MESSAGE="ERROR: $1 does not exist as a language, also not found as a custom source configset"
   fi

   if [[ ! -z $1 &&  ! "$1" == "-h" && -z $2 ]]
   then
      MESSAGE="$MESSAGE\nERROR: target not specified"
   fi

   if [[ ! -z $MESSAGE ]]
   then
      tput setaf 1
      echo -e $MESSAGE
      tput sgr0
   fi

   cat << EOM

    Usage:  $0 [-h] <language|source configset> <collection name> [<mode>]

    Language must be an existing configuration in the solr.languages directory
    Alternatively a source configset must be the relative path to the conf directory containing schema.xml, solrconfig.xml etc,
      for example configsets/my-custom-conf/conf

    The optional <mode> is one of
    - "core" (default): creates a config(set) and initializes a core with it
    - "cloud" : creates a configset, uploads it to the SolrCloud Zookeeper instance and creates a collection with the same name
	- "configset" : creates a configset only in the configsets directory  
    - "cloud-config" :  creates a configset, uploads it to the SolrCloud Zookeeper instance for subsequent use
    - "core-config" : creates a regular core config in Solr Home
    - "core-update" : updates a core configuration, inclusing reloading the core

        
    Languages available:
EOM
    ls -d solr.languages/*/ | cut -f2 -d'/' | awk '{print "        " $1}'
    exit
elif [[ -d $1 ]]
then
     echo Using $1 as a custom source
     SOURCE_MODE='CUSTOM'
fi

if [[ -z $3 ]]
then
    MODE='core'
else
    MODE=$3
fi

echo Running in $MODE mode

# for core creation, must correspond to Solr configured "home"
# not used for cloud based collections
TARGET_DATA_DIR_ROOT='server/solr'

# where to store the created configsets
TARGET_CONFIGSET_ROOT='configsets/live'

ZK_HOST=127.0.0.1:9983
ZKCLI=server/scripts/cloud-scripts/zkcli.sh
CURL=curl

ZKHOST=127.0.0.1:9983
SOLRHOST=127.0.0.1:8983
CONFNAME=$2
LANGUAGE=$1
DEFAULT_SOURCE_CONFIGSET=configsets/templates/ezp-default
SOURCE_CONFIGSET=$DEFAULT_SOURCE_CONFIGSET

# Override config values 
if [[ -f config.in.sh ]]
then
   . config.in.sh
fi

# safe create dir, so can also be used to update

TARGET_CONFIGSET=$TARGET_CONFIGSET_ROOT/$CONFNAME
mkdir -p $TARGET_CONFIGSET

#First create a backup of custom files if needed
if [[ "$MODE" == "core-update" || "$MODE" == "cloud-update" ]]
then
    if [[ -f $TARGET_CONFIGSET/conf/custom-fields.xml ]]
    then
        cp $TARGET_CONFIGSET/conf/custom-fields.xml $TARGET_CONFIGSET/conf/custom-fields.xml-backup
    fi
fi


if [[ "$SOURCE_MODE" == "LANGUAGE" ]]
then
    cp -r $DEFAULT_SOURCE_CONFIGSET/* $TARGET_CONFIGSET
    cp -r solr.languages/$LANGUAGE/* $TARGET_CONFIGSET/conf
else
    SOURCE_CONFIGSET=$1
    cp -r $SOURCE_CONFIGSET/* $TARGET_CONFIGSET
fi


if [[ "$MODE" == "core-config" || "$MODE" == "core" ]]
then
    mkdir -p $TARGET_DATA_DIR_ROOT/$CONFNAME/conf
    cp -r $TARGET_CONFIGSET $TARGET_DATA_DIR_ROOT

fi

if [[ "$MODE" == "core-update" ]]
then

    if [[ -f $TARGET_CONFIGSET/conf/custom-fields.xml-backup ]]
    then
        cp $TARGET_CONFIGSET/conf/custom-fields.xml-backup $TARGET_CONFIGSET/conf/custom-fields.xml
    fi
    cp -r $TARGET_CONFIGSET $TARGET_DATA_DIR_ROOT
    echo "Reloading core  .."
    $CURL "http://$SOLRHOST/solr/admin/cores?action=RELOAD&core=$CONFNAME"


fi

if [[ "$MODE" == "core" ]]
then
    echo "Activating core  .."
    $CURL "http://$SOLRHOST/solr/admin/cores?action=CREATE&name=$CONFNAME"
fi


if [[ "$MODE" == "cloud" || "$MODE" == "cloud-config" ]]
then
    echo "Uploading $CONFNAME configuration set from $TARGET_CONFIGSET"
    $ZKCLI -cmd upconfig -zkhost $ZKHOST -confname $CONFNAME -confdir $TARGET_CONFIGSET
fi

if [[ "$MODE" == "cloud" ]]
then
    echo "Activating collection and core(s)  .."
    $CURL "http://$SOLRHOST/solr/admin/collections?action=CREATE&name=$CONFNAME&collection.configName=$CONFNAME&property.name=$CONFNAME&numShards=1"
fi
echo "IMPORTANT: make sure the collection/core definition for \"$2\" is also configured at the application level"

