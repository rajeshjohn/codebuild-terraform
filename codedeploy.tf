resource "aws_s3_bucket" "codebuild-cache" {
  bucket = "rajesh-codebuild-cache"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.codebuild-cache.id
  acl    = "private"
}

resource "aws_codebuild_project" "codebuild-java-app-via-terraform" {
  name          = "codebuild-java-terraform"
  description   = "java_codebuild_project created via terraform"
  build_timeout = "5"
  service_role  = "arn:aws:iam::053883564770:role/service-role/codebuild-codebuild-java-application-service-role"


  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild-cache.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }

    environment_variable {
      name  = "SOME_KEY2"
      value = "SOME_VALUE2"
      type  = "PARAMETER_STORE"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild-cache.id}/build-log"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/rajeshjohn/codebuild-terraform.git"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "master"
}

resource "aws_iam_policy" "cloudlogstreampolicy" {
 name = "my-policy"

 policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "my-policy-attach" {
  role = "codebuild-codebuild-java-application-service-role"
  policy_arn = "${aws_iam_policy.cloudlogstreampolicy.arn}"
}