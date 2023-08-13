resource "aws_docdb_subnet_group" "example" {
  name       = "example"
  subnet_ids = aws_subnet.private.*.id  # Özel alt ağları belirtin
}

resource "aws_docdb_cluster" "example_cluster" {
  cluster_identifier           = "example-cluster"
  engine                       = "docdb"
  master_username              = "mydocdb"
  master_password              = "mypassword" # Güçlü bir şifre kullanın
  skip_final_snapshot         = true
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  vpc_security_group_ids      = [aws_security_group.example_sg.id]
  db_subnet_group_name        = aws_docdb_subnet_group.example.name  # aws_docdb_subnet_group kaynağının adını kullanın
  backup_retention_period     = 7
  preferred_backup_window     = "07:00-09:00"
  port                         = 27017
  storage_encrypted           = true
  tags = {
    Name = "example-docdb-cluster"
  }
}

# Amazon DocumentDB Güvenlik Grubu
resource "aws_security_group" "example_sg" {
  name        = "example_sg"
  description = "Example security group for DocumentDB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Dikkat: Genel ağ erişimi sağlar, prodüksiyon ortamlar için daha iyi bir yapılandırma düşünün
  }
}

