# Configuración del backend de S3 (Este bloque debe estar al inicio de tu archivo)
terraform {
  backend "s3" {
    bucket = "aop-pagina-ia"            # Nombre del bucket de S3 que debes crear previamente
    key    = "terraform/terraform.tfstate"  # Ruta donde se almacenará el archivo de estado
    region = "us-east-1"                 # Región en la que se encuentra el bucket S3
  }
}

# Proveedor AWS
provider "aws" {
  region = var.region  # Asegúrate de que la variable `region` esté definida
}

# Crear el bucket de S3 para tu página estática
resource "aws_s3_bucket" "pagina_ia" {
  bucket = var.bucket_name  # Asegúrate de definir `bucket_name` como variable
  tags   = var.tags         # Asegúrate de que `tags` esté definida como variable
}

# Configuración del sitio web estático en el bucket S3
resource "aws_s3_bucket_website_configuration" "pagina_ia_website" {
  bucket = aws_s3_bucket.pagina_ia.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Configuración del bloque de acceso público al bucket (en caso de que no quieras bloquear acceso)
resource "aws_s3_bucket_public_access_block" "no_block_public_access" {
  bucket = aws_s3_bucket.pagina_ia.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Política de acceso al bucket para habilitar la lectura pública
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

# Subir el archivo index.html al bucket S3
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.pagina_ia.id
  key          = "index.html"
  source       = "${path.module}/../index.html"
  content_type = "text/html"
}

# Subir el archivo estilos.css al bucket S3
resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.pagina_ia.id
  key          = "estilos.css"
  source       = "${path.module}/../estilos.css"
  content_type = "text/css"
}

# Subir los archivos dentro de la carpeta assets al bucket S3
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

# Salidas del bucket y URL del sitio web
output "bucket_name" {
  value = aws_s3_bucket.pagina_ia.bucket
}

output "website_url" {
  value = aws_s3_bucket.pagina_ia.website_endpoint
}
