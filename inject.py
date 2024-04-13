# made by hazukie
# date: 2024.4.13

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

# 注入 JS 文件路径
HOOK_JS_WRITE_PATH = TYPORA_INSTALLED_PATH+"/node/raven/hook.js"

# 注入 JS 文件的待解压缩包路径
INJECT_JS_DIR_ASAR_PATH =TYPORA_INSTALLED_PATH+"/resources/node_modules.asar"

# 注入 JS 文件的文件夹路径
INJECT_JS_DIR_PATH = TYPORA_INSTALLED_PATH+"/node"

# 注入JS文件的目的文件路径
INJECT_JS_PATH = TYPORA_INSTALLED_PATH+"/node/raven/index.js"

###------配置结束------###


import os
import sys

# 判断文件是否存在
# file_path: 文件名
def file_exist(file_path):
    return os.path.exists(file_path)


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
    print("\033[31m%s\033[0m" % strs)


# 打印日志
def infos(strs):
    print("\033[32m%s\033[0m" % strs)


if __name__ == "__main__":
    warning("您需要使用 sudo python inject.py 运行！")
    infos("Typora 安装路径: "+TYPORA_INSTALLED_PATH)
    if file_exist(INJECT_JS_DIR_PATH):
        warning('您可能已经注入过 hook 文件了！\n警告：在当前目录下发现 node 文件夹')
        infos('您若不确定之前是否注入过该文件的话，请手动删除当前目录下的 node 文件夹(%s)！'%INJECT_JS_DIR_PATH)
        sys.exit(0)
    if not file_exist(INJECT_JS_DIR_ASAR_PATH):
        warning('未找到 node_modules.asar ！')
        warning('请将我(inject.py) 移动到 Typora 安装目录下!')
        sys.exit(0)

    infos('正在解压 node_modues.asar')
    rphrase='sudo node ./asar_modules/node_modules/@electron/asar/bin/asar.js extract %s %s'%(INJECT_JS_DIR_ASAR_PATH,INJECT_JS_DIR_PATH)
    infos(rphrase)
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
    phrase='sudo node ./asar_modules/node_modules/@electron/asar/bin/asar.js pack %s %s'% (INJECT_JS_DIR_PATH,INJECT_JS_DIR_ASAR_PATH)
    infos(phrase)
    ret2=os.popen(phrase)
    warning(ret2.read())
    infos('打包完成！')
