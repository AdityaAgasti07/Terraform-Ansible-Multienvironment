resource "aws_s3_bucket" "my_bucket" {
  bucket = "${var.env}-aditya-junoon-app-bucket"
  tags = {
    Name = "${var.env}-aditya-junoon-app-bucket"
    Environment = var.env
  }
}