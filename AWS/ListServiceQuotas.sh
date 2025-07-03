aws service-quotas list-service-quotas \
  --service-code ec2 \
  --query "Quotas[?contains(QuotaName,'Running On-Demand Standard')].[QuotaName,QuotaCode,Value]" \
  --output table
