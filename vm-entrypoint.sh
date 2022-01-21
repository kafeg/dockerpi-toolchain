#!/bin/sh

set -x

env

sed -i 's/\${new_size_in_gib}/4/g' /entrypoint.sh

/entrypoint.sh ${1}
