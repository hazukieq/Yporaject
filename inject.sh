#!/bin/bash
# made by hazukie
# date: 2024.4.13

# 打印警告日志
warning() {
    echo -e "\033[31m$1\033[0m"
}

# 打印日志
infos() {
    echo -e "\033[32m$1\033[0m"
}

# 待注入数据文件路径
HOOK_JS_PATH="./src/hooklog.js"

# Typora 安装路径
TYPORA_INSTALLED_PATH="/usr/share/typora"

infos "Typora 安装路径: $TYPORA_INSTALLED_PATH"
warning "Typora 安装路径是否正确?(y/n)"
read -r check
echo "==>${check:0:1}"
if [[ "${check:0:1}" != "y" ]];then
	infos "不正确的话你可以尝试输入新的路径:"
	read -r reply
	if [[ -z $reply ]];then
		warning "您输入为空...脚本已正常退出，请稍候重试！"
		exit 0
	fi
	TYPORA_INSTALLED_PATH="$reply"
fi
infos "已确认当前安装路径为: $TYPORA_INSTALLED_PATH"



# 注入 JS 文件路径
HOOK_JS_WRITE_PATH="$TYPORA_INSTALLED_PATH/node/raven/hook.js"

# 注入 JS 文件的待解压缩包路径
INJECT_JS_DIR_ASAR_PATH="$TYPORA_INSTALLED_PATH/resources/node_modules.asar"

# 注入 JS 文件的文件夹路径
INJECT_JS_DIR_PATH="$TYPORA_INSTALLED_PATH/node"


# 注入JS文件的目的文件路径
INJECT_JS_PATH="$TYPORA_INSTALLED_PATH/node/raven/index.js"

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
	cat "$HOOK_JS_PATH"|sudo tee "$HOOK_JS_WRITE_PATH"
}


# 给目的文件中追加一行 "require('./hook')",
# 实现在 Typora 运行时调用注入JS文件
append_require2file() {
    echo -e "\nrequire('./hook')" |sudo tee -a "$INJECT_JS_PATH"
}



if file_exist "$INJECT_JS_DIR_PATH"; then
    warning "您可能已经注入过 hook 文件了！\n警告：在当前目录下发现 node 文件夹"
    infos "您若不确定之前是否注入过该文件的话，请手动删除当前目录下的 node 文件夹($INJECT_JS_DIR_PATH)！"
    exit 0
fi

if [ ! -e "$INJECT_JS_DIR_ASAR_PATH" ]; then
    warning "未找到 node_modules.asar！"
    warning "请将我(inject.py) 移动到 Typora 安装目录下!"
    exit 0
fi

infos "正在解压 node_modues.asar"
sudo node ./asar_modules/node_modules/@electron/asar/bin/asar.js extract $INJECT_JS_DIR_ASAR_PATH $INJECT_JS_DIR_PATH
infos "成功解压至 node 文件夹中！"

infos "正在将 hook.js 添加至 node 文件夹中..."
write_js2file
infos "正在将依赖添加到 node/raven/index.js..."
append_require2file

infos "添加 hook.js 成功！"
infos "依赖添加到 node/raven/index.js 成功！"

infos "正在重新打包 node 文件夹至 node_modules.asar..."
sudo node ./asar_modules/node_modules/@electron/asar/bin/asar.js pack $INJECT_JS_DIR_PATH $INJECT_JS_DIR_ASAR_PATH
infos "打包完成！"

infos "您的序列号为："
infos "LSGDW2-6M43UN-KHKH2A-D6FDJF"
infos "D9KYN9-MCCL2F-59LFPC-NK2CPX"
warning "如果激活失败，恐怕您还得安装 rust 环境并使用 license-gen/target/debug/license-gen 生成新的序列号"
