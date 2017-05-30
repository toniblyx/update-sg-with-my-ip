# updatesgwithmyip
Shell script to update an AWS Security Group (VPC) with your public IP, helpful to change SSH access for example and not to have a SG open to the world if you have a dynamic public IP.

Usage:
```
./updatesgwithmyip.sh <sg-id>
```
ie: ./updatesgwithmyip.sh sg-12345678

For EC2-Classic would be with --group-name instead, something like:
```
aws ec2 authorize-security-group-ingress --group-name $1 --protocol tcp --port 22 --cidr $MY_PUBLIC_IP/32
```

To make the change automatically you may add it to your crontab, in linux or mac somethign like this (every hour o'clock):
```
0 * * * * /path/to/updatesgwithmyip.sh sg-12345678
```
