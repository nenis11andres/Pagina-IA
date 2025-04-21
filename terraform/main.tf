terraform {
  backend "s3" {
    bucket = var.bucket_name
    key    = "terraform/terraform.tfstate"
    region = var.region
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "pagina_ia" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_website_configuration" "pagina_ia_website" {
  bucket = aws_s3_bucket.pagina_ia.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "no_block_public_access" {
  bucket = aws_s3_bucket.pagina_ia.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.pagina_ia.id

  depends_on = [aws_s3_bucket_public_access_block.no_block_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.pagina_ia.arn}/*"
    }]
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.pagina_ia.id
  key          = "index.html"
  source       = "${path.module}/../index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.pagina_ia.id
  key          = "estilos.css"
  source       = "${path.module}/../estilos.css"
  content_type = "text/css"
}

resource "aws_s3_object" "assets" {
  for_each     = fileset("${path.module}/../assets", "**")
  bucket       = aws_s3_bucket.pagina_ia.id
  key          = "assets/${each.value}"
  source       = "${path.module}/../assets/${each.value}"
  content_type = lookup(
    {
      "png"  = "image/png"
      "jpg"  = "image/jpeg"
      "jpeg" = "image/jpeg"
      "svg"  = "image/svg+xml"
      "gif"  = "image/gif"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
}

output "bucket_name" {
  value = aws_s3_bucket.pagina_ia.bucket
}

output "website_url" {
  value = aws_s3_bucket.pagina_ia.website_endpoint
}
