aws ec2 describe-images \
  --filters "Name=state,Values=available" \
  --query "sort_by(Images[?starts_with(CreationDate,'2025-07') && contains(PlatformDetails,'Linux')], &CreationDate)[] | [].[ImageId, Name, CreationDate, PlatformDetails]" \
  --output table
