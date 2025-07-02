INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-066ed77ed0a1751b2 \
  --count 1 \
  --instance-type t3.large \
  --security-group-ids "$SG_ID" \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":200,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
  --user-data file://user-data.yml \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "实例正在启动，InstanceId=$INSTANCE_ID"
