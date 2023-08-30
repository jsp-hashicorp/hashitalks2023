#!/bin/bash
# State file에서 serial과 lineage 정보를 가져옴
# 디렉토리 내의 모든 tfstate 파일을 가져옴
state_files=("../01_ent001" "../01_hc02" "../01_tkdemo3" "../01_weba001")

# 결과를 저장할 파일 경로
output_file="output.txt"

# 출력 파일 초기화
> "$output_file"

# 각 tfstate 파일에 대해 작업 공간 이름, serial 및 lineage 값을 추출하여 파일에 추가
function save_info {
for state_dir in ${state_files[@]}; do
  workspace_name=$(basename $(dirname "$state_dir/terraform.tfstate"))
  serial=$(cat "$state_dir/terraform.tfstate" | jq -r '.serial')
  lineage=$(cat "$state_dir/terraform.tfstate" | jq -r '.lineage')

  # 작업 공간 이름, serial, lineage 값을 파일에 추가
  echo "\"$workspace_name\" = {"ws_name" = \"$workspace_name\","serial"="$serial", "lineage"=\"$lineage\" }" >> "$output_file"
done

echo "출력이 완료되었습니다. 결과는 "$output_file"에 저장되었습니다."
}

### 
save_info