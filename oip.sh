#!/bin/bash

# 读取用户输入的IP地址列表
read -p "请输入IP地址，使用逗号分隔: " ip_list

# 定义一个计数器，用于生成标签值
counter=1

# 将IP地址列表转化为数组
IFS=',' read -ra ADDR <<< "$ip_list"

# 遍历数组中的每个IP地址
for i in "${ADDR[@]}"; do
    # 根据当前计数器的值为IP地址配置网络接口
    ip addr add "$i"/24 dev ens3 label ens3:$counter
    # 更新计数器
    counter=$((counter + 1))
done

echo "配置完成"
