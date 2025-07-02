aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].{
    InstanceId: InstanceId,
    Name: (Tags[?Key==`Name`] | [0].Value),
    State: State.Name,
    Type: InstanceType,
    ImageId: ImageId,
    PublicIPv4: PublicIpAddress
  }' \
  --output table
