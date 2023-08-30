#!/bin/bash

# Terraform state 파일을 다운로드할 디렉토리
STATE_DIR=("../01_ent001" "../01_hc02" "../01_tkdemo3" "../01_weba001")

# Shell Script를 실행할 디렉토리
WORKING_DIR="../02_state_backup"

# STATE_DIR 별 State 파일 다운로드
for directory in "${STATE_DIR[@]}"; do
  echo "===== 작업 Directory: $directory  ====="
  # 해당 디렉토리로 이동
  cd $directory
  # Terraform state 파일 다운로드
  echo "state file download"
  terraform state pull > terraform.tfstate
  # Terraform state 파일 다운로드 확인
  ls -al terraform.tfstate
  echo "state file download 완료"
  cd $WORKING_DIR
  echo "============="
  echo " "
done