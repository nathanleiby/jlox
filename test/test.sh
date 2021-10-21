#!/bin/bash
cmd='julia main.jl'

specdir='./test/specs'

had_error=0
for spec in `ls $specdir | grep .lox\$`; do
    diff <($cmd $specdir/$spec) <(cat $specdir/$spec.out)

    if [[ $? == "0" ]]; then
        echo "✅ $spec";
    else
        echo "❌ $spec";
        had_error=1
    fi
done

exit $had_error
