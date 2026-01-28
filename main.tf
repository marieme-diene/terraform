# 1. Création du Bucket
resource "aws_s3_bucket" "site" {
  bucket        = var.website_bucket_name
  force_destroy = true
}

# 2. Configurer le bucket en mode Site Web
resource "aws_s3_bucket_website_configuration" "site_config" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }
}

# 3. Désactiver le blocage public (Ouvrir les vannes)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 4. Politique de sécurité (Autoriser tout le monde à lire)
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
      },
    ]
  })
}

# 5. Upload de TOUT le dossier site/ (index.html + styles.css + app.js + images...)
locals {
  site_dir   = "${path.module}/site"
  site_files = fileset(local.site_dir, "**/*")

  content_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
    txt  = "text/plain"
  }
}

resource "aws_s3_object" "site_files" {
  for_each = local.site_files

  bucket = aws_s3_bucket.site.id
  key    = each.value
  source = "${local.site_dir}/${each.value}"
  etag   = filemd5("${local.site_dir}/${each.value}")

  # Définir le bon Content-Type selon l'extension (sinon fallback)
  content_type = lookup(
    local.content_types,
    lower(element(split(".", each.value), length(split(".", each.value)) - 1)),
    "binary/octet-stream"
  )

  depends_on = [aws_s3_bucket_policy.public_read]
}