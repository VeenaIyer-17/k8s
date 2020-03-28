#!/usr/bin/env bash

if [[ $# != 2 ]]; then
    echo "Usage: $0 <merge file (supplied by script)> <file being edited (supplied by invoker of EDITOR)>"
    exit 1
fi

yq merge --inplace --overwrite $2 $1