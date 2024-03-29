#!/usr/bin/bash

# Part number for the target development board
declare -r part_num=xc7a35ticsg324-1l
# Constraint file name (in current directory)
declare -r xdc=Arty-A7-35-Master.xdc

if [ $# -eq 0 ]
  then
    echo Error: project name not specified
    exit 1
fi
prj_dir=$PWD/$1
mkdir $prj_dir && cd $prj_dir
mkdir sim src out
cp -r ../scripts/* ./
cp -r ../scripts/.gitignore ./
rm -rf new.sh update.sh
cd sim
touch tb.sv
