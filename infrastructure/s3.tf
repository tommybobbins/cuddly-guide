# S3 bucket for website.
resource "aws_s3_bucket" "www" {
  bucket = "www.${var.domain_name}"
  tags   = var.common_tags
  policy = templatefile("templates/s3-policy.json", { bucket = "www.${var.domain_name}" })

}

# Add bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "www_encryption" {
  bucket = aws_s3_bucket.www.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "www" {
  bucket = aws_s3_bucket.www.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "www_cors" {
  bucket = aws_s3_bucket.www.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://www.${var.domain_name}"]
    expose_headers  = ["ETag"]
  }
}

resource "aws_s3_bucket" "root" {
  bucket = var.domain_name
  policy = templatefile("templates/s3-policy.json", { bucket = var.domain_name })
}

# Add bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "root_encryption" {
  bucket = aws_s3_bucket.root.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}


# S3 bucket for redirecting non-www to www.
resource "aws_s3_bucket_acl" "root" {
  bucket = aws_s3_bucket.root.id
  acl    = "public-read"
}


resource "aws_s3_bucket_website_configuration" "root" {
  bucket = aws_s3_bucket.root.id

  redirect_all_requests_to {
    host_name = "www.${var.domain_name}"
  }
}

# Upload content
#resource "null_resource" "remove_and_upload_to_s3" {
#  provisioner "local-exec" {
#    command = "aws s3 sync --metadata-directive REPLACE --cache-control 'max-age=86400, public' ${var.site_content} s3://${aws_s3_bucket.www.bucket}"
#  }
#}
