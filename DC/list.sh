aws ec2 describe-images \
  --owners amazon \
  --filters "Name=platform,Values=windows" "Name=state,Values=available" \
  --query 'Images | sort_by(@,&CreationDate) | [-1].{AMI_ID:ImageId,Name:Name,Date:CreationDate}' \
  --output text
