#!/bin/bash
cmd='julia main.jl'

specdir='./test/specs'

for spec in `ls $specdir | grep .lox\$`; do
    diff <($cmd $specdir/$spec) <(cat $specdir/$spec.out)

    if [[ $? == "0" ]]; then
        echo "✅ $spec";
        exit 0;
    else
        echo "❌ $spec";
        exit 1;
    fi
done
