#!/bin/bash
# made by hazukie
# date: 2024.4.13
# JUST FOR LEARNING PURPOSES, DON'T USE THIS TO CRACK SOFTWARE.
# 只是出于学习目的，请勿将其用于破解软件，否则后果自负。用户行为均与本项目作者无关！

#####################################
####	    函数配置部分	####
####################################
# 打印警告日志
warning() {
    printf "\033[31m-> $*\n\033[0m"
}

# 打印日志
infos() {
    printf "\033[32m=> $*\n\033[0m"
}

# 捕获 Ctrl+C 中断键
trap 'onCtrlC' INT
function onCtrlC() {
	printf "\n"
	warning "触发 Ctrl+C,已中止当前脚本运行..."
	exit 0
}

# 提示高危命令执行
check_dangerous_cmd(){
	warning "即将执行 $*"
	warning "是否确认执行高危命令? (y/n)"
	read -p "-> " -r dcheck
	if [[ "${dcheck:0:1}" != "y" ]];then
		warning "已取消执行高危命令,程序中止退出..."
		exit 1 
	else
		infos "正在执行高危命令 $*"
	fi
}

# 询问函数:
#	调用函数后通过 ret 变量获取返回值,
function ask(){
	infos "$*"
	read -p "-> " -r content
	until [[ ! -z "$content" ]];
	do
		infos "$*"
		read -p "-> " -r content
	done
	ret=""
	ret="$content"
}


check_typora_installed_path(){
	warning "该脚本包含 sudo 指令,请您确保知悉高危命令执行的后果且承担相关代价"
	warning "在执行過程中，请您仔细确认相关提示，当提示「即将执行高危命令」时，那么此种情形将考验您的判断力"
	infos "Typora 安装路径: $*"
	warning "Typora 安装路径是否正确?(y/n)"
	ret="$*"
	read -p "-> " -r check
	if [[ "${check:0:1}" != "y" ]];then
		ask "不正确的话你可以尝试输入新的路径:"
		infos "已确认当前安装路径为: $ret\n"
	fi
}


# 判断 node 是否安装
check_node(){
	warning "检测是否存在 node..."
	if ! type node >/dev/null 2>&1;then
		warning "未找到 node..."
		exit 0
	else
		infos "node 存在\n"
	fi
}

# 判断文件是否存在
file_exist() {
    if [ -e "$1" ]; then
        return 0
    else
        return 1
    fi
}

#注入数据
write_js2file() {
	cat "$CUR_HOOK_JS_PATH">"$HOOK_JS_WRITE_PATH"
}


# 给目的文件中追加一行 "require('./hook')",
# 实现在 Typora 运行时调用注入JS文件
append_require2file() {
    echo -e "\nrequire('./hook')">> "$CUR_INJECT_JS_PATH"
}

#前置准备工作
mkinit(){
	# 检查相关文件夹是否存在
	if file_exist "$CUR_INJECT_JS_DIR_PATH"; then
		warning "您可能已经注入过 hook 文件了！\n警告：在当前目录下发现 node 文件夹"
    		infos "您若不确定之前是否注入过该文件的话，请手动删除当前目录下的 node 文件夹($CUR_INJECT_JS_DIR_PATH)！\n"
    		infos "您可以有以下选择："
    		infos "\t 1. 删除目录"
    		warning "\t\trm $CUR_INJECT_JS_DIR_PATH -r\n"
    		infos "\t 2. 复制已注入压缩包(已确认)至 $INJECT_ASAR_PATH"
    		warning "\t\tsudo cp $CUR_PACKED_ASAR_PATH $INJECT_JS_DIR_ASAR_PATH"
    		exit 0
	fi
	if file_exist "$INJECT_JS_DIR_ASAR_PATH"; then
    		warning "未找到 node_modules.asar！"
    		warning "请确认 Typora 安装目录下是否正确，以及该安装目录下的 resources 中是否存在 node_modules.asar!"
    		exit 0
	fi

	# 检查 node 是否存在
	check_node

	# 复制 asar 文件至当前项目 build 下
	infos "复制 node_modules 至 当前目录下($(pwd)/build)"
	check_dangerous_cmd "sudo cp $INJECT_JS_DIR_ASAR_PATH $CUR_INJECT_ASAR_PATH"
	sudo cp $INJECT_JS_DIR_ASAR_PATH $CUR_INJECT_ASAR_PATH
}

################## 函数配置部分 ###############




################## 数据配置部分 ###############

# 待注入数据文件路径
CUR_HOOK_JS_PATH="./src/hooklog.js"

# Typora 安装路径
TYPORA_INSTALLED_PATH="/usr/share/typora"
# 再次确认是否正确
check_typora_installed_path "$TYPORA_INSTALLED_PATH"
TYPORA_INSTALLED_PATH="$ret"

# 注入 JS 文件的待解压缩包路径
INJECT_JS_DIR_ASAR_PATH="$TYPORA_INSTALLED_PATH/resources/node_modules.asar"

# 为防止破坏原压缩包，特意复制至当前目录
if [[ ! -d ./build ]];then
	mkdir build
fi
# 当前压缩包副本路径
CUR_INJECT_ASAR_PATH="./build/node_modules.asar"

# 当前重新打包压缩包路径
CUR_PACKED_ASAR_PATH="${CUR_INJECT_ASAR_PATH}_new"

# 当前注入 JS 文件的文件夹路径
CUR_INJECT_JS_DIR_PATH="./build/node"

# 注入 JS 文件路径
HOOK_JS_WRITE_PATH="$CUR_INJECT_JS_DIR_PATH/raven/hook.js"

# 注入JS文件的目的文件路径
CUR_INJECT_JS_PATH="$CUR_INJECT_JS_DIR_PATH/raven/index.js"

# 解压缩 Asar 包的程序路径
ASAR_BIN="./asar_modules/node_modules/@electron/asar/bin/asar.js" 
################## 数据配置部分 ###############



################## 正式执行部分 ###############
# 前置工作初始化
mkinit

# 解压 asar 文件
infos "正在解压 node_modues.asar"
node $ASAR_BIN extract $CUR_INJECT_ASAR_PATH $CUR_INJECT_JS_DIR_PATH
infos "成功解压至 $(pwd)/node 文件夹中！\n"

# 添加js文件和依赖
infos "正在将 hook.js 添加至 $CUR_INJECT_JS_DIR_PATH 文件夹中..."
write_js2file
infos "正在将依赖添加到 $CUR_INJECT_JS_PATH...\n"
append_require2file
infos "添加 $CUR_HOOK_JS_PATH 成功！"
infos "在 $CUR_INJECT_JS_PATH 添加依赖成功！\n"

# 重新打包成 asar 文件
infos "正在重新打包 node 文件夹至 $CUR_PACKED_ASAR_PATH..."
node $ASAR_BIN pack $CUR_INJECT_JS_DIR_PATH $CUR_PACKED_ASAR_PATH
infos "打包完成！\n"

# 复制 asar 文件到软件处
warning "###### 正在将 $CUR_INJECT_ASAR_PATH 移动至 $INJECT_JS_DIR_ASAR_PATH ######"
check_dangerous_cmd "sudo cp $CUR_PACKED_ASAR_PATH $INJECT_JS_DIR_ASAR_PATH"
sudo cp $CUR_PACKED_ASAR_PATH $INJECT_JS_DIR_ASAR_PATH

# 善后工作
warning "若执行当前脚本后不能正常打开软件的话，则请执行以下命令还原："
warning "\tcp $CUR_INJECT_ASAR_PATH $INJECT_JS_DIR_ASAR_PATH\n"
infos "您的序列号为："
infos "\tLSGDW2-6M43UN-KHKH2A-D6FDJF"
infos "\tD9KYN9-MCCL2F-59LFPC-NK2CPX\n"
warning "如果激活失败，恐怕您还得安装 rust 环境并使用 license-gen/target/debug/license-gen 生成新的序列号"
################## 正式执行部分 ###############
