terraform {
  backend "s3" {
    bucket         = "aop-pagina-ia"      # El mismo bucket del backend
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

# Referencia al bucket creado en backend.tf
resource "aws_s3_bucket" "pagina_ia" {
  bucket = var.bucket_name  # Este nombre debe coincidir con el que usas en el backend
  tags   = var.tags
}

# Configuración de la página web estática en el bucket
resource "aws_s3_bucket_website_configuration" "pagina_ia_website" {
  bucket = aws_s3_bucket.pagina_ia.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Política de acceso público para permitir la lectura de los objetos del bucket
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.pagina_ia.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.pagina_ia.arn}/*"
      }
    ]
  })
}

# Subir el archivo index.html al bucket
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.pagina_ia.id
  key          = "index.html"
  source       = "${path.module}/../index.html"
  content_type = "text/html"
}

# Subir el archivo estilos.css al bucket
resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.pagina_ia.id
  key          = "estilos.css"
  source       = "${path.module}/../estilos.css"
  content_type = "text/css"
}

# Subir todos los archivos dentro de la carpeta assets al bucket
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

# Outputs para el nombre del bucket y la URL del sitio web
output "bucket_name" {
  value = aws_s3_bucket.pagina_ia.bucket
}

output "website_url" {
  value = aws_s3_bucket.pagina_ia.website_endpoint
}
