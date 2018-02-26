#!/bin/bash

for i in $(find assets -name '*.png'); do optipng $i; done
for i in $(find _site/assets -name '*.png'); do optipng $i; done
