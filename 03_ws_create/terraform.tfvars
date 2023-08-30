# TFE/TFC 접속을 위한 토큰은 terraform login 명령어를 사용, 환경 파일에 저장 후 사용할 것
# https://developer.hashicorp.com/terraform/cli/commands/login
ws_name = ["01_ent001","01_hc02", "01_tkdemo3", "01_weba001"] # 작업 대상 디렉토리 이름과 동일하게 Workspace 이름을 사용.
hostname = "app.terraform.io"
exec_mode = "local"