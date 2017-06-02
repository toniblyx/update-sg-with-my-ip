# updatesgwithmyip
Shell script to update an AWS Security Group (VPC) with your public IP, helpful to change SSH access for example and not to have a SG open to the world if you have a dynamic public IP.

### Usage (simple mode):
```
./updatesgwithmyip.sh <sg-id>
```
e.g.: `./updatesgwithmyip.sh sg-12345678`

### Usage (advanced mode)

Short option names (default on macOS).
```
./updatesgwithmyip -s <sg-id>
                   -P <port-number>
                   -f <family>
                   -i <IPD server>
                   -p <AWS profile>
                   -r <AWS region>
                   -n
```

Long option names are available if you have GNU getopt
```
./updatesgwithmyip --security-group <sg-id>
                   --port           <port-number>
                   --family         <family>
                   --ipd-server     <IPD server>
                   --profile        <AWS profile>
                   --region         <AWS region>
                   --dry-run
```

For EC2-Classic would be with --group-name instead, something like:
```
aws ec2 authorize-security-group-ingress --group-name $1 --protocol tcp --port 22 --cidr $MY_PUBLIC_IP/32
```

* `<sg-id>` is mandatory and is the security group you wish to alter
e.g. `sg-12345678`

All other arguments are optional:

* `<port-number>`
  if you are running SSH on another port than 22
  default: `22`
* `<family>` perhaps you want to use this script for something other
  than SSH, and want to set up udp connections.
  default: `tcp`
* `<IPD server>`
  If you don't trust someone else's IPD server and install your own
  default: `ifconfig.co`
* `<AWS profile>`
  AWS profile, if not using default
  default: `unset` (aws CLI uses its default)
* `<AWS region>`
  AWS region, if not using default
  default: `unset` (aws CLI uses its default)

To make the change automatically you may add it to your crontab, in linux or mac something like this (every hour o'clock):
```
0 * * * * /path/to/updatesgwithmyip.sh sg-12345678
```
