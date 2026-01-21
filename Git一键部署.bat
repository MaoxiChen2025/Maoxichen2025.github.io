@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul 2>&1
title 一键部署（含网络检测）- 出错会暂停

:: ====================== 核心配置 =======================
set "deploy_path=D:\其他\桌面文件\毛毛\Trae Projects\01\02\CN"
set "github_repo=https://github.com/MaoxiChen2025/Maoxichen2025.github.io.git"
set "github_branch=master"
set "git_user_name=MaoxiChen2025"
set "git_user_email=2662772508@qq.com"
:: =======================================================

echo ==============================================
echo 【调试模式】即将开始检查，按任意键继续...
pause > nul

:: 检查Git是否安装
echo ==============================================
echo 正在检查Git是否安装...
git --version
if errorlevel 1 (
    echo 【错误】未检测到Git！请先安装Git并添加到环境变量。
    pause
    exit /b 1
)
echo Git安装正常！

:: --------------- 新增：检测是否能访问GitHub（仓库所在平台）---------------
echo ==============================================
echo 正在检测网络是否能访问GitHub（仓库依赖此网络）...
:: 尝试ping GitHub 2次，超时1秒
ping github.com -n 2 -w 1000 > nul 2>&1
if errorlevel 1 (
    echo 【错误】网络无法访问GitHub！请检查网络连接后重试。
    pause
    exit /b 1
)
echo 网络正常，可访问GitHub！

:: 检查部署路径是否存在
echo ==============================================
echo 正在检查部署路径：%deploy_path%
if not exist "%deploy_path%" (
    echo 【错误】部署路径不存在！请检查deploy_path配置。
    pause
    exit /b 1
)
echo 路径存在！

:: 切换到部署目录
echo ==============================================
echo 正在切换到部署目录...
pushd "%deploy_path%"
if errorlevel 1 (
    echo 【错误】无法切换到部署目录！
    pause
    exit /b 1
)
echo 当前工作目录：%cd%

:: 检查并初始化Git仓库
echo ==============================================
echo 正在检查并初始化Git仓库...
if not exist ".git" (
    echo 检测到当前目录不是Git仓库，正在初始化...
    git init
    if errorlevel 1 (
        echo 【错误】Git仓库初始化失败！
        pause
        popd
        endlocal
        exit /b 1
    )
    echo Git仓库初始化成功！
    git remote add origin %github_repo%
    if errorlevel 1 (
        echo 警告：远程仓库已关联，跳过关联步骤！
    ) else (
        echo 远程仓库关联成功！
    )
) else (
    echo 当前目录已是Git仓库，跳过初始化。
)

:: 检查并配置Git身份
echo ==============================================
echo 正在配置Git身份...
git config --global user.name "%git_user_name%"
git config --global user.email "%git_user_email%"

set "check_name="
for /f "tokens=*" %%i in ('git config --global user.name') do set "check_name=%%i"
set "check_email="
for /f "tokens=*" %%i in ('git config --global user.email') do set "check_email=%%i"

if "%check_name%"=="" (
    echo 【错误】Git用户名配置失败！
    pause
    popd
    endlocal
    exit /b 1
)
if "%check_email%"=="" (
    echo 【错误】Git邮箱配置失败！
    pause
    popd
    endlocal
    exit /b 1
)
echo Git身份配置成功：用户名=%check_name%，邮箱=%check_email%

:: 本地文件列表
echo ==============================================
echo 【本地待部署文件列表（含所有子文件夹）】：
echo ----------------------------------------------
for /f "tokens=* delims=" %%i in ('dir /a /b /o:d /s "%deploy_path%"') do (
    set "full_path=%%i"
    set "rel_path=!full_path:%deploy_path%\=!"
    if "!rel_path!"=="" (
        echo ● CN/
    ) else (
        echo ● CN/!rel_path!
    )
)
echo ----------------------------------------------
pause > nul

:: 远程文件列表
echo ==============================================
echo 【GitHub远程仓库文件列表（含所有子文件夹）】：
echo ----------------------------------------------
git fetch origin %github_branch% > nul 2>&1
set "remote_empty=1"
for /f "tokens=* delims=" %%i in ('git ls-tree -r --name-only origin/%github_branch% 2^> nul') do (
    echo ● CN/%%i
    set "remote_empty=0"
)
if "%remote_empty%"=="1" (
    echo ● CN/ 提示：远程仓库暂无任何文件（空仓库）
)
echo ----------------------------------------------
pause > nul

:: 用户确认
set "confirm="
set /p "confirm=是否确认部署？(Y继续，其他键退出)："
if /i not "%confirm%"=="Y" (
    echo 取消部署，按任意键退出...
    pause > nul
    popd
    endlocal
    exit /b 0
)

:: 部署流程
echo ==============================================
echo 正在拉取远程仓库最新内容...
git fetch --all
git reset --hard origin/%github_branch% 2> nul
if errorlevel 1 (
    echo 提示：远程仓库为空，无需拉取/重置，继续部署...
)

echo 正在添加所有文件到Git暂存区...
git add .

echo 正在提交文件...
set "commit_msg=更新文件 - %date% %time%"
git commit -m "%commit_msg%"
if errorlevel 1 (
    echo 提示：无文件变更，无需提交！
) else (
    echo 提交成功！
)

echo 正在推送到GitHub仓库...
git push -u origin %github_branch% -f
if errorlevel 1 (
    echo 【错误】推送失败！请检查：
    echo 1. 是否有权限访问该仓库（推荐配置SSH密钥）
    echo 2. 网络是否临时波动（可重试）
    pause
    popd
    endlocal
    exit /b 1
)

echo ==============================================
echo 部署成功！
echo ==============================================
popd
endlocal
pause
exit /b 0