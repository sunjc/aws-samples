#!/bin/bash

. $(dirname $0)/common.sh

# 根据Instance Name创建image并添加标签
create_image() {
  instance_name=$1
  image_name=$2
  tags=$3
  echo "Create image for instance ${instance_name}"

  instance_id=$(query_instance_id_by_name "${instance_name}")
  image_id=$(aws ec2 create-image --instance-id "${instance_id}" --name "${image_name}" --description "${image_name}" --no-reboot --query ImageId)
  image_id=${image_id//\"/}
  echo "ImageId: $image_id"

  create_tags_with_name "${image_id}" "${image_name}" "${tags}"
}

# 删除AMI
delete_image() {
  image_name=$1
  echo "Delete image ${image_name}"

  image_id=$(query_image_id_by_name "${image_name}")
  echo "Image id: ${image_id}"

  echo "Deregister image $image_id"
  aws ec2 deregister-image --image-id "${image_id}"

  snapshot_ids=$(query_snapshot_ids_by_image_id "${image_id}")

  for snapshot_id in ${snapshot_ids}
  do
    echo "Delete snapshot ${snapshot_id}"
    aws ec2 delete-snapshot --snapshot-id "${snapshot_id}"
  done
  echo
}

# 根据Name启动EC2 Instance
start_instance() {
  id=$(query_instance_id_by_name "$1")
  aws ec2 start-instances --instance-ids ${id}
}

# 根据类别启动EC2 Instance
start_instances() {
  ids=$(query_instance_ids_by_category "$1")
  aws ec2 start-instances --instance-ids ${ids}
}

# 根据Name停止EC2 Instance
stop_instance() {
  id=$(query_instance_id_by_name "$1")
  aws ec2 stop-instances --instance-ids ${id}
}

# 根据类别停止EC2 Instance
stop_instances() {
  ids=$(query_instance_ids_by_category "$1")
  aws ec2 stop-instances --instance-ids ${ids}
}

# 根据Name重启EC2 Instance
reboot_instance() {
  id=$(query_instance_id_by_name "$1")
  aws ec2 reboot-instances --instance-ids ${id}
}

# 根据类别重启EC2 Instance
reboot_instances() {
  ids=$(query_instance_ids_by_category "$1")
  aws ec2 reboot-instances --instance-ids ${ids}
}

# 根据Name终止EC2 Instance
terminate_instance() {
  id=$(query_instance_id_by_name "$1")
  echo "terminate instance, instance name: $1 instance id: ${id}"

  aws ec2 modify-instance-attribute --instance-id "${id}" --no-disable-api-termination
  aws ec2 terminate-instances --instance-ids ${id}
  echo
}

# 根据类别终止EC2 Instance
terminate_instances() {
  ids=$(query_instance_ids_by_category "$1")
  echo "terminate instances, category: $1 instance-ids: ${ids}"

  for id in ${ids}
  do
    aws ec2 modify-instance-attribute --instance-id "${id}" --no-disable-api-termination
  done
  aws ec2 terminate-instances --instance-ids ${ids}
  echo
}

# 从Image创建EC2 Instance，EC2配置从JSON文件读取，可以附加一个Volume，可以使用用户数据文件，可以添加标签
run_instance() {
  instance_name=$1
  image_name=$2
  device_snapshot_name=$3
  init_file=$4
  tags=$5

  block_device_mappings=" "

  if [[ "${device_snapshot_name}" ]]; then
    snapshot_id=$(query_snapshot_id_by_name "${device_snapshot_name}")
    if [[ "${snapshot_id}" ]]; then
      block_device_mappings="--block-device-mappings DeviceName=/dev/sdf,Ebs={SnapshotId=${snapshot_id},DeleteOnTermination=true,VolumeType=gp2}"
    else
      echo "Please provide a valid volume snapshot name"
      exit 1
    fi
  fi

  echo "Create EC2 instance ${instance_name} from image ${image_name}"
  image_id=$(query_image_id_by_name "${image_name}")

  if [[ "$init_file" ]]; then
    instance_id=$(aws ec2 run-instances --image-id "${image_id}" ${block_device_mappings} --cli-input-json file://json/"${instance_name}".json \
                --user-data file://"${init_file}" --query 'Instances[0].[InstanceId]' | grep -o -E "${INSTANCE_ID_REGEX}")
  else
    instance_id=$(aws ec2 run-instances --image-id "${image_id}" ${block_device_mappings} --cli-input-json file://json/"${instance_name}".json \
                --query 'Instances[0].[InstanceId]' | grep -o -E "${INSTANCE_ID_REGEX}")
  fi

  create_tags_with_name "${instance_id}" "${instance_name}" "${tags}"
}

# 为EC2 Instance的指定卷创建快照并删除以前同名快照
create_snapshot() {
  instance_name=$1
  device=$2
  snapshot_name=$3
  tags=$4

  instance_id=$(query_instance_id_by_name "${instance_name}")

  delete_snapshot "${snapshot_name}"

  volume_id=$(query_volume_id_by_instance_id_and_device ${instance_id} ${device})
  if [[ "${volume_id}" ]]; then
    echo "create snapshot for volume: ${device} of instance ${instance_name}"
    snapshot_id=$(aws ec2 create-snapshot --volume-id ${volume_id} | grep -o -E "${SNAPSHOT_ID_REGEX}")

    create_tags_with_name "${snapshot_id}" "${snapshot_name}" "${tags}"
  fi
}

# 根据名称删除快照
delete_snapshot() {
  snapshot_id=$(query_snapshot_id_by_name "$1")
  if [[ "${snapshot_id}" ]]; then
    echo "delete snapshot: $1"
    aws ec2 delete-snapshot --snapshot-id ${snapshot_id}
  fi
}

# 从快照创建卷并删除旧的重名卷，然后将卷连接到Instance的指定device
attach_volume() {
  snapshot_name=$1
  instance_name=$2
  device=$3
  tags=$4

  availability_zone="cn-north-1a"
  volume_name="$1-1a"

  snapshot_id=$(query_snapshot_id_by_name ${snapshot_name})
  instance_id=$(query_instance_id_by_name ${instance_name})

  if [[ -z "${snapshot_id}" ]]; then
    echo "Please provide valid snapshot name"
    exit 1
  fi

  if [[ -z "${instance_id}" ]]; then
    echo "Please provide valid instance name"
    exit 1
  fi

  old_volume_ids=$(query_volume_ids_by_name "${volume_name}")
  for id in ${old_volume_ids}
  do
    echo "delete old volume: $id"
    aws ec2 delete-volume --volume-id ${id}
  done

  echo "create volume ${volume_name} from snapshot ${snapshot_name}(${snapshot_id})"
  volume_id=$(aws ec2 create-volume --snapshot-id ${snapshot_id} --availability-zone ${availability_zone} --volume-type gp2 --query 'VolumeId' \
            | grep -o -E "${VOLUME_ID_REGEX}")

  count=0
  while [[ "${count}" -le 0 ]]
  do
    echo "Creating volume ${volume_name} ..."
    count=$(aws ec2 describe-volumes --volume-ids ${volume_id} --query Volumes[0].State | grep -c available)
    sleep 3
  done

  echo "attach volume: ${volume_name} to instance ${instance_name}"
  aws ec2 attach-volume --volume-id ${volume_id} --instance-id ${instance_id} --device ${device}

  create_tags_with_name "${volume_id}" "${volume_name}" "${tags}"
}

echo_usage() {
  echo "Usage: $0 [command] [args ...]"
  echo "Commands:"
  echo "create-image [instance_name] [image_name] [tags] Create an AMI from an EC2 instance"
  echo "delete-image [image_name] Delete image by name"
  echo "start-instance [instance_name] Start an EC2 instance"
  echo "start-instances [category_name] Start EC2 instances by category"
  echo "stop-instance [instance_name] Stop an EC2 instance"
  echo "stop-instances [category_name] Stop EC2 instances by category"
  echo "reboot-instance [instance_name] Reboot an EC2 instance"
  echo "reboot-instances [category_name] Reboot EC2 instances by category"
  echo "terminate-instance [instance_name] Terminate an EC2 instance"
  echo "terminate-instances [category_name] Terminate EC2 instances by category"
  echo "run-instance [instance_name] [image_name] [options] Launch an instance using an AMI"
  echo "    Options:"
  echo "    --device-snapshot-name One block device snapshot name"
  echo "    --init-file an user data file"
  echo "    --tags One  or more tags"
  echo "create-snapshot [instance_name] [device] [snapshot_name] [tags] Creates a snapshot of the specified volume for an instance"
  echo "delete-snapshot [snapshot_name] Deletes the specified snapshot"
  echo "attach-volume [snapshot_name] [instance_name] [device] [tags] Create a volume from a snapshot, and then attach the volume to an instance"
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
  create-image)
    create_image "$2" "$3" "$4"
    ;;
  delete-image)
    delete_image "$2"
    ;;
  start-instance)
    start_instance "$2"
    ;;
  start-instances)
    start_instances "$2"
    ;;
  stop-instance)
    stop_instance "$2"
    ;;
  stop-instances)
    stop_instances "$2"
    ;;
  reboot-instance)
    reboot_instance "$2"
    ;;
  reboot-instances)
    reboot_instances "$2"
    ;;
  terminate-instance)
    terminate_instance "$2"
    ;;
  terminate-instances)
    terminate_instances "$2"
    ;;
  run-instance)
    args=`getopt -l init-file:,device-snapshot-name:,tags: -- "$@"`
    if [[ $? != 0 ]] ; then
     exit 1
    fi

    device_snapshot_name=""
    init_file=""
    tags=""

    eval set -- "${args}"
    while true
    do
    case "$1" in
      --device-snapshot-name)
        device_snapshot_name="$2"
        shift 2
        ;;
      --init-file)
        init_file="$2"
        shift 2
        ;;
      --tags)
        tags="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
    esac
    done

    run_instance "$2" "$3" "${device_snapshot_name}" "${init_file}" "${tags}"
    ;;
  create-snapshot)
    create_snapshot "$2" "$3" "$4" "$5"
    ;;
  delete-snapshot)
    delete_snapshot "$2"
    ;;
  attach-volume)
    attach_volume "$2" "$3" "$4" "$5"
    ;;
  *)
    exit 1
    ;;
esac