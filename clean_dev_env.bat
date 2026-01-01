@echo off
chcp 65001 >nul
REM 开发环境清理脚本 (Windows)
REM 移除 Python、Node.js、Go、Rust

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
if /i "%~1"=="-y" (
    set "AUTO_CONFIRM=1"
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
echo   --skip-python    跳过 Python 清理
echo   --skip-nodejs    跳过 Node.js 清理
echo   --skip-go        跳过 Go 清理
echo   --skip-rust      跳过 Rust 清理
echo   -y               自动确认，不询问
echo   -h, --help, /?   显示此帮助信息
echo.
echo 示例:
echo   %~nx0                    # 清理所有语言
echo   %~nx0 -y                 # 自动清理所有语言
echo   %~nx0 --skip-rust        # 清理除 Rust 外的所有语言
echo.
echo 警告: 此操作将卸载开发语言，请谨慎使用！
exit /b 0

:args_done

REM 颜色定义
set "INFO=[信息]"
set "SUCCESS=[成功]"
set "WARNING=[警告]"
set "ERROR=[错误]"
set "CLEAN=[清理]"

REM 显示开始信息
echo ========================================
echo   开发环境清理脚本
echo ========================================
echo 将清理以下开发语言:
if not defined SKIP_PYTHON echo   - Python
if not defined SKIP_NODEJS echo   - Node.js
if not defined SKIP_GO echo   - Go
if not defined SKIP_RUST echo   - Rust
echo.
echo %WARNING% 警告: 此操作将卸载开发语言及其配置
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% 此脚本需要管理员权限运行
    echo 请右键点击此脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

REM 确认操作
if not defined AUTO_CONFIRM (
    set /p "CONFIRM=确认继续清理? (y/N): "
    if /i not "!CONFIRM!"=="y" (
        echo %INFO% 操作已取消
        pause
        exit /b 0
    )
)

REM ========================================
REM 清理 Python
REM ========================================
if defined SKIP_PYTHON (
    echo %INFO% 跳过 Python 清理
) else (
    echo.
    echo ========================================
    echo         清理 Python
    echo ========================================

    echo %CLEAN% 停止 Python 相关进程...
    taskkill /F /IM python.exe 2>nul
    taskkill /F /IM pythonw.exe 2>nul

    echo %CLEAN% 卸载 Python...
    REM 查找已安装的 Python 版本
    for /f "delims=" %%i in ('reg query "HKLM\SOFTWARE\Python\PythonCore" 2^>nul ^| findstr /R ".*\\PythonCore$"') do (
        for /f "tokens=2,3" %%a in ('reg query "%%i" /v InstallPath 2^>nul') do (
            set "PY_PATH=%%b"
        )
    )

    REM 通过 Windows Installer 卸载
    for /f "delims=" %%i in ('wmic product where "name like '%%Python%%'" get identify 2^>nul ^| findstr /R "^[0-9]"') do (
        msiexec /x %%i /quiet /norestart
    )

    REM 删除 Python 目录
    if exist "%LOCALAPPDATA%\Programs\Python" (
        rmdir /S /Q "%LOCALAPPDATA%\Programs\Python" 2>nul
        echo %SUCCESS% 已删除: %LOCALAPPDATA%\Programs\Python
    )

    if exist "%APPDATA%\Python" (
        rmdir /S /Q "%APPDATA%\Python" 2>nul
        echo %SUCCESS% 已删除: %APPDATA%\Python
    )

    REM 清理环境变量
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
    set "NEW_PATH=!SYS_PATH:Python=!"
    setx PATH "!NEW_PATH!" >nul 2>&1

    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%b"
    set "NEW_PATH=!USR_PATH:Python=!"
    setx PATH "!NEW_PATH!" >nul 2>&1

    echo %SUCCESS% Python 清理完成
)

REM ========================================
REM 清理 Node.js
REM ========================================
if defined SKIP_NODEJS (
    echo %INFO% 跳过 Node.js 清理
) else (
    echo.
    echo ========================================
    echo         清理 Node.js
    echo ========================================

    echo %CLEAN% 停止 Node.js 相关进程...
    taskkill /F /IM node.exe 2>nul
    taskkill /F /IM npm.cmd 2>nul

    echo %CLEAN% 卸载 Node.js...
    REM 通过 Windows Installer 卸载
    for /f "delims=" %%i in ('wmic product where "name like '%%Node.js%%'" get identify 2^>nul ^| findstr /R "^[0-9]"') do (
        msiexec /x %%i /quiet /norestart
    )

    REM 删除 Node.js 目录
    if exist "%PROGRAMFILES%\nodejs" (
        rmdir /S /Q "%PROGRAMFILES%\nodejs" 2>nul
        echo %SUCCESS% 已删除: %PROGRAMFILES%\nodejs
    )

    if exist "%PROGRAMFILES(X86)%\nodejs" (
        rmdir /S /Q "%PROGRAMFILES(X86)%\nodejs" 2>nul
        echo %SUCCESS% 已删除: %PROGRAMFILES(X86)%\nodejs
    )

    REM 删除 npm 缓存
    if exist "%APPDATA%\npm-cache" (
        rmdir /S /Q "%APPDATA%\npm-cache" 2>nul
        echo %SUCCESS% 已删除: %APPDATA%\npm-cache
    )

    REM 清理环境变量
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
    set "NEW_PATH=!SYS_PATH:nodejs=!"
    setx PATH "!NEW_PATH!" >nul 2>&1

    echo %SUCCESS% Node.js 清理完成
)

REM ========================================
REM 清理 Go
REM ========================================
if defined SKIP_GO (
    echo %INFO% 跳过 Go 清理
) else (
    echo.
    echo ========================================
    echo         清理 Go
    echo ========================================

    echo %CLEAN% 停止 Go 相关进程...
    taskkill /F /IM go.exe 2>nul

    echo %CLEAN% 卸载 Go...
    REM 通过 Windows Installer 卸载
    for /f "delims=" %%i in ('wmic product where "name like '%%Go Programming Language%%'" get identify 2^>nul ^| findstr /R "^[0-9]"') do (
        msiexec /x %%i /quiet /norestart
    )

    REM 删除 Go 目录
    if exist "C:\Program Files\Go" (
        rmdir /S /Q "C:\Program Files\Go" 2>nul
        echo %SUCCESS% 已删除: C:\Program Files\Go
    )

    if exist "C:\Program Files (x86)\Go" (
        rmdir /S /Q "C:\Program Files (x86)\Go" 2>nul
        echo %SUCCESS% 已删除: C:\Program Files (x86)\Go
    )

    REM 删除 GOPATH
    if exist "%USERPROFILE%\go" (
        rmdir /S /Q "%USERPROFILE%\go" 2>nul
        echo %SUCCESS% 已删除: %USERPROFILE%\go
    )

    REM 清理环境变量
    setx GOPATH "" >nul 2>&1

    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
    set "NEW_PATH=!SYS_PATH:Go=!"
    setx PATH "!NEW_PATH!" >nul 2>&1

    echo %SUCCESS% Go 清理完成
)

REM ========================================
REM 清理 Rust
REM ========================================
if defined SKIP_RUST (
    echo %INFO% 跳过 Rust 清理
) else (
    echo.
    echo ========================================
    echo         清理 Rust
    echo ========================================

    echo %CLEAN% 停止 Rust 相关进程...
    taskkill /F /IM cargo.exe 2>nul
    taskkill /F /IM rustc.exe 2>nul

    echo %CLEAN% 卸载 Rust...
    if exist "%USERPROFILE%\.cargo\bin\rustup.exe" (
        "%USERPROFILE%\.cargo\bin\rustup.exe" self uninstall -y
        echo %SUCCESS% Rust 已通过 rustup 卸载
    )

    REM 删除 Rust 目录
    if exist "%USERPROFILE%\.rustup" (
        rmdir /S /Q "%USERPROFILE%\.rustup" 2>nul
        echo %SUCCESS% 已删除: %USERPROFILE%\.rustup
    )

    if exist "%USERPROFILE%\.cargo" (
        rmdir /S /Q "%USERPROFILE%\.cargo" 2>nul
        echo %SUCCESS% 已删除: %USERPROFILE%\.cargo
    )

    REM 清理环境变量
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%b"
    set "NEW_PATH=!USR_PATH:.cargo\bin=!"
    setx PATH "!NEW_PATH!" >nul 2>&1

    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
    set "NEW_PATH=!SYS_PATH:.cargo\bin=!"
    setx PATH "!NEW_PATH!" >nul 2>&1

    echo %SUCCESS% Rust 清理完成
)

REM ========================================
REM 验证清理结果
REM ========================================
echo.
echo ========================================
echo         验证清理结果
echo ========================================

if not defined SKIP_PYTHON (
    echo %INFO% 检查 Python...
    where python >nul 2>&1
    if %errorlevel% equ 0 (
        echo %WARNING% Python 仍然存在
    ) else (
        echo %SUCCESS% Python 已清理
    )
)

if not defined SKIP_NODEJS (
    echo %INFO% 检查 Node.js...
    where node >nul 2>&1
    if %errorlevel% equ 0 (
        echo %WARNING% Node.js 仍然存在
    ) else (
        echo %SUCCESS% Node.js 已清理
    )
)

if not defined SKIP_GO (
    echo %INFO% 检查 Go...
    where go >nul 2>&1
    if %errorlevel% equ 0 (
        echo %WARNING% Go 仍然存在
    ) else (
        echo %SUCCESS% Go 已清理
    )
)

if not defined SKIP_RUST (
    echo %INFO% 检查 Rust...
    where cargo >nul 2>&1
    if %errorlevel% equ 0 (
        echo %WARNING% Rust 仍然存在
    ) else (
        echo %SUCCESS% Rust 已清理
    )
)

echo.
echo ========================================
echo %SUCCESS% 🎉 开发环境清理完成！
echo ========================================
echo.
echo %INFO% 请重新启动命令提示符以使更改生效
echo.

pause
