#!/bin/bash


if [[ "$1" == "-h"  ||   ( -z $1  || -z $2 || ! -d solr.languages/$1) ]]
then
   tput setaf 1
   if [[  ! -z $1 &&  ! "$1" == "-h" &&  ! -d solr.languages/$1 ]] 
   then
      echo "ERROR: Language $1 does not exist"
   fi

   if [[ ! -z $1 &&  ! "$1" == "-h" && -z $2 ]]
   then
      echo "ERROR: target directory not specified"
   fi
   tput sgr0

   echo "Usage:  $0 [-h] <language> <collection name>"
   echo "Languages available:"
   ls -d solr.languages/*/ | cut -f2 -d'/'
   exit 
fi

TARGET_DATA_DIR='server/solr'

# Override config values 
if [[ -f config.in.sh ]]
then
   . config.in.sh
fi

# safe create dir, so can also be used to update

mkdir -p $TARGET_DATA_DIR/$2
cp -r configsets/ezp-default/conf $TARGET_DATA_DIR/$2
cp -r solr.languages/$1/* $TARGET_DATA_DIR/$2/conf


echo "IMPORTANT: make sure the core definition for \"$2\" is also configured at the application level"

