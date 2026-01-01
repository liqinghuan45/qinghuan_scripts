@echo off
chcp 65001 >nul
REM Git 和 GitHub CLI 安装脚本 (Windows)

setlocal enabledelayedexpansion

REM 解析命令行参数
:parse_args
if "%~1"=="--skip-git" (
    set "SKIP_GIT=1"
    shift
    goto :parse_args
)
if "%~1"=="--skip-gh" (
    set "SKIP_GH=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="/?" goto :show_help
if not "%~1"=="" goto :parse_args
goto :args_done

:show_help
echo 用法: %~nx0 [选项]
echo.
echo 选项:
echo   --skip-git       跳过 Git 安装
echo   --skip-gh        跳过 GitHub CLI 安装
echo   -h, --help, /?   显示此帮助信息
echo.
echo 示例:
echo   %~nx0              # 安装 Git 和 GitHub CLI
echo   %~nx0 --skip-gh    # 只安装 Git
echo   %~nx0 --skip-git   # 只安装 GitHub CLI
exit /b 0

:args_done

REM 颜色定义
set "INFO=[信息]"
set "SUCCESS=[成功]"
set "WARNING=[警告]"
set "ERROR=[错误]"
set "INSTALL=[安装]"

REM 显示开始信息
echo ========================================
echo   Git 和 GitHub CLI 安装脚本
echo ========================================
echo 将安装以下工具:
if not defined SKIP_GIT echo   - Git (最新版)
if not defined SKIP_GH echo   - GitHub CLI (gh)
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% 此脚本需要管理员权限运行
    echo 请右键点击此脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

REM ========================================
REM 安装 Git
REM ========================================
if defined SKIP_GIT (
    echo %INFO% 跳过 Git 安装
) else (
    echo.
    echo ========================================
    echo         安装 Git
    echo ========================================

    echo %INSTALL% 检查 Git 是否已安装...
    where git >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('git --version') do echo %SUCCESS% Git 已安装: %%i
        echo %INFO% 如需重新安装，请先卸载现有版本
    ) else (
        echo %INSTALL% 下载 Git 安装程序...
        set "GIT_URL=https://github.com/git-for-windows/git/releases/latest/download/Git-2.47.1-64-bit.exe"
        set "GIT_INSTALLER=%TEMP%\git-installer.exe"

        powershell -Command "Invoke-WebRequest -Uri '%GIT_URL%' -OutFile '%GIT_INSTALLER%'"
        if %errorlevel% neq 0 (
            echo %ERROR% Git 下载失败
            pause
            exit /b 1
        )

        echo %INSTALL% 安装 Git...
        REM 静默安装 Git，配置默认选项
        "%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /COMPONENTS="ext,ext\shellhere,ext\guihere,assoc,assoc_sh,sysenv" /DefaultInOption=CheckoutASCII /DefaultOutOption=CheckoutASCII /AutoCrlf=0 /NoIcons=1
        if %errorlevel% neq 0 (
            echo %ERROR% Git 安装失败
            pause
            exit /b 1
        )

        del "%GIT_INSTALLER%"
        echo %SUCCESS% Git 安装完成

        REM 配置 Git
        echo %INSTALL% 配置 Git 默认设置...
        git config --global core.autocrlf false 2>nul
        git config --global init.defaultBranch main 2>nul
        git config --global core.editor "notepad" 2>nul

        echo %SUCCESS% Git 配置完成

        REM 刷新环境变量
        refreshenv >nul 2>&1
    )
)

REM ========================================
REM 安装 GitHub CLI
REM ========================================
if defined SKIP_GH (
    echo %INFO% 跳过 GitHub CLI 安装
) else (
    echo.
    echo ========================================
    echo         安装 GitHub CLI
    echo ========================================

    echo %INSTALL% 检查 GitHub CLI 是否已安装...
    where gh >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('gh --version') do echo %SUCCESS% GitHub CLI 已安装: %%i
    ) else (
        echo %INSTALL% 下载 GitHub CLI 安装程序...
        set "GH_URL=https://github.com/cli/cli/releases/latest/download/gh_2.60.1_windows_amd64.msi"
        set "GH_INSTALLER=%TEMP%\gh-installer.msi"

        powershell -Command "Invoke-WebRequest -Uri '%GH_URL%' -OutFile '%GH_INSTALLER%'"
        if %errorlevel% neq 0 (
            echo %ERROR% GitHub CLI 下载失败
            pause
            exit /b 1
        )

        echo %INSTALL% 安装 GitHub CLI...
        msiexec /i "%GH_INSTALLER%" /quiet /norestart
        if %errorlevel% neq 0 (
            echo %ERROR% GitHub CLI 安装失败
            pause
            exit /b 1
        )

        del "%GH_INSTALLER%"
        echo %SUCCESS% GitHub CLI 安装完成

        REM 刷新环境变量
        refreshenv >nul 2>&1
    )
)

REM ========================================
REM 验证安装
REM ========================================
echo.
echo ========================================
echo         验证安装
echo ========================================

if not defined SKIP_GIT (
    echo %INFO% 检查 Git...
    where git >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('git --version') do echo %SUCCESS% %%i

        echo %INFO% Git 配置信息:
        for /f "delims=" %%i in ('git config --global user.name 2^>nul') do (
            echo   用户名: %%i
        )
        for /f "delims=" %%i in ('git config --global user.email 2^>nul') do (
            echo   邮箱: %%i
        )

        REM 检查是否已配置用户信息
        git config --global user.name >nul 2>&1
        if %errorlevel% neq 0 (
            echo.
            echo %WARNING% Git 用户信息未配置
            echo %INFO% 建议配置 Git 用户信息:
            echo   git config --global user.name "Your Name"
            echo   git config --global user.email "your_email@example.com"
        )
    ) else (
        echo %WARNING% Git 未找到
    )
)

if not defined SKIP_GH (
    echo %INFO% 检查 GitHub CLI...
    where gh >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "tokens=1,2,3" %%i in ('gh --version') do echo %SUCCESS% GitHub CLI %%i %%j %%k

        REM 检查是否已登录
        gh auth status >nul 2>&1
        if %errorlevel% neq 0 (
            echo.
            echo %WARNING% GitHub CLI 未登录
            echo %INFO% 使用以下命令登录:
            echo   gh auth login
        ) else (
            echo %SUCCESS% GitHub CLI 已登录
        )
    ) else (
        echo %WARNING% GitHub CLI 未找到
    )
)

echo.
echo ========================================
echo %SUCCESS% 🎉 安装完成！
echo ========================================
echo.

REM 显示常用命令
echo %INFO% 常用 Git 命令:
echo   git init                    # 初始化仓库
echo   git clone ^<url^>            # 克隆仓库
echo   git add .                   # 添加所有更改
echo   git commit -m "message"     # 提交更改
echo   git push                    # 推送到远程
echo   git pull                    # 拉取更新
echo.

echo %INFO% 常用 GitHub CLI 命令:
echo   gh auth login               # 登录 GitHub
echo   gh repo create              # 创建仓库
echo   gh pr create                # 创建 Pull Request
echo   gh issue create             # 创建 Issue
echo   gh repo clone ^<owner/repo^> # 克隆仓库
echo.

pause
