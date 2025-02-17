#!/bin/bash

# 加载系统函数库(Only for RHEL Linux)
# [ -f /etc/init.d/functions ] && source /etc/init.d/functions

# 自定义action函数，实现通用action功能
success() {
  echo -en "\\033[60G[\\033[1;32m  OK  \\033[0;39m]\r"
  return 0
}

failure() {
  local rc=$?
  echo -en "\\033[60G[\\033[1;31mFAILED\\033[0;39m]\r"
  [ -x /bin/plymouth ] && /bin/plymouth --details
  return $rc
}

action() {
  local STRING rc

  STRING=$1
  echo -n "$STRING "
  shift
  "$@" && success $"$STRING" || failure $"$STRING"
  rc=$?
  echo
  return $rc
}

# 判断命令是否正常执行 函数
if_success() {
	if [ $? -eq 0 ]; then
	        action "$1" /bin/true
	else
	        action "$2" /bin/false
	        exit 1
	fi
}

Server_Dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
Conf_Dir="$Server_Dir/conf"
Temp_Dir="$Server_Dir/temp"
Log_Dir="$Server_Dir/logs"
URL='更改为你的clash订阅地址'
# 检查url是否有效
Text1="Clash订阅地址可访问！"
Text2="Clash订阅地址不可访问！"
# curl -s --head $URL | head -n 1 | grep 'HTTP/1.[01] [23]..' > /dev/null
wget -q -O /dev/null $URL
if_success $Text1 $Text2

# 临时取消环境变量
unset http_proxy
unset https_proxy

# 拉取更新config.yml文件
Text3="配置文件config.yaml下载成功！"
Text4="配置文件config.yaml下载失败，退出启动！"
wget -q -O $Temp_Dir/clash.yaml $URL
if_success $Text3 $Text4

# 取出代理相关配置 
sed -n '/^proxies:/,$p' $Temp_Dir/clash.yaml > $Temp_Dir/proxy.txt

# 合并形成新的config.yaml
cat $Temp_Dir/templete_config.yaml > $Temp_Dir/config.yaml
cat $Temp_Dir/proxy.txt >> $Temp_Dir/config.yaml
\cp $Temp_Dir/config.yaml $Conf_Dir/

# 启动Clash服务
Text5="服务启动成功！"
Text6="服务启动失败！"
nohup $Server_Dir/clash-linux-amd64-v1.3.5 -d $Conf_Dir &> $Log_Dir/clash.log &
if_success $Text5 $Text6

# 添加环境变量(root权限)
echo -e "export http_proxy=http://127.0.0.1:7890\nexport https_proxy=http://127.0.0.1:7890" > /etc/profile.d/clash.sh
echo -e "系统代理http_proxy/https_proxy设置成功，请在当前窗口执行以下命令加载环境变量:\n\nsource /etc/profile.d/clash.sh\n"
