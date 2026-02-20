resource "aws_iam_role" "amplify" {
  name = "amplify-abi86-giganten"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "amplify.amazonaws.com",
          "codebuild.amazonaws.com"
        ]
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "amplify_backend" {
  role       = aws_iam_role.amplify.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
}

resource "aws_amplify_app" "hugo_site" {
  name         = "abi86-giganten"
  repository   = "https://github.com/megaproaktiv/abi86-giganten"
  access_token = var.github_token
  iam_service_role_arn = aws_iam_role.amplify.arn

  depends_on = [aws_iam_role_policy_attachment.amplify_backend]

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - wget https://github.com/gohugoio/hugo/releases/download/v0.121.0/hugo_extended_0.121.0_Linux-64bit.tar.gz
            - tar -xf hugo_extended_0.121.0_Linux-64bit.tar.gz
            - mv hugo /usr/bin/hugo
            - chmod +x /usr/bin/hugo
        build:
          commands:
            - cd abi86-giganten.de
            - hugo
      artifacts:
        baseDirectory: abi86-giganten.de/public
        files:
          - '**/*'
      cache:
        paths: []
  EOT

  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.hugo_site.id
  branch_name = "main"
}

resource "aws_amplify_domain_association" "domain" {
  app_id      = aws_amplify_app.hugo_site.id
  domain_name = "abi86-giganten.de"

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }
}

output "amplify_app_id" {
  value = aws_amplify_app.hugo_site.id
}

output "amplify_default_domain" {
  value = aws_amplify_app.hugo_site.default_domain
}
