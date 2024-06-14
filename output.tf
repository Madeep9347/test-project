output "web_private_ip" {
  value = aws_instance.web.private_ip
}

output "db_private_ip" {
  value = aws_instance.db.private_ip
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

