#!/bin/bash

cssh $(dig +short all.cdn.opsbears.net|xargs -i echo -n 'ubuntu@{} ')
