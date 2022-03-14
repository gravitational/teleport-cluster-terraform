resource "aws_kms_grant" "proxy_acm" {
  name              = "teleport_proxy_acm"
  count             = var.ami_kms_key_arn != "" ? 1 : 0
  key_id            = var.ami_kms_key_arn
  grantee_principal = aws_autoscaling_group.proxy_acm[0].service_linked_role_arn
  operations        = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "DescribeKey", "CreateGrant"]
  retire_on_delete  = false
}
