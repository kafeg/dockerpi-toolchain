#!/bin/sh

sed -i 's/\${new_size_in_gib}/4/g' /entrypoint.sh

/entrypoint.sh