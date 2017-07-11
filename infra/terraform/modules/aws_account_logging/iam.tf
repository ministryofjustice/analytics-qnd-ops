data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
        actions = ["sts:AssumeRole"]
        effect = "Allow"
        principals = {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}


# Role assumed by the 'ship_s3_logs_to_elasticsearch' lambda function
resource "aws_iam_role" "s3_logs_to_elasticsearch" {
    name = "s3_logs_to_elasticsearch"
    assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role.json}"
}

# Policies for the 'ship_s3_logs_to_elasticsearch' role
resource "aws_iam_role_policy" "s3_logs_to_elasticsearch" {
    name = "s3_logs_to_elasticsearch"
    role = "${aws_iam_role.s3_logs_to_elasticsearch.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": "logs:CreateLogGroup",
          "Resource": "arn:aws:logs:::*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
          ],
          "Resource": [
              "arn:aws:logs:::log-group:/aws/lambda/s3_logs_to_elasticsearch:*"
          ]
      },
  {
    "Sid": "Stmt1499439833532",
    "Action": [
      "s3:ListBucket"
    ],
    "Effect": "Allow",
    "Resource": "${aws_s3_bucket.s3_logs.arn}"
  },
  {
    "Sid": "Stmt1499439848123",
    "Action": [
      "s3:GetObject"
    ],
    "Effect": "Allow",
    "Resource": "${aws_s3_bucket.s3_logs.arn}"
  }
  ]
}
EOF
}
