#!/bin/bash
# made by hazukie
# date: 2024.4.13
# JUST FOR LEARNING PURPOSES, DON'T USE THIS TO CRACK SOFTWARE.
# 只是出于学习目的，请勿将其用于破解软件，否则后果自负。用户行为均与本项目作者无关！

# 打印警告日志
warning() {
    printf "\033[31m-> $*\n\033[0m"
}

# 打印日志
infos() {
    printf "\033[32m=> $*\n\033[0m"
}

# 待注入数据文件路径
HOOK_JS_PATH="./src/hooklog.js"

# Typora 安装路径
TYPORA_INSTALLED_PATH="/usr/share/typora"


infos "Typora 安装路径: $TYPORA_INSTALLED_PATH"
warning "Typora 安装路径是否正确?(y/n)"
read -r check
if [[ "${check:0:1}" != "y" ]];then
	infos "不正确的话你可以尝试输入新的路径:"
	read -r reply
	if [[ -z $reply ]];then
		warning "您输入为空...脚本已正常退出，请稍候重试！"
		exit 0
	fi
	TYPORA_INSTALLED_PATH="$reply"
fi
infos "已确认当前安装路径为: $TYPORA_INSTALLED_PATH\n"


# 注入 JS 文件的待解压缩包路径
INJECT_JS_DIR_ASAR_PATH="$TYPORA_INSTALLED_PATH/resources/node_modules.asar"

# 为防止破坏原压缩包，特意复制至当前目录
if [[ ! -d ./build ]];then
	mkdir build
fi
CUR_INJECT_ASAR_PATH="./build/node_modules.asar"

# 注入 JS 文件的文件夹路径
INJECT_JS_DIR_PATH="./build/node"

# 注入 JS 文件路径
HOOK_JS_WRITE_PATH="$INJECT_JS_DIR_PATH/raven/hook.js"

# 注入JS文件的目的文件路径
INJECT_JS_PATH="$INJECT_JS_DIR_PATH/raven/index.js"

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
	cat "$HOOK_JS_PATH">"$HOOK_JS_WRITE_PATH"
}


# 给目的文件中追加一行 "require('./hook')",
# 实现在 Typora 运行时调用注入JS文件
append_require2file() {
    echo -e "\nrequire('./hook')">> "$INJECT_JS_PATH"
}


################## 正式执行部分 ###############

if file_exist "$INJECT_JS_DIR_PATH"; then
    warning "您可能已经注入过 hook 文件了！\n警告：在当前目录下发现 node 文件夹"
    infos "您若不确定之前是否注入过该文件的话，请手动删除当前目录下的 node 文件夹($INJECT_JS_DIR_PATH)！\n"
    infos "您可以有以下选择："
    infos "\t 1. 删除目录"
    warning "\t\trm $INJECT_JS_DIR_PATH -r\n"
    infos "\t2. 复制已注入压缩包(已确认)至 $INJECT_ASAR_PATH"
    warning "\t\tsudo cp $CUR_INJECT_ASAR_PATH $INJECT_JS_DIR_ASAR_PATH"
    exit 0
fi

if [ ! -e "$INJECT_JS_DIR_ASAR_PATH" ]; then
    warning "未找到 node_modules.asar！"
    warning "请确认 Typora 安装目录下是否正确，以及该安装目录下的 resources 中是否存在 node_modules.asar!"
    exit 0
fi


check_node

infos "复制 node_modules 至 当前目录下($(pwd))"
sudo cp $INJECT_JS_DIR_ASAR_PATH $CUR_INJECT_ASAR_PATH
if [[ ! -d backup ]];then
	mkdir -p ./build/backup
fi
infos "备份 node_modules 至 ./build/backup 目录下\n"
cp $CUR_INJECT_ASAR_PATH ./build/backup

infos "正在解压 node_modues.asar"
node ./asar_modules/node_modules/@electron/asar/bin/asar.js extract $CUR_INJECT_ASAR_PATH $INJECT_JS_DIR_PATH
infos "成功解压至 $(pwd)/node 文件夹中！\n"

infos "正在将 hook.js 添加至 $INJECT_JS_DIR_PATH 文件夹中..."
write_js2file
infos "正在将依赖添加到 $INJECT_JS_DIR_PATH/raven/index.js...\n"
append_require2file

infos "添加 hook.js 成功！"
infos "依赖添加到 $INJECT_JS_PATH/raven/index.js 成功！\n"

infos "正在重新打包 node 文件夹至 node_modules.asar..."
rm $CUR_INJECT_ASAR_PATH
node ./asar_modules/node_modules/@electron/asar/bin/asar.js pack $INJECT_JS_DIR_PATH $CUR_INJECT_ASAR_PATH
infos "打包完成！\n"

warning "###### 正在将 $CUR_INJECT_ASAR_PATH 移动至 $INJECT_JS_DIR_ASAR_PATH ######"
sudo cp $CUR_INJECT_ASAR_PATH $INJECT_JS_DIR_ASAR_PATH
warning "若执行当前脚本后不能正常打开软件的话，则请执行以下命令还原："
warning "\tcp ./build/backup/node_modules.asar $INJECT_JS_DIR_ASAR_PATH\n"

infos "您的序列号为："
infos "\tLSGDW2-6M43UN-KHKH2A-D6FDJF"
infos "\tD9KYN9-MCCL2F-59LFPC-NK2CPX\n"
warning "如果激活失败，恐怕您还得安装 rust 环境并使用 license-gen/target/debug/license-gen 生成新的序列号"
