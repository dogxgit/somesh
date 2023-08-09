#!/bin/bash

# 获取用户输入的IP地址
read -p "请输入IP地址，使用逗号分隔: " ip_list

# 将IP地址列表转化为数组
IFS=',' read -ra ADDR <<< "$ip_list"

# 输出IP地址验证
echo "您输入的IP地址是:"
for ip in "${ADDR[@]}"; do
    echo "$ip"
done

echo "开始处理..."

# 以一个例子开始，修改第一个文件
CONFIG_1="/etc/v2ray-agent/xray/conf/07_VLESS_vision_reality_inbounds.json"
new_inbounds=$(echo '[]' | jq .)

for index in "${!ADDR[@]}"; do
    counter=$((index + 1))
    
    # 生成随机UUID
    rand_uuid=$(uuidgen)
    
    inbounds_template=$(jq --arg ip "${ADDR[$index]}" --arg rand_uuid "$rand_uuid" --arg counter "$counter" \
                            '.inbounds[0] 
                            | .tag = ("in" + ($counter|tostring))
                            | .settings.clients[0].id = $rand_uuid
                            | .listen = $ip' $CONFIG_1)

    new_inbounds=$(echo $new_inbounds | jq ". + [$inbounds_template]")
done

new_inbounds=$(echo $new_inbounds | jq ". + [$(jq '.inbounds[0]' $CONFIG_1)]")
jq --argjson new_inbounds "$new_inbounds" '.inbounds = $new_inbounds' $CONFIG_1 > temp1.json
mv temp1.json $CONFIG_1

echo "第一个文件处理完成。"


# 输出修改后的id和ip
echo "修改后的ID和对应的IP地址："
for index in "${!ADDR[@]}"; do
    counter=$((index + 1))
    id=$(jq --arg counter "$counter" -r '.inbounds[] | select(.tag == ("in" + $counter)).settings.clients[0].id' $CONFIG_1)
    echo "ID: $id, IP: ${ADDR[$index]}"
done
# 修改第二个文件
CONFIG_2="/etc/v2ray-agent/xray/conf/09_routing.json"

# 获取原始规则
orig_rule=$(jq '.routing.rules[0]' $CONFIG_2)

# 创建新规则数组
new_rules=$(echo '[]' | jq .)

# 基于输入的IP地址生成新的路由规则
for index in "${!ADDR[@]}"; do
    counter=$((index + 1))
    rule_template=$(echo '{}' | jq --arg counter "$counter" \
                        '.type = "field" 
                        | .inboundTag = ("in" + $counter) 
                        | .outboundTag = ("ip" + $counter)')

    new_rules=$(echo $new_rules | jq ". += [$rule_template]")
done

# 将原始规则添加到新规则数组的末尾
new_rules=$(echo $new_rules | jq ". += [$orig_rule]")

# 将新的规则写入到配置文件中
jq --argjson new_rules "$new_rules" '.routing.rules = $new_rules' $CONFIG_2 > temp2.json
mv temp2.json $CONFIG_2

echo "第二个文件处理完成。"

# 修改第三个文件
CONFIG_3="/etc/v2ray-agent/xray/conf/10_ipv4_outbounds.json"

# 获取原始出站
orig_outbounds=$(jq '.outbounds' $CONFIG_3)

# 创建新的出站数组
new_outbounds=$(echo '[]' | jq .)

# 基于输入的IP地址生成新的出站规则
for index in "${!ADDR[@]}"; do
    counter=$((index + 1))
    outbound_template=$(echo '{}' | jq --arg ip "${ADDR[$index]}" --arg counter "$counter" \
                        '.sendThrough = $ip 
                        | .protocol = "freedom" 
                        | .tag = ("ip" + $counter)')

    new_outbounds=$(echo $new_outbounds | jq ". += [$outbound_template]")
done

# 将原始出站规则添加到新的出站数组的末尾
new_outbounds=$(echo $new_outbounds | jq ". += $orig_outbounds")

# 将新的出站规则写入到配置文件中
jq --argjson new_outbounds "$new_outbounds" '.outbounds = $new_outbounds' $CONFIG_3 > temp3.json
mv temp3.json $CONFIG_3

echo "第三个文件处理完成。"
