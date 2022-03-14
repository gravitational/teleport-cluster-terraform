resource "aws_kms_grant" "auth" {
  name              = "teleport_auth"
  count             = var.ami_kms_key_arn != "" ? 1 : 0
  key_id            = var.ami_kms_key_arn
  grantee_principal = aws_autoscaling_group.auth.service_linked_role_arn
  operations        = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "DescribeKey", "CreateGrant"]
  retire_on_delete  = false
}
