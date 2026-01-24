@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul 2>&1
title 一键部署（本地覆盖远程版）- 出错会暂停

:: ====================== 核心配置（确认无误后保留）======================
set "deploy_path=D:\其他\桌面文件\毛毛\Trae Projects\01\02\CN"
set "github_repo=https://github.com/MaoxiChen2025/Maoxichen2025.github.io.git"
set "github_branch=master"  :: 本地/远程分支保持一致
set "git_user_name=MaoxiChen2025"
set "git_user_email=2662772508@qq.com"
:: ======================================================================

echo ==============================================
echo 【部署模式】本地文件将直接覆盖远程仓库同名文件！
echo 按任意键开始检查...
pause > nul

:: 1. 检查Git安装
echo ==============================================
echo 正在检查Git是否安装...
git --version > nul 2>&1
if errorlevel 1 (
    echo 【错误】未检测到Git！请安装并添加到环境变量。
    pause
    exit /b 1
)
echo Git安装正常！

:: 2. 检查网络（能否访问GitHub）
echo ==============================================
echo 正在检测网络...
ping github.com -n 2 -w 1000 > nul 2>&1
if errorlevel 1 (
    echo 【错误】无法访问GitHub！请检查网络。
    pause
    exit /b 1
)
echo 网络正常！

:: 3. 检查部署路径
echo ==============================================
echo 正在检查部署路径：%deploy_path%
if not exist "%deploy_path%" (
    echo 【错误】部署路径不存在！
    pause
    exit /b 1
)
pushd "%deploy_path%"
echo 当前工作目录：%cd%

:: 4. 初始化Git仓库（若未初始化）
echo ==============================================
echo 正在检查Git仓库...
if not exist ".git" (
    git init
    git remote add origin %github_repo%
    echo Git仓库初始化并关联远程成功！
) else (
    echo 本地已关联Git仓库，跳过初始化。
)

:: 5. 配置Git身份
echo ==============================================
echo 正在配置Git身份...
git config --global user.name "%git_user_name%"
git config --global user.email "%git_user_email%"
:: 验证身份
set "check_name="
for /f "tokens=*" %%i in ('git config --global user.name') do set "check_name=%%i"
if "%check_name%"=="" (
    echo 【错误】Git用户名配置失败！
    pause
    popd
    exit /b 1
)
echo Git身份配置成功：%check_name%

:: 6. 展示本地文件列表（CN/相对路径+无序列表）
echo ==============================================
echo 【本地待部署文件（将覆盖远程）】：
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

:: 7. 用户最终确认
set "confirm="
set /p "confirm=确认用本地文件覆盖远程仓库？(输入Y继续)："
if /i not "%confirm%"=="Y" (
    echo 取消部署，按任意键退出...
    pause > nul
    popd
    exit /b 0
)

:: 8. 核心部署：提交+强制推送（覆盖远程）
echo ==============================================
echo 正在添加所有文件到暂存区...
git add .

echo 正在提交本地文件...
set "commit_msg=本地覆盖远程 - %date% %time%"
git commit -m "%commit_msg%"
if errorlevel 1 (
    echo 提示：无文件变更，无需提交！
) else (
    echo 提交成功！
)

echo 正在强制推送（本地覆盖远程）...
git push -f origin %github_branch%
if errorlevel 1 (
    echo 【错误】推送失败！请检查：
    echo 1. GitHub账号是否有权限（推荐配置SSH密钥）
    echo 2. 分支名称是否正确（当前是%github_branch%）
    pause
    popd
    exit /b 1
)

:: 部署成功
echo ==============================================
echo ✅ 部署成功！本地文件已覆盖远程仓库！
echo 仓库地址：%github_repo%
echo 访问地址：https://maoxichen2025.github.io
echo ==============================================
popd
pause
exit /b 0