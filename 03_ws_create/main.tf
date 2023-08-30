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