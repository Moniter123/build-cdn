#!/bin/bash
aws route53 change-resource-record-sets --hosted-zone-id XXXXXX --change-batch file://.dns.json