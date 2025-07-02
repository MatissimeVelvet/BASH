# 5.1 启动实例并保存 InstanceId
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-017d0d06edcce9d38 \
  --count 1 \
  --instance-type m5.xlarge \
  --security-group-ids "$SG_ID" \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":777,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
  --user-data file://windows-user-data.ps1 \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "实例正在启动，InstanceId=$INSTANCE_ID"
