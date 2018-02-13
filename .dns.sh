#!/bin/bash
aws route53 change-resource-record-sets --hosted-zone-id ZUHMK8NABN9AI --change-batch file://.dns.json