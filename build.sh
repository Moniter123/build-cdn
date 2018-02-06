#!/bin/bash

JEYKLL_ENV=prod bundle exec jekyll build
#for i in $(find _site/assets -name '*.png'); do optipng $i; done
rsync -e "ssh -p 2222" -avz ./_site/ pasztor.at@smallwebs.opsbears.net:/var/www/pasztor.at/htdocs/
