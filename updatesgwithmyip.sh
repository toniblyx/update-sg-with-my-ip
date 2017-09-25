#!/bin/bash

# Script that gets current public IP and updates
# a given security group to allow SSH access
#
# Usage (simple mode):
# ./updatesgwithmyip.sh <sg-id>
# ie: ./updatesgwithmyip.sh sg-12345678

# Usage (advanced mode)

# Short option names (default on macOS).
# ./updatesgwithmyip -s <sg-id>
#                    -P <port-number>
#                    -f <family>
#                    -i <IPD server>
#                    -p <AWS profile>
#                    -r <AWS region>
#                    -n

# Long option names are available if you have GNU getopt
# ./updatesgwithmyip --security-group <sg-id>
#                    --port           <port-number>
#                    --family         <family>
#                    --ipd-server     <IPD server>
#                    --profile        <AWS profile>
#                    --region         <AWS region>
#                    --dry-run

# <sg-id> is mandatory and is the security group you wish to alter
#   e.g. sg-12345678
# All other options are optional
# <port-number>
#   if you are running SSH on another port than 22
#   default: 22
# <family>
#   perhaps you want to use this script for something other
#   than SSH, and want to set up udp connections.
#   default: 'tcp'
# <IPD server>
#   If you don't trust someone else's IPD server and install your own
#   default: 'ifconfig.co'
# <AWS profile>
#   AWS profile, if not using default
#   default: unset (aws CLI uses its default)
# <AWS region>
#   AWS region, if not using default
#   default: script assumes region us-east-1
#   default: unset (aws CLI uses its default)

# For EC2-Classic would be with --group-name instead, something like:
#
# aws ec2 authorize-security-group-ingress --group-name $1 \
# --protocol tcp --port 22 --cidr $my_public_ip/32

# To make the change automatically you may add it to your crontab,
# in linux or mac somethign like this (every hour o'clock):
# 0 * * * * /path/to/updatesgwithmyip.sh sg-12345678

declare -r DRY_RUN=0
declare -r REALLY_RUN=1

# Default IPD Server. For security you may wish to run your own.
declare -r DEFAULT_PORT='22'
declare -r DEFAULT_FAMILY='tcp'
declare -r DEFAULT_IPD_SERVER='ifconfig.co'
declare -r DEFAULT_REGION='us-east-1'
declare -r DEFAULT_DRY_RUN=${REALLY_RUN}

declare security_group port family ipd_server profile region dry_run other_args my_public_ip

if [ $# == 1 ]
then
  security_group=$1
else
  declare params
  getopt -T > /dev/null
  if [ $? -eq 4 ]
  then
    # GNU GetOpt
    params=$(getopt -o s:P:f:i:p:r:n --long security-group:,port:,family:,ipd-server:,profile:,region:,dry-run -n 'updatesgwithmyip' -- "$@")
    eval set -- "$params"
  else
    # Basic GetOpt
    params=$(getopt s:P:f:i:p:r:n $*)
    eval set -- "$params"
  fi

  while [ $# -gt 0 ]
  do
    case "$1" in
      -s|--security-group)
        security_group="$2"
        shift 2
        ;;
      -P|--port)
        port="$2"
        shift 2
        ;;
      -f|--family)
        family="$2"
        shift 2
        ;;
      -i|--ipd-server)
        ipd_server="$2"
        shift 2
        ;;
      -p|--profile)
        profile="$2"
        shift 2
        ;;
      -r|--region)
        region="$2"
        shift 2
        ;;
      -n|--dry-run)
        dry_run=${DRY_RUN}
        shift
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "Not implemented: $1" >&2
        exit 1
        ;;
      esac
  done
fi

: ${port:=${DEFAULT_PORT}}
: ${family:=${DEFAULT_FAMILY}}
: ${ipd_server:=${DEFAULT_IPD_SERVER}}
: ${dry_run:=${DEFAULT_DRY_RUN}}
: ${region:=${DEFAULT_REGION}}

get_ip () {
  my_public_ip=$(curl -s ${ipd_server})
  local retval=$?
  if [ ${retval} != 0 ]
  then
    echo '[ERROR] Failed to get IP address' >&2
    exit ${retval}
  fi
}

build_other_args () {
  [ ${dry_run} == ${DRY_RUN} ] && other_args+='--dry-run'
  [ ! -z "${profile}" ] && other_args+=" --profile ${profile}"
  [ ! -z "${region}" ] && other_args+=" --region ${region}"
}

remove_existing (){
  aws ec2 describe-security-groups \
  --group-id ${security_group} \
  --output text \
  --filters Name=ip-permission.from-port,Values=${port} \
  --query 'SecurityGroups[*].IpPermissions[*].IpRanges' \
  ${other_args} > ipcidrs.txt
  sort ipcidrs.txt | uniq > ips.txt
  for i in `cat ips.txt`;
    do aws ec2 revoke-security-group-ingress \
      --group-id ${security_group} \
      --protocol ${family} \
      --port ${port} \
      --cidr $i \
      ${other_args} >/dev/null 2>&1;
    done
  local retval=$?
  if [ ${retval} != 0 ]
  then
    echo '[ERROR] Failed to delete existing security group rule' >&2
    exit ${retval}
  fi
  rm -f ips.txt ipcidrs.txt
}
authorize () {
  aws ec2 authorize-security-group-ingress \
    --group-id ${security_group} \
    --protocol ${family} \
    --port ${port} \
    --cidr ${my_public_ip}/32 \
    ${other_args}
  local retval=$?
  if [ ${retval} != 0 ]
  then
    echo '[ERROR] Failed to update security group' >&2
    exit ${retval}
  fi
}

sanity_check () {
  if [ -z "${security_group}" ] || [ ${security_group} == '-s' ]
  then
    echo '[ERROR] No security group passed in' >&2
    exit 1
  fi
}

run () {
  echo "Verifying parameters..."
  sanity_check
  echo "Getting current IP..."
  get_ip
  build_other_args
  read -p "Remove existing rules (e.g. existing rules with different IPs)? y/n  " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
      remove_existing
  fi
  echo "Adding new rule for port ${port} with IP ${my_public_ip}"
  authorize
  echo "Finished."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run $*
