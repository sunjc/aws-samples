#!/bin/bash

. $(dirname $0)/common.sh

# 当EC2 Instance CPU利用率超过90%时发送邮件告警
cpu() {
  instance_name=$1
  sns_topic_arn=$2

  instance_id=$(query_instance_id_by_name "${instance_name}")

  aws cloudwatch put-metric-alarm --alarm-name "cpu-${instance_name}" --alarm-description "Alarm when CPU exceeds 90 percent" --metric-name CPUUtilization \
  --namespace AWS/EC2 --statistic Average --period 300 --threshold 90 --comparison-operator GreaterThanThreshold \
  --dimensions "Name=InstanceId,Value=${instance_id}" --evaluation-periods 2 --unit Percent --alarm-actions $2
}

echo_usage() {
  echo "Usage: $0 [cpu] [instance_name] [sns_topic_arn]"
}

if test @$1 = @--help -o @$1 = @-h; then
  echo_usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  echo_usage
  exit 1
fi

case "$1" in
  "cpu")
    cpu "$2" "$3"
    ;;
  *)
    exit 1
    ;;
esac

