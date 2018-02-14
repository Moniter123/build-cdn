#!/bin/bash

set -e

for NODE in $(dig +short all.cdn.opsbears.net); do
    rsync -e "ssh" --rsync-path="sudo rsync" -avz --delete ./_site/ $NODE:/srv/www/pasztor.at/htdocs/ &
done
