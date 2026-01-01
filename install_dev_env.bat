@echo off
chcp 65001 >nul
REM 开发环境一键安装脚本 (Windows)
REM 安装 Python 3.12、Node.js、Go、Rust

setlocal enabledelayedexpansion

REM 解析命令行参数
:parse_args
if "%~1"=="--skip-python" (
    set "SKIP_PYTHON=1"
    shift
    goto :parse_args
)
if "%~1"=="--skip-nodejs" (
    set "SKIP_NODEJS=1"
    shift
    goto :parse_args
)
if "%~1"=="--skip-go" (
    set "SKIP_GO=1"
    shift
    goto :parse_args
)
if "%~1"=="--skip-rust" (
    set "SKIP_RUST=1"
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
echo   --skip-python    跳过 Python 安装
echo   --skip-nodejs    跳过 Node.js 安装
echo   --skip-go        跳过 Go 安装
echo   --skip-rust      跳过 Rust 安装
echo   -h, --help, /?   显示此帮助信息
echo.
echo 示例:
echo   %~nx0                    # 安装所有语言
echo   %~nx0 --skip-rust        # 安装除 Rust 外的所有语言
echo   %~nx0 --skip-python --skip-go  # 只安装 Node.js 和 Rust
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
echo   开发环境一键安装脚本
echo ========================================
echo 将安装以下开发语言:
if not defined SKIP_PYTHON echo   - Python 3.12
if not defined SKIP_NODEJS echo   - Node.js (LTS)
if not defined SKIP_GO echo   - Go (最新版)
if not defined SKIP_RUST echo   - Rust (最新版)
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
REM 安装 Python 3.12
REM ========================================
if defined SKIP_PYTHON (
    echo %INFO% 跳过 Python 安装
) else (
    echo.
    echo ========================================
    echo         安装 Python 3.12
    echo ========================================

    echo %INSTALL% 检查 Python 是否已安装...
    where python >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "PY_VER=%%i"
        echo %SUCCESS% Python 已安装: %PY_VER%
        echo %INFO% 如需重新安装，请先卸载现有版本
    ) else (
        echo %INSTALL% 下载 Python 3.12 安装程序...
        set "PY_URL=https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe"
        set "PY_INSTALLER=%TEMP%\python-3.12.8-amd64.exe"

        powershell -Command "Invoke-WebRequest -Uri '%PY_URL%' -OutFile '%PY_INSTALLER%'"
        if %errorlevel% neq 0 (
            echo %ERROR% Python 下载失败
            pause
            exit /b 1
        )

        echo %INSTALL% 安装 Python 3.12...
        "%PY_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
        if %errorlevel% neq 0 (
            echo %ERROR% Python 安装失败
            pause
            exit /b 1
        )

        del "%PY_INSTALLER%"
        echo %SUCCESS% Python 3.12 安装完成

        REM 刷新环境变量
        refreshenv >nul 2>&1
    )
)

REM ========================================
REM 安装 Node.js
REM ========================================
if defined SKIP_NODEJS (
    echo %INFO% 跳过 Node.js 安装
) else (
    echo.
    echo ========================================
    echo         安装 Node.js (LTS)
    echo ========================================

    echo %INSTALL% 检查 Node.js 是否已安装...
    where node >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('node --version') do echo %SUCCESS% Node.js 已安装: %%i
    ) else (
        echo %INSTALL% 下载 Node.js LTS 安装程序...
        set "NODE_URL=https://nodejs.org/dist/latest-v22.x/node-v22-x64.msi"
        set "NODE_INSTALLER=%TEMP%\nodejs-installer.msi"

        powershell -Command "Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%NODE_INSTALLER%'"
        if %errorlevel% neq 0 (
            echo %ERROR% Node.js 下载失败
            pause
            exit /b 1
        )

        echo %INSTALL% 安装 Node.js...
        msiexec /i "%NODE_INSTALLER%" /quiet /norestart
        if %errorlevel% neq 0 (
            echo %ERROR% Node.js 安装失败
            pause
            exit /b 1
        )

        del "%NODE_INSTALLER%"
        echo %SUCCESS% Node.js 安装完成

        REM 刷新环境变量
        refreshenv >nul 2>&1
    )
)

REM ========================================
REM 安装 Go
REM ========================================
if defined SKIP_GO (
    echo %INFO% 跳过 Go 安装
) else (
    echo.
    echo ========================================
    echo         安装 Go
    echo ========================================

    echo %INSTALL% 检查 Go 是否已安装...
    where go >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('go version') do echo %SUCCESS% Go 已安装: %%i
    ) else (
        echo %INSTALL% 下载 Go 安装程序...
        set "GO_URL=https://go.dev/dl/go1.23.4.windows-amd64.msi"
        set "GO_INSTALLER=%TEMP%\go-installer.msi"

        powershell -Command "Invoke-WebRequest -Uri '%GO_URL%' -OutFile '%GO_INSTALLER%'"
        if %errorlevel% neq 0 (
            echo %ERROR% Go 下载失败
            pause
            exit /b 1
        )

        echo %INSTALL% 安装 Go...
        msiexec /i "%GO_INSTALLER%" /quiet /norestart
        if %errorlevel% neq 0 (
            echo %ERROR% Go 安装失败
            pause
            exit /b 1
        )

        del "%GO_INSTALLER%"
        echo %SUCCESS% Go 安装完成

        REM 设置 GOPATH
        setx GOPATH "%USERPROFILE%\go" >nul
        setx PATH "%PATH%;%USERPROFILE%\go\bin" >nul

        REM 刷新环境变量
        refreshenv >nul 2>&1
    )
)

REM ========================================
REM 安装 Rust
REM ========================================
if defined SKIP_RUST (
    echo %INFO% 跳过 Rust 安装
) else (
    echo.
    echo ========================================
    echo         安装 Rust
    echo ========================================

    echo %INSTALL% 检查 Rust 是否已安装...
    where cargo >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('cargo --version') do echo %SUCCESS% Rust 已安装: %%i
    ) else (
        echo %INSTALL% 下载并安装 Rust (通过 rustup)...
        set "RUSTUP_URL=https://win.rustup.rs/x86_64"

        REM 使用 rustup-init 安装 Rust
        powershell -Command "Invoke-WebRequest -Uri '%RUSTUP_URL%' -OutFile '%TEMP%\rustup-init.exe'"
        if %errorlevel% neq 0 (
            echo %ERROR% Rustup 下载失败
            pause
            exit /b 1
        )

        echo %INSTALL% 安装 Rust...
        "%TEMP%\rustup-init.exe" --default-toolchain stable --profile default -y
        if %errorlevel% neq 0 (
            echo %ERROR% Rust 安装失败
            pause
            exit /b 1
        )

        del "%TEMP%\rustup-init.exe"
        echo %SUCCESS% Rust 安装完成

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

if not defined SKIP_PYTHON (
    echo %INFO% 检查 Python...
    where python >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "tokens=2" %%i in ('python --version 2^>^&1') do echo %SUCCESS% Python: %%i
    ) else (
        echo %WARNING% Python 未找到
    )

    echo %INFO% 检查 pip...
    where pip >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('pip --version') do echo %SUCCESS% %%i
    ) else (
        echo %WARNING% pip 未找到
    )
)

if not defined SKIP_NODEJS (
    echo %INFO% 检查 Node.js...
    where node >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('node --version') do echo %SUCCESS% Node.js: %%i
    ) else (
        echo %WARNING% Node.js 未找到
    )

    echo %INFO% 检查 npm...
    where npm >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('npm --version') do echo %SUCCESS% npm: %%i
    ) else (
        echo %WARNING% npm 未找到
    )
)

if not defined SKIP_GO (
    echo %INFO% 检查 Go...
    where go >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('go version') do echo %SUCCESS% %%i
    ) else (
        echo %WARNING% Go 未找到
    )
)

if not defined SKIP_RUST (
    echo %INFO% 检查 Rust...
    where cargo >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('cargo --version') do echo %SUCCESS% %%i
    ) else (
        echo %WARNING% Rust/Cargo 未找到
    )
)

echo.
echo ========================================
echo %SUCCESS% 🎉 开发环境安装完成！
echo ========================================
echo.
echo %INFO% 请重新启动命令提示符以使用新安装的工具
echo.

pause
