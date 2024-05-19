:: ####### 作者声明 #########
:: a copied script for windows.
:: made by hazukie
:: date: 2024.5.12
:: JUST FOR LEARNING PURPOSES, DON'T USE THIS TO CRACK SOFTWARE.
:: 只是出于学习目的，请勿将其用于破解软件，否则后果自负。用户行为均与本项目作者无关！

@echo off
call :warning 当前脚本仅适用于 windows 平台，且仅在 windows10 版本下通过测试
call :warning 若在执行过程中出现问题，请及时在项目作者反馈
call :infos 开始执行脚本
:: ####### 作者声明 #########


:: ####### 数据配置 #########
:: 待注入数据文件路径
set CUR_HOOK_JS_PATH=src\hooklog.js
:: ####### 数据配置 #########
:: Typora 安装路径
set TYPORA_INSTALLED_PATH="C:\Program Files\Typora\resources"

::set INJECT_ASAR_PATH=%TYPORA_INSTALLED_PATH:"=%\node_modules.asar

set CUR_INJECT_ASAR_PATH=build\node_modules.asar
set CUR_PACKED_ASAR_PATH=build\node_modules.asar.pack

set CUR_INJECT_JS_DIR_PATH=build\node_modules
set CUR_HOOK_JS_WRITE_PATH=%CUR_INJECT_JS_DIR_PATH%\raven\hook.js
set CUR_INJECT_JS_PATH=%CUR_INJECT_JS_DIR_PATH%\raven\index.js

:: ####### 执行配置 #########

:: Node 安装路径
set NODE_INSTALLED_PATH=C:\Users\hazukie\AppData\Roaming\nvm\v20.10.0\node.exe

:: ASAR 解压缩可执行程序代码存放处
:: Yproject 项目下 asar_modules/node_modules/@electron/asar/bin/
:: 此处使用相对地址,即相对于你执行的位置！
:: asar 解压缩程序将会被 脚本函数 asar_zip 调用
set ASAR_BIN=./asar_modules/node_modules/@electron/asar/bin/asar.js
:: ####### 执行配置 #########



:: ####### 执行开始 #########
call :warning "该脚本包含 sudo 指令,请您确保知悉高危命令执行的后果且承担相关代价"
call :warning "在执行過程中，请您仔细确认相关提示，当提示「即将执行高危命令」时，那么此种情形将考验您的判断力"
call :infos  "Typora 安装路径: " %TYPORA_INSTALLED_PATH%
call :askif "Typora 安装路径是否正确?"
if %ret% equ "0" (
	echo 程序继续执行 ) else (
	call :ask "不正确的话你可以尝试输入新的路径" )

if %ret% neq "0" (
	set TYPORA_INSTALLED_PATH=
	set TYPORA_INSTALLED_PATH=%ret: =%)

call :infos "已确认当前安装路径为: " %TYPORA_INSTALLED_PATH%
set INJECT_ASAR_PATH=
set INJECT_ASAR_PATH=%TYPORA_INSTALLED_PATH:"=%\node_modules.asar
call :infos %INJECT_ASAR_PATH%

:: 检测 node 是否存在
call :ask "请输入 Node 安装路径"
call :infos "你为避免反复确认,可以直接改 NODE_INSTALLED_PATH 的值！！"
set NODE_INSTALLED_PATH=
set NODE_INSTALLED_PATH=%ret: =%
call :infos "Node 安装路径为: " %NODE_INSTALLED_PATH%

call :checkf %NODE_INSTALLED_PATH%
:: 正在测试 node 是否可用...
call :checkf %NODE_INSTALLED_PATH%
%NODE_INSTALLED_PATH% -v

:: 检测 Typora 安装路径是否存在
call :checkf  %TYPORA_INSTALLED_PATH%

:: 前置条件已经准备完毕
:: 正式开始初始化
call :mkinit "%INJECT_ASAR_PATH%"

:: 开始解压缩
call :asar_zip "%INJECT_ASAR_PATH%"
goto :eof
:: ####### 执行结束 #########




:: ####### 函数配置 #########

@rem 打印警告日志
@echo off
:warning
echo ## 警告: %~1%~2
goto :eof

@rem 打印日志
@echo off
:infos
echo 提示: %~1%~2
goto :eof


@rem 询问输入函数
@echo off
:ask
set ret=
set /p ret=%~1:
if "%ret%" equ "" (
	call :warning "您输入为空...请重试！" 
	goto :ask )
goto :eof


@rem 询问是否函数
@rem 参数1: 问题,参数2: 比较条件(可选)
@echo off
:askif
set /p ret=%~1 (y/n): 
if "%ret:~0,1%" neq "y" (
	call :infos "您的回复: %ret%"
	set ret=
	set ret="1" ) else (
	call :infos "您的回复: %ret%"
	set ret=
	set ret="0" )
goto :eof


@rem 文件初始化函数
@echo off
:mkinit
call :infos "正在初始化..."
if exist build (
	call :infos "build 文件夹已经存在"
	call :warning "正在删除 build 文件夹"
	rd /s /q build ) else (
	call :infos "未发现 build 文件夹"
	)
call :infos "正在创建 build 文件夹"
mkdir build
call :infos "build 文件夹创建完成"

if exist build\node_modules (
	call :infos "build/node_modules 文件夹已经存在"
	call :warning "正在删除 build 文件夹"
	rd /s /q build\node_modules ) else (
	call :infos "未发现 build/node_modules 文件夹"
	)
call :infos "正在创建 build/node_modules 文件夹"
mkdir build\node_modules
call :infos "build/node_modules 文件夹创建完成"

call :infos "正在复制 node_modules.asar 至 build 文件夹中..."
copy %1  "%CUR_INJECT_ASAR_PATH%"

goto :eof

@rem 文件存在函数
@echo off
:checkf
call :infos "正在检测 %1 是否存在或可用..."
if exist  %1 (
	call :infos  %1 "文件存在"  ) else (
	call :warning %1 "文件不存在!"
	call :infos "脚本已正常退出..."
	exit 0)
goto :eof


@rem 添加 hook.js
:write_js2file
:: 复制内容至 hook.js 文件
type "%CUR_HOOK_JS_PATH%" > "%CUR_HOOK_JS_WRITE_PATH%"
goto :eof


@rem 添加 hook.js 依赖至 index.js
:append_require2file
:: 添加内容至 index.js 文件
echo /* append hook!*/ >> "%CUR_INJECT_JS_PATH%"
echo require('./hook') >> "%CUR_INJECT_JS_PATH%"
goto :eof



@rem 解压缩执行函数
@rem 参数0：unpack/pack
@rem 参数1：源
@rem 参数2：目的地
@echo off
:asar_zip
::call :checkf %ASAR_BIN% 
:: 解压 node_modules 到 当前 build 文件夹下
echo %NODE_INSTALLED_PATH% %ASAR_BIN% extract "%CUR_INJECT_ASAR_PATH%" "%CUR_INJECT_JS_DIR_PATH%"

%NODE_INSTALLED_PATH% %ASAR_BIN% extract "%CUR_INJECT_ASAR_PATH%" "%CUR_INJECT_JS_DIR_PATH%"

:: 添加 hook.js
call :write_js2file
:: 添加 index.js
call :append_require2file

:: 重新打包 node_modules 为 node_modules.asar.pack
echo %NODE_INSTALLED_PATH% %ASAR_BIN% pack %CUR_INJECT_JS_DIR_PATH% %CUR_PACKED_ASAR_PATH%
%NODE_INSTALLED_PATH% %ASAR_BIN% pack %CUR_INJECT_JS_DIR_PATH% %CUR_PACKED_ASAR_PATH%


:: 复制到 typora 安装程序
call :infos "正在复制 node_modules.asar.pack 至 Typora 文件夹中..."
copy "%CUR_PACKED_ASAR_PATH%" %1
goto :eof
