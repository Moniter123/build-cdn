#!/bin/bash

for i in $(find _site/assets -name '*.png'); do optipng $i; done