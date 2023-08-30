# variable "ws_name" {
#     description = "Workspace name"
#     type = list
# }

variable "org_name" {
  description = "Tasrget Org name"

}

variable "tfe_token" {
  description = "TFE API Token"
}

variable "api_url" {
  description = "Base API URL (https://app.terraform.io/api/v2)"
}

variable "state_info" {
  description = "migration 대상 state file 정로"
  type        = map(any)
}