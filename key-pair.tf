# Create a new key pair
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "totaleto-key"
  public_key = tls_private_key.this.public_key_openssh
}

# Output the private key (Be careful with this in production environments)
output "private_key" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}