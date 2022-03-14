resource "aws_kms_grant" "node" {
  name              = "teleport_node"
  count             = var.ami_kms_key_arn != "" ? 1 : 0
  key_id            = var.ami_kms_key_arn
  grantee_principal = aws_autoscaling_group.node.service_linked_role_arn
  operations        = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "DescribeKey", "CreateGrant"]
  retire_on_delete  = false
}
