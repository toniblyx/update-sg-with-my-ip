#!/bin/bash

# Script to that gets my current public IP and updates 
# a given security group to allow SSH access
# 
# Usage:
# ./updatesgwithmyip.sh <sg-id>
# ie: ./updatesgwithmyip.sh sg-12345678

MY_PUBLIC_IP=$(curl -s ifconfig.co)

aws ec2 authorize-security-group-ingress --group-id $1 \
--protocol tcp --port 22 --cidr $MY_PUBLIC_IP/32

# For EC2-Classic would be with --group-name instead, something like:
#
# aws ec2 authorize-security-group-ingress --group-name $1 \
# --protocol tcp --port 22 --cidr $MY_PUBLIC_IP/32

# To make the change automatically you may add it to your crontab,
# in linux or mac somethign like this (every hour o'clock):
# 0 * * * * /path/to/updatesgwithmyip.sh sg-12345678
