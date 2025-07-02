# 生成安全组名称（带时间戳保证唯一）
SG_NAME="debian12-sg-$(date +%s)"

# 创建安全组并获取其 GroupId
SG_ID=$(aws ec2 create-security-group \
  --group-name "$SG_NAME" \
  --description "Allow all inbound IPv4/IPv6" \
  --query 'GroupId' \
  --output text)

echo "安全组创建成功，GroupId: $SG_ID"
