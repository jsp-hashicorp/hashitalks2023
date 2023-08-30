# Workspace 잠금 - state 이관 - workspace 잠금 해제
# 공통 : Workspace ID 필요 (data source 활용)
# state 파일 내 Serial, Lineage 정보 : cat statefile|jq -r .serial 
# jq '.users[]|.first,.last' | paste - -
/*
❯ cat terraform.tfstate|jq -r '.lineage,.serial'|paste - -
1b58c838-fa3f-1411-9dde-44660d4430bb    10
❯ cat terraform.tfstate|jq -r '"Serial :\(.serial), Lineage: \(.lineage)"'
Serial :10, Lineage: 896c7cff-9394-c1b5-a3db-475b38c06f4c
❯ cat terraform.tfstate|jq '"Serial :\(.serial), Lineage: \(.lineage)"'
"Serial :10, Lineage: 896c7cff-9394-c1b5-a3db-475b38c06f4c"
*/

## 00 : 정보 조회 Workspace 
# Workspace ID : data.tfe_workspace.target_worspace[0].id
data "tfe_workspace" "target_workspace" {
  for_each     = var.state_info
  name         = each.key
  organization = var.org_name
}

## 01: Workspace Lock : API 사용해서 잠금
/* https://developer.hashicorp.com/terraform/enterprise/api-docs/workspaces#lock-a-workspace
 POST /workspaces/:workspace_id/actions/lock
Sample Payload
{
  "reason": "Locking workspace-1"
}

Sample Request 
curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @payload.json \
  https://app.terraform.io/api/v2/workspaces/ws-SihZTyXKfNXUWuUa/actions/lock

*/
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
/*
https://developer.hashicorp.com/terraform/enterprise/api-docs/workspaces#unlock-a-workspace
POST /workspaces/:workspace_id/actions/unlock
Sample Request
curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  https://app.terraform.io/api/v2/workspaces/ws-SihZTyXKfNXUWuUa/actions/unlock
*/
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