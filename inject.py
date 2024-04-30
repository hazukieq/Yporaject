# made by hazukie
# date: 2024.4.13
# JUST FOR LEARNING PURPOSES, DON'T USE THIS TO CRACK SOFTWARE.
# 只是出于学习目的，请勿将其用于破解软件，否则后果自负。用户行为均与本项目作者无关！

###------配置开始------###

# 为什么有 <嵌入特性>呢？
# 其实就是：
#   是否注入一个带有 log 打印日志功能的 hook 文件
#   这样子便于我们在启动 Typora 时观察 待拦截的函数是否拦截
# 注意：
#   该特性默认开启，
#   想要不开启的话设置 embed_mode=False
# 是否开启嵌入特性
embed_mode = True

# 如果关闭<嵌入特性(EMBED)>,该 JS 文件将在运行时被使用
NO_EMBED_HOOK_JS_PATH = "./src/hook.js"
# 开启<嵌入特性>时: 待注入数据文件
EMBED_HOOK_JS_PATH = "./src/hooklog.js"

### Typora 安装路径
TYPORA_INSTALLED_PATH="/usr/share/typora"

# 注入 JS 文件的待解压缩包路径
INJECT_JS_DIR_ASAR_PATH = TYPORA_INSTALLED_PATH+"/resources/node_modules.asar"

# 为安全起见，特意复制至当前目录下
BUILD_DIR="./build"
BACKUP_DIR='./build/backup'
# 注入 JS 文件的待解压缩包路径
CUR_INJECT_JS_DIR_ASAR_PATH = "./build/node_modules.asar"

# 注入 JS 文件的文件夹路径
INJECT_JS_DIR_PATH = BUILD_DIR+"/node"

# 注入 JS 文件路径
HOOK_JS_WRITE_PATH = INJECT_JS_DIR_PATH+"/raven/hook.js"

# 注入JS文件的目的文件路径
INJECT_JS_PATH = INJECT_JS_DIR_PATH+"/raven/index.js"

###------配置结束------###


import os
import sys

# 判断文件是否存在
# file_path: 文件名
def file_exist(file_path):
    return os.path.exists(file_path)

def file_mkdir(dpath):
    if not os.path.exists(dpath):
        os.mkdir(dpath)


# 若开启<嵌入特性>,则将会使用该函数
# 注入数据
def embed_write_js2file():
    EMBED_HOOK_JS_BYTES=open(EMBED_HOOK_JS_PATH,'r+')
    with open(HOOK_JS_WRITE_PATH, "wb+") as f:
        f.write(EMBED_HOOK_JS_BYTES.read().encode())
    EMBED_HOOK_JS_BYTES.close()


# 若关闭<嵌入特性>，则将会使用该函数
def no_embed_write_js2file():
    NO_EMBED_HOOK_JS_BYTES = open(NO_EMBED_HOOK_JS_PATH,'r+')
    with open(HOOK_JS_WRITE_PATH, "wb+") as f:
        f.write(NO_EMBED_HOOK_JS_BYTES.read().encode())
    NO_EMBED_HOOK_JS_BYTES.close()


# 给目的文件中追加一行 "require('./hook')",
# 实现在 Typora 运行时调用注入JS文件
def append_require2file():
    with open(INJECT_JS_PATH, "a+") as f:
        f.write("\nrequire('./hook')")


# 打印警告日志
def warning(strs):
    print("\033[31m->%s\033[0m" % strs)


# 打印日志
def infos(strs):
    print("\033[32m=>%s\033[0m" % strs)


if __name__ == "__main__":
    check_node='type node >/dev/null 2>&1'
    if os.system(check_node)!=0:
        warning('未找到 node')
        sys.exit(0)
    else:
        infos('找到 node')

    infos("Typora 安装路径: "+TYPORA_INSTALLED_PATH)
    file_mkdir(BUILD_DIR)
    file_mkdir(BACKUP_DIR)
    if file_exist(INJECT_JS_DIR_PATH):
        warning('您可能已经注入过 hook 文件了！')
        warning('警告：在当前目录下发现 node 文件夹')
        infos('您若不确定之前是否注入过该文件的话，请手动删除当前目录下的 node 文件夹(%s)！'%INJECT_JS_DIR_PATH)
        sys.exit(0)
    if not file_exist(INJECT_JS_DIR_ASAR_PATH):
        warning('未找到 node_modules.asar ！')
        warning('请确认 Typora 安装目录下是否正确！!')
        sys.exit(0)
    infos('正在复制%s 至 当前目录下(%s)' % (INJECT_JS_DIR_ASAR_PATH,CUR_INJECT_JS_DIR_ASAR_PATH))
    if os.system('sudo cp %s %s' %(INJECT_JS_DIR_ASAR_PATH,CUR_INJECT_JS_DIR_ASAR_PATH))==0:
        infos('复制成功！')
        os.system('cp %s %s'%(CUR_INJECT_JS_DIR_ASAR_PATH,BACKUP_DIR))
    else:
        warning('当执行 %s 时发生错误' % ('sudo cp %s %s' %(INJECT_JS_DIR_ASAR_PATH,CUR_INJECT_JS_DIR_ASAR_PATH)))
        sys.exit(0)

    infos('正在解压 node_modues.asar')
    rphrase='node ./asar_modules/node_modules/@electron/asar/bin/asar.js extract %s %s'%(CUR_INJECT_JS_DIR_ASAR_PATH,INJECT_JS_DIR_PATH)
    ret=os.popen(rphrase)
    warning(ret.read())
    infos('成功解压至 node 文件夹中！')

    infos('正在将 hook.js 添加至 node 文件夹中...')
    infos('正在将依赖添加到 node/raven/index.js...')
    
    if embed_mode:
        embed_write_js2file()
    else:
        no_embed_write_js2file()
    append_require2file()

    infos('添加 hook.js 成功！')
    infos('依赖添加到 node/raven/index.js 成功！')

    infos('正在重新打包 node 文件夹至 node_modules.asar...')
    phrase='rm %s;node ./asar_modules/node_modules/@electron/asar/bin/asar.js pack %s %s'% (CUR_INJECT_JS_DIR_ASAR_PATH,INJECT_JS_DIR_PATH,CUR_INJECT_JS_DIR_ASAR_PATH)
    ret2=os.popen(phrase)
    warning(ret2.read())
    infos('打包完成！')

    warning("###### 正在将 $CUR_INJECT_ASAR_PATH 移动至 $INJECT_JS_DIR_ASAR_PATH ######")
    do_cp_p='sudo cp %s %s'%(CUR_INJECT_JS_DIR_ASAR_PATH,INJECT_JS_DIR_ASAR_PATH)
    do_cp_ret=os.popen(do_cp_p)
    warning(do_cp_ret.read())
    warning("若执行当前脚本后不能正常打开软件的话，则请执行以下命令还原：")
    warning("\tcp ./build/backup/node_modules.asar %s\n" %(INJECT_JS_DIR_ASAR_PATH))

    infos("您的序列号为：")
    infos("\tLSGDW2-6M43UN-KHKH2A-D6FDJF")
    infos("\tD9KYN9-MCCL2F-59LFPC-NK2CPX\n")
    warning("如果激活失败，恐怕您还得安装 rust 环境并使用 license-gen/target/debug/license-gen 生成新的序列号")
