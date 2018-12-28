#!/bin/bash

INSTANCE_ID_REGEX="i-\w{8,17}"
IMAGE_ID_REGEX="ami-\w{8,17}"
VOLUME_ID_REGEX="vol-\w{8,17}"
SNAPSHOT_ID_REGEX="snap-\w{8,17}"
ROUTETABLE_ID_REGEX="rtb-\w{8,17}"

query_instance_id_by_name() {
  instance_id=$(aws ec2 describe-instances --filter Name=tag:Name,Values="$1" Name=instance-state-name,Values=pending,running,stopped \
              --query 'Reservations[0].[Instances[0].InstanceId]' | grep -o -E "$INSTANCE_ID_REGEX")
  echo ${instance_id}
}

query_instance_ids_by_category() {
  instance_ids=$(aws ec2 describe-instances --filter Name=tag:Category,Values="$1" Name=instance-state-name,Values=pending,running,stopped \
               --query 'Reservations[*].[Instances[*].InstanceId]' | grep -o -E "$INSTANCE_ID_REGEX")
  echo ${instance_ids}
}

wait_instance_ok() {
  instance_id=$(aws ec2 describe-instances --filter Name=tag:Name,Values="$1" Name=instance-state-name,Values=pending,running \
              --query 'Reservations[0].[Instances[0].InstanceId]' | grep -o -E "$INSTANCE_ID_REGEX")
  check_instance_status ${instance_id}
}

check_instance_status() {
  while true
  do
    ok_count=$(aws ec2 describe-instance-status --instance-id $1 | grep -c ok)
    if [[ "$ok_count" -eq 2 ]]; then
      break
    else
      echo "Waiting ..."
      sleep 5
    fi
  done
}

describe_running_instances() {
  instances=$(aws ec2 describe-instances --filter Name=instance-state-name,Values=running \
            --query 'Reservations[*].Instances[*].{State:State.Name,Ip:PrivateIpAddress,InstanceId:InstanceId,Name:Tags[0].Value}')
  echo ${instances}
}

query_image_id_by_name() {
  image_id=$(aws ec2 describe-images --filter Name=name,Values="$1" --query Images[0].[ImageId] | grep -o -E "$IMAGE_ID_REGEX")
  echo ${image_id}
}

query_volume_id_by_name() {
  id=$(aws ec2 describe-volumes --filter Name=tag:Name,Values="$1" --query Volumes[0].[VolumeId] | grep -o -E "$VOLUME_ID_REGEX")
  echo ${id}
}

query_volume_ids_by_name() {
  id=$(aws ec2 describe-volumes --filter Name=tag:Name,Values="$1" --query Volumes[*].[VolumeId] | grep -o -E "$VOLUME_ID_REGEX")
  echo ${id}
}

query_volume_id_by_instance_id_and_device() {
  id=$(aws ec2 describe-volumes --filter Name=attachment.instance-id,Values="$1" Name=attachment.device,Values=$2 \
     --query Volumes[0].[VolumeId] | grep -o -E "$VOLUME_ID_REGEX")
  echo ${id}
}

query_snapshot_id_by_name() {
  snapshot_id=$(aws ec2 describe-snapshots --filter Name=tag:Name,Values="$1" --query Snapshots[0].[SnapshotId] | grep -o -E "$SNAPSHOT_ID_REGEX")
  echo ${snapshot_id}
}

query_snapshot_ids_by_image_id() {
  snapshot_ids=$(aws ec2 describe-snapshots --query Snapshots[*].[SnapshotId][*] --filter Name=description,Values=*"$1"* | grep -o -E "$SNAPSHOT_ID_REGEX")
  echo ${snapshot_ids}
}

query_route_table_id_by_name() {
  id=$(aws ec2 describe-route-tables --filter Name=tag:Name,Values="$1" --query RouteTables[0].RouteTableId | grep -o -E "$ROUTETABLE_ID_REGEX")
  echo ${id}
}

query_elb_instance_ids() {
  ids=$(aws elb describe-load-balancers --load-balancer-name "$1" --query LoadBalancerDescriptions[0].[Instances[*].[InstanceId]] | grep -o -E "$INSTANCE_ID_REGEX")
  echo ${ids}
}

create_tags_with_name() {
  resource_id=$1
  name=$2
  tags=$3;

  if [[ -z ${resource_id} ]]; then
    return 1
  fi

  if [[ ${tags} ]]; then
    echo "Add tags: ${tags}"
  fi

  aws ec2 create-tags --resources ${resource_id} --tags Key=Name,Value="${name}" ${tags}
  echo
}