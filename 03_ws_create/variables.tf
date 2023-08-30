variable "ws_name" {
    description = "Workspace name"
    type = list
}

variable "hostname" {
  description = "TFE 서버 hostname"
}

# variable "token" {
#     description = "TFE API Token"
# }

variable "exec_mode" {
    description = "Choose the Execution mode betweeon remote, local and agent"
}