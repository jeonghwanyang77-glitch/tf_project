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

# 3. 보안그룹

# 4. EC2 생성을 위한 OS 이미지 정보 조회

# 5. EC2 생성 선언

# 6. 탄력적 IP 적용 (1차 버전에는 제외)