#!/usr/bin/bash

if [ $# -eq 0 ]
  then
    echo Error: project name not specified
    exit 1
fi
prj_dir=$PWD/$1
cp -r ./scripts/* $prj_dir
cp -r ./scripts/.gitignore $prj_dir
rm -rf $prj_dir/new.sh $prj_dir/update.sh
