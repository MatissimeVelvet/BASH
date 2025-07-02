# 放通所有 IPv4 入站流量
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol -1 \
  --cidr 0.0.0.0/0

# 放通所有 IPv6 入站流量
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol -1 \
  --cidr ::/0
