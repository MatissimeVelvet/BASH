aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol -1 \
  --cidr 0.0.0.0/0
