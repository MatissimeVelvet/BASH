# 生成一个带时间戳的安全组名称，确保不与现有冲突
SG_NAME="m5xlarge-sg-$(date +%s)"

# 创建安全组，并将返回的 GroupId 保存到变量 SG_ID
SG_ID=$(aws ec2 create-security-group \
  --group-name "$SG_NAME" \
  --description "Open all inbound ports for m5.xlarge" \
  --query 'GroupId' \
  --output text)

echo "安全组已创建：$SG_NAME (GroupId=$SG_ID)"
