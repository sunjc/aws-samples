#!/bin/bash

# 根据db-instance-identifier删除数据库，删除前先创建快照，并将db-snapshot-identifier保存在文件中
delete() {
  echo "deleting database $1 ..."
  snapshot_id="$1-$(date +%Y%m%d)"
  aws rds delete-db-instance --db-instance-identifier "$1" --no-skip-final-snapshot --final-db-snapshot-identifier "${snapshot_id}"
  echo "${snapshot_id}" > "$(dirname $0)/$1.snapshot.id"
}

# 从最近的快照恢复数据库，数据库配置从json文件读取，恢复成功后指定security group，并输出恢复日志到文件中
restore() {
  log_file="$(dirname $0)/restore.log"
  id_file="$(dirname $0)/$1.snapshot.id"
  snapshot_id=$(cat ${id_file})
  echo "Restore database $1 from snapshot ${snapshot_id}" | tee ${log_file}
  aws rds restore-db-instance-from-db-snapshot --db-snapshot-identifier "${snapshot_id}" --cli-input-json file://json/"$1".json | tee ${log_file}

  count=0
  while [[ "${count}" -le 0 ]]
  do
    echo "Creating database $1 ..."
    count=$(aws rds describe-db-instances --db-instance-identifier "$1" --query 'DBInstances[0].[DBInstanceStatus]' | grep -c available)
    sleep 5
  done

  echo "Modify database $1" | tee ${log_file}
  aws rds modify-db-instance --db-instance-identifier "$1" --vpc-security-group-ids $2 | tee ${log_file}
}

echo_usage() {
  echo "Usage: $0 [delete|restore] [args ...]"
  echo "Commands:"
  echo "delete [db-instance-identifier] Delete a DB instance"
  echo "restore [db-instance-identifier] [vpc-security-group-ids] Create a new DB instance from a DB snapshot"
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
  delete)
    delete "$2"
    ;;
  restore)
    restore "$2" "$3"
    ;;
  *)
    exit 1
    ;;
esac