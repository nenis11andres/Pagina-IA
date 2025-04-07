variable "bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
  default     = "aop-pagina-ia"
}

variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Etiquetas del bucket"
  type        = map(string)
  default     = {
    Name = "Web IA"
  }
}
