#!/bin/bash

NODES=$(dig +short all.cdn.opsbears.net)

for NODE in ${NODES}; do
    rsync -e "ssh -p 2222" -avz ./_site/ "ubuntu@${NODE}:/srv/www/pasztor.at/htdocs/"
done
