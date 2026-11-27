######################################
# ed2 구성에 대한 모든 설정 선언
# data ~     : 조회
# resource ~ : 리소스 생성
######################################

# 1. VPC 구성 (새로 생성 or [v]기존 사용)
#    VPC 이름과 상관없는 VPC 생성 시 지정된 default 영향을 받은 것임. 리전별로 1개만 존재함
data "aws_vpc" "default" {
    # 현재 존재하는 vpc 목록 중에 default vpc 정보를 조회
    default = true
}

# 2. subnet 설정 or 구성 후 설정
#    현재 default vpc는 4개의 서브넷을 가지고 있음 => 멀티 AZ 지원 관점에서 4가지 사용할 수 있음
#    멀티 AZ를 사용한다는 것은 예) 같은 서비스를 a동과 b동에 동일하게 구성하여 a동이 장애나면 b동에서 대응하도록 구성
data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        # n개의 서브넷 정보가 조회되어서 리스트[]에 담긴다. 서브넷을 보유한 vpc의 idㄹ ㅗ조회한 것
        values = [data.aws_vpc.default.id]
    }
}

# 3. 보안그룹 생성 선언
resource "aws_security_group" "ai-cp2-08-sg" {
    # 기본 세부 정보 #######################
    # 이름
    name = "ai-cp2-08-sg"
    # 설명 - ASCII만 지원. 한글 x
    description = "ai-cp2-08 security group"
    # 보안그룹이 속한 vpc 지정
    vpc_id = data.aws_vpc.default.id

    # 인바운드 #############################
    # 외부의 트래픽이 내부로 진입 됨 -> 통과할 포트만 등록 -> 존재하는 만큼 추가함 (규칙 추가)
    # 22, 80
    ingress {
        # 프로토콜
        protocol = "tcp"
        # 포트
        from_port = 22 # 허용할 포트 범위의 시작 번호
        to_port = 22   # 허용할 포트 범위의 끝 번호
        # CIDR 블록
        # classless Inter-Domain 'Routing' : IP주소, 네트워크 범위를 표현
        # IP주소의 범위 (네트워크 대역) 정의
        # IPv4 기준 0~255.0~255.0~255.0~255 => 각 자리 수 별로 256개를 설정 => 전체 32비트 사용
        # 모든 IP의 가지 수는 256*256*256*256개 가능함
        # ().().().()/<앞에서부터 고정되는 비트 수>
        # ex1) 10.0.0.0/8 => 앞에서부터 8비트는 고정 => 10.(0~255).(0~255).(0~255)
        # ex2) 2010.0.0/16 => 앞에서부터 16비트는 고정 => 20.10.(0~255).(0~255)
        # 0.0.0.0/0 => 모든 대역폭 => 전 세계 어디서든
        # 222.111.55.44/32 => 오직 1개의 IP만 가능, 내 IP
        cidr_blocks = [ "222.108.125.33/32" ]
        # 설명. 강의장에서만 접속
        description = "SSH"
    }
    ingress {
        # 프로토콜
        protocol = "tcp"
        # 포트
        from_port = 80
        to_port = 80
        cidr_blocks = [ "0.0.0.0/0" ] # 전세계로 개방
        # 전세계에서 웹으로 접속 OK
        description = "HTTP"
    }

    # 아웃바운드 ###########################
    # 내부 트레픽이 외부로 나가는 규칙
    egress {
        # 모든 프로토콜 개방
        protocol = "-1"
        # 모든 포트 개방
        from_port = 0
        to_port = 0
        # IP 전세계로 개방
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

# 4. EC2 생성을 위한 AMI(Amazon Machine Image) 이미지 정보 조회
data "aws_ami" "amazon_linux" {
    # 최신 설정
    most_recent = true
    # 소유자
    owners = [ "amazon" ]
    # 필터링
    filter {
        name = "name"
        values = [ "al2023-ami-*" ]
    }
    # 필터 추가
    filter {
        name = "architecture"
        values = [ "x86_64" ]
    }
}

# 5. EC2 생성 선언
resource "aws_instance" "ai-cp2-08-ec2" {
    # 태그
    tags = {
      Name = "ai-cp2-08-ec2"
    }
    # AMI
    ami = data.aws_ami.amazon_linux.id
    # 인스턴스 유형
    instance_type = var.instance_type
    # 키 페어
    key_name = var.key_name
    # 서브넷
    subnet_id = data.aws_subnets.default.ids[0] # a,b,c,d중 첫번째 a동
    # 보안 그룹
    vpc_security_group_ids = [
        aws_security_group.ai-cp2-08-sg.id
    ]
    # 스토리지 생략
    # 고급설정 생략
    # IP는 임시적으로 동적 할당
}

# 6. 탄력적 IP 적용 (1차 버전에는 제외)