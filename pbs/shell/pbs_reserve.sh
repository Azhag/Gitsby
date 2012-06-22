#!/bin/sh
# usage:
#   reserve [<memory>  [<cores> [<hours>] [<hostname>]]]
#       memory defaults to 2gb
#       cores defaults to 4
#       hours defaults to 1
#       hostname defaults to current machine
#  this reserves 2gb of memory, 4 cores for one hour on the current
#  machine.
mem=${1:-2gb}
cores=${2:-4}
hours=${3:-1}
host=${4:-`hostname`}
seconds=$((hours*60*60))
trap 'rm $tmp' INT QUIT TERM EXIT
tmp=`mktemp`
#host=`hostname`
cat <<EOF >$tmp
#PBS -l walltime=$hours:00:00,mem=$mem,pmem=$mem,nodes=ppn=$cores,host=$host
sleep $seconds
EOF
qsub $tmp
