aws ec2 describe-images \
  --owners 136693071363 \
  --filters "Name=name,Values=debian-12-amd64-*" "Name=state,Values=available" \
  --query 'Images | sort_by(@,&CreationDate) | [-1].{AMI_ID:ImageId,Name:Name,Date:CreationDate}' \
  --output text
