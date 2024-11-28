# AWS 리전
provider "aws" {
  region = "eu-central-1"
}

# VPC
variable "vpc_id" {
  default = "vpc-0f9890e23819167c7"
}

# 보안 그룹
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "sg" {
  name = "saju-api-sg-dev"
  description = "saju api sg dev"
  vpc_id = var.vpc_id
 
  # 인바운드 규칙
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "APP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 규칙
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "saju-api-sg-dev"
    Service = "saju-dev"
  }
}

# EC2 리소스 만들자
# 리전별로 ami 이름이 다르다 -> EC2 생성할때 나오는 화면에서 Amazon Machine Image 에 나오는 아이디 값 AMI ID 복사해서 붙여넣기
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "ec2" {
    ami = "ami-00d72ec36cdfc8a0a"                     # AMI ID
    instance_type = "t2.micro"  # 인스턴스 유형
    key_name = "saju-key-dev"   # 기존 키페어 선택
    # 해당 보안그룹 ID 직접 가져올수도 있다
    vpc_security_group_ids = [aws_security_group.sg.id]  # 기존 보안그룹 ID
    availability_zone = "eu-central-1a"   # 가용영역
    user_data = file("./userdata.sh")     # 사용자 데이타
    # 스토리지 추가
    root_block_device {
      volume_size = 30    # 크기(GiB)
      volume_type = "gp3"  # 볼륨 유형
    }
    # 태그 설정
    tags = {
        Name = "saju-api-dev"
        Service = "saju-dev"
    } 
}

# 탄력적 IP 할당
# 위치 : EC2 > 네트워크 및 보안 > 탄력적 IP
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "eip" {
  instance = aws_instance.ec2.id

  tags = {
    Name = "saju-api-dev"
    Service = "saju-dev"
  } 
}

# 탄력적 IP를 ec2에 연결
output "eip_ip" {
  value = aws_eip.eip.public_ip
}