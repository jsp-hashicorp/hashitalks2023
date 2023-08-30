# 작업 순서

## 아래와 같은 순서로 작업
- 1. 작업 환경 준비 
- 2. state 파일 백업
- 3. 작업 대상 Workspace 생성
- 4. state 내 필요 정보 확인 후 state 파일 이관
- 발표 자료 내려 받기 : [[HashiTalks_Korea 2023]Terraform_CE_to_Enterprise_migration.pdf]([HashiTalks_Korea 2023]Terraform_CE_to_Enterprise_migration.pdf)

## 1. 작업 환경 준비
작업 대상 Workspace을 이관 대상 Workspace이름과 동일하게 생성 (로컬 디렉토리).

아래와 같이 작업 대상 디렉토리와 같은 수준으로 디렉토리 구성 후 작업할 것. 예시로 구성한 01_ent001은 이관이 필요한 대상 Workspace갯수 만틈 생성.

```bash
❯ tree -d
.
.
├── 01_ent001 # 작업 대상 디렉토리 --> 원하는 만큰 생성 가능
│   └── files
├── 02_state_backup # State 파일 백업 작업 디렉토리
├── 03_ws_create    # TFE/TFC 내 Workspace 생성 작업용 
└── 04_state_mig    # State 파일 이관 작업 디렉토리 

```

## 2. state 파일 백업
- 작업 디렉토리 : 02_state_backup
- Remote Backend (AWS S3)에 대한 설정은 이미 작업 대상 디렉토리 상에 존재 할 것.
- 스크립트를 실행하는 Shell환경에 AWS S3 Bucket 접근 권한이 있을 것.
- 작업 대상 디렉토리와 같은 수준의 디렉토리에서 `down.sh` 스크립트를 실행할 것.

```bash
❯ sh down.sh
===== 작업 Directory: ../hashicat-aws001  =====
state file download
-rw-r--r--  1 jsp  staff  22526 Jul 13 14:19 terraform.tfstate
state file download 완료
=============
 
===== 작업 Directory: ../hashicat-aws002  =====
state file download
-rw-r--r--  1 jsp  staff  22285 Jul 13 14:19 terraform.tfstate
state file download 완료
=============
```


## 3. 작업 대상 Workspace 생성
- 작업 디렉토리 : 03_ws_create
- `terraform init`을 통해 Workspace가 생성되지만, 다수의 Workspace를 생성하고 공통 설정을 적용하기 위해 Workspace를 사전에 생성
- 작업을 수행하는 CLI 환경에서 TFE/TFC API TOKEN이 환경 변수 또는 Configuration File로 설정되어 있어야 함.
- `terraform apply`이후 TFE/TFC 상의 Organization 내에서 Workspace가 생성.

```hcl
[main.tf]
locals {
    # 이미 만들어 놓은 TFC/TFE 내의 조직 이름 및 프로젝트 이름 지정
    org_name = "tfc_org_이름"
    prj_name = "tfc_project_이름"
}

# Project ID 조회
data "tfe_project" "talks" {
    name = local.prj_name
    organization =  local.org_name
}

resource "tfe_workspace" "test" {
  count = length(var.ws_name)
  name           = var.ws_name[count.index]
  organization   = local.org_name
  execution_mode = var.exec_mode
  project_id = data.tfe_project.talks.id
  tag_names    = ["hashitalks", "migrated", "2023", "demo"] # 원하는 Tag 지정 가능
  terraform_version = "1.5.2" # 원하는 TF Community Edition 버전 지정
  force_delete = true
}

[terraform.tfvars]
# TFE/TFC 접속을 위한 토큰은 terraform login 명령어를 사용, 환경 파일에 저장 후 사용할 것
# https://developer.hashicorp.com/terraform/cli/commands/login
ws_name = ["01_ent001","01_hc02", "01_tkdemo3", "01_weba001"] # 작업 대상 디렉토리 이름과 동일하게 Workspace 이름을 사용.
hostname = "app.terraform.io"
exec_mode = "local"
```


## 4.state 내 필요 정보 확인 후 state 파일 이관

### 4.1 state 정보 확인 스크립트 실행
API기반으로 state 파일 업로드 시, state 파일 내의 `serial`, `lineage` 정보에 대한 확인이  필요. 
아래 스크립트를 이용하여, 복수 개의 작업 대상 디렉토리에 있는 terraform.tfstate 파일에서 필요한 정보를 확인 후 output.txt로 저장

```bash
#!/bin/bash
# State file에서 serial과 lineage 정보를 가져옴
# 디렉토리 내의 모든 tfstate 파일을 가져옴
state_files=("../01_ent001" "../tk-hcat002" "../hc202308") # 이관 작업 대상 Workspace 지정

# 결과를 저장할 파일 경로
output_file="output.txt"

# 출력 파일 초기화
> "$output_file"

# Workspace ID를 조회

# 각 tfstate 파일에 대해 작업 공간 이름, serial 및 lineage 값을 추출하여 파일에 추가
function save_info {
for state_dir in ${state_files[@]}; do
  workspace_name=$(basename $(dirname "$state_dir/terraform.tfstate"))
  serial=$(cat "$state_dir/terraform.tfstate" | jq -r '.serial')
  lineage=$(cat "$state_dir/terraform.tfstate" | jq -r '.lineage')

  # 작업 공간 이름, serial, lineage 값을 파일에 추가
  echo "$workspace_name = {"ws_name" = \"$workspace_name\","serial"="$serial", "lineage"=\"$lineage\" }" >> "$output_file"
done

echo "출력이 완료되었습니다. 결과는 "$output_file"에 저장되었습니다."
}

### 
save_info
```

실행 시 저장된 결과값은 아래와 같다.
```bash
talks-hashicat-aws001 = {ws_name = "talks-hashicat-aws001",serial=10, lineage="896c7cff-9394-c1b5-a3db-475b38c06f4c" }
tk-hcat002 = {ws_name = "tk-hcat002",serial=7, lineage="8a32e2ba-430b-84d3-edc9-7a9336173614" }
hc202308 = {ws_name = "hc202308",serial=9, lineage="8a97e2bf-4396-c4d3-adce-4873c9376321" }
```

### 4.2 terraform.tfvars 수정
위 작업 결과 생성된 결과값을 아래와 같이 terraform.tfvars의 변수값에 저장.
org_name, tfe_token도 작업 대상에 맞게 수정 할 것.
```hcl
org_name  = "TARGET_ORG_NAME"
tfe_token = "TFE/TFC API TOKEN"
api_url   = "https://app.terraform.io/api/v2" # TFE/TFC API Endpoint
state_info = {
 talks-hashicat-aws001 = {ws_name = "talks-hashicat-aws001",serial=10, lineage="896c7cff-9394-c1b5-a3db-475b38c06f4c" }
 tk-hcat002 = {ws_name = "tk-hcat002",serial=7, lineage="8a32e2ba-430b-84d3-edc9-7a9336173614" }
 hc202308 = {ws_name = "hc202308",serial=9, lineage="8a97e2bf-4396-c4d3-adce-4873c9376321" }
}
```

### 4.3 State migration
위와 같이 필요한 정보 설정이 끝나면, `terraform apply`를 실행하여, 이미 생성된 Workspace로 state 파일을 이관한다.

workspace 잠금 - state 파일 업로드 - workspace 잠금 해제 순으로 동작

```hcl
# Workspace 잠금 - state 이관 - workspace 잠금 해제
# 공통 : Workspace ID 필요 (data source 활용)


## 00 : 정보 조회 Workspace 
# Workspace ID : data.tfe_workspace.target_worspace[0].id
data "tfe_workspace" "target_workspace" {
  for_each     = var.state_info
  name         = each.key
  organization = var.org_name
}

## 01: Workspace Lock : API 사용해서 잠금
resource "terraform_data" "lock_workspace" {
  for_each = var.state_info

  triggers_replace = [
    data.tfe_workspace.target_workspace
  ]

  provisioner "local-exec" {
    command = <<EOT
      curl -s \
        --header "Content-Type: application/vnd.api+json" \
        --header "Authorization: Bearer ${var.tfe_token}" \
        --request POST \
        --data '{ "reason": "Locking ${data.tfe_workspace.target_workspace[each.key].name} for state upload" }' \
        ${var.api_url}/workspaces/${data.tfe_workspace.target_workspace[each.key].id}/actions/lock
       echo "${data.tfe_workspace.target_workspace[each.key].name}가 성공적으로 잠금처리되었습니다."
    EOT
  }
}

# # ## 02 state upload
resource "terraform_data" "upload_state_file" {
  for_each = var.state_info

  triggers_replace = [
    resource.terraform_data.lock_workspace
  ]

  provisioner "local-exec" {
    command = <<EOT
        curl \
            -s --request POST \
            --header "Authorization: Bearer ${var.tfe_token}" \
            --header "Content-Type: application/vnd.api+json" \
            --data '{
                "data": {
                "type": "state-versions", 
                "attributes": {
                    "serial": ${each.value["serial"]} ,
                    "md5": "${md5(file("../${each.key}/terraform.tfstate"))}",
                    "lineage": "${each.value["lineage"]}",
                    "state": "${base64encode(file("../${each.key}/terraform.tfstate"))}"
                }
                }
            }' \
            ${var.api_url}/workspaces/${data.tfe_workspace.target_workspace[each.key].id}/state-versions
        echo "  Statefile을 Workspace ${data.tfe_workspace.target_workspace[each.key].name}로 성공적으로 Upload 하였습니다."
  EOT

  }
}



## 03. Workspace Unlock
resource "terraform_data" "unlock_workspace" {
  for_each = var.state_info

  triggers_replace = [
    terraform_data.upload_state_file
  ]

  depends_on = [terraform_data.upload_state_file]

  provisioner "local-exec" {
    command = <<EOT
      curl -s \
        --header "Content-Type: application/vnd.api+json" \
        --header "Authorization: Bearer ${var.tfe_token}" \
        --request POST \
        ${var.api_url}/workspaces/${data.tfe_workspace.target_workspace[each.key].id}/actions/unlock

      echo " Workspace ${data.tfe_workspace.target_workspace[each.key].name}가 성공적으로 잠금해제 처리되었습니다."
    EOT
  }
}
```
