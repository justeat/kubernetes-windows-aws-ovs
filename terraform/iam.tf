
resource "aws_iam_instance_profile" "bastion-nodes-profile" {
  name  = "${var.cluster-name}-bastion-nodes-profile"
  role = "${aws_iam_role.bastion-nodes-iam.name}"
}

resource "aws_iam_role" "bastion-nodes-iam" {
  name = "${var.cluster-name}-bastion-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "gateway-nodes-profile" {
  name  = "${var.cluster-name}-gateway-nodes-profile"
  role = "${aws_iam_role.gateway-nodes-iam.name}"
}

resource "aws_iam_role" "gateway-nodes-iam" {
  name = "${var.cluster-name}-gateway-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "gateway-profile" {
  name  = "${var.cluster-name}-gateway-profile"
  role = "${aws_iam_role.master-nodes-iam.name}"
}

resource "aws_iam_role_policy" "gateway-nodes_role_policy" {
  name = "s3-rw-state"
  role = "${aws_iam_role.gateway-nodes-iam.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Put*"
            ],
            "Resource": [
                "arn:aws:s3:::${var.cluster-name}-k8s-state/*",
                "arn:aws:s3:::${var.cluster-name}-k8s-state"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.cluster-name}-k8s-state"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "master-nodes-profile" {
  name  = "${var.cluster-name}-master-nodes-profile"
  role = "${aws_iam_role.master-nodes-iam.name}"
}

resource "aws_iam_role_policy" "master-nodes_role_policy" {
  name = "s3-rw-state"
  role = "${aws_iam_role.master-nodes-iam.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Put*"
            ],
            "Resource": [
                "arn:aws:s3:::${var.cluster-name}-k8s-state/*",
                "arn:aws:s3:::${var.cluster-name}-k8s-state"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::kubernetes-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:AttachVolume",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:DetachVolume",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.cluster-name}-k8s-state"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "master-nodes-iam" {
  name = "${var.cluster-name}-master-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nodes-profile" {
  name  = "${var.cluster-name}-nodes-profile"
  role = "${aws_iam_role.nodes-iam.name}"
}

resource "aws_iam_role_policy" "nodes_role_policy" {
  name = "s3-read-state"
  role = "${aws_iam_role.nodes-iam.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${var.cluster-name}-k8s-state/*",
                "arn:aws:s3:::${var.cluster-name}-k8s-state"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::kubernetes-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:AttachVolume",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:DetachVolume",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::venus.je-k8s-state"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}



resource "aws_iam_role" "nodes-iam" {
  name = "${var.cluster-name}-nodes-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "ecrproxy-iam" {
  name = "${var.cluster-name}-ecrproxy-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecrproxy-profile" {
  name  = "${var.cluster-name}-ecrproxy-profile"
  role = "${aws_iam_role.ecrproxy-iam.name}"
}


resource "aws_iam_role_policy" "ecrproxy_role_policy" {
  name = "ecr-read"
  role = "${aws_iam_role.ecrproxy-iam.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:GetRepositoryPolicy",
              "ecr:DescribeRepositories",
              "ecr:ListImages",
              "ecr:DescribeImages",
              "ecr:BatchGetImage"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}



