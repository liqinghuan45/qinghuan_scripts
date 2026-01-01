@echo off
chcp 65001 >nul
REM 系统信息检查脚本 (Windows)
REM 检查硬件、软件、开发环境等信息

setlocal enabledelayedexpansion

REM 颜色定义
set "INFO=[信息]"
set "SUCCESS=[成功]"
set "WARNING=[警告]"
set "ERROR=[错误]"
set "CHECK=[检查]"
set "FOUND=[已安装]"
set "NOT_FOUND=[未安装]"

REM ========================================
echo ========================================
echo           系统信息检查工具
echo ========================================
echo.

REM ========================================
REM 1. 系统硬件信息
REM ========================================
echo ========================================
echo         1. 系统硬件信息
echo ========================================

echo %CHECK% 操作系统...
for /f "tokens=2 delims==" %%i in ('wmic os get Caption /value ^| find "Caption="') do echo   操作系统: %%i
for /f "tokens=2 delims==" %%i in ('wmic os get Version /value ^| find "Version="') do echo   系统版本: %%i
for /f "tokens=2 delims==" %%i in ('wmic os get OSArchitecture /value ^| find "OSArchitecture="') do echo   系统架构: %%i

echo.
echo %CHECK% CPU 信息...
for /f "tokens=2 delims==" %%i in ('wmic cpu get Name /value ^| find "Name="') do echo   CPU 型号: %%i
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfCores /value ^| find "NumberOfCores="') do echo   CPU 核心数: %%i
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value ^| find "NumberOfLogicalProcessors="') do echo   逻辑处理器: %%i

echo.
echo %CHECK% 内存信息...
for /f "tokens=2 delims==" %%i in ('wmic computersystem get TotalPhysicalMemory /value ^| find "TotalPhysicalMemory="') do (
    set /a "RAM_MB=%%i/1024/1024"
    echo   总内存: !RAM_MB! MB
)
for /f "tokens=2 delims==" %%i in ('wmic os get FreePhysicalMemory /value ^| find "FreePhysicalMemory="') do (
    set /a "FREE_MB=%%i/1024"
    echo   可用内存: !FREE_MB! MB
)

echo.
echo %CHECK% 磁盘信息...
for /f "skip=1 tokens=1,2,3" %%i in ('wmic logicaldisk get DeviceID,Size,FreeSpace') do (
    if "%%i" neq "" (
        set /a "DISK_SIZE_GB=%%j/1024/1024/1024"
        set /a "DISK_FREE_GB=%%k/1024/1024/1024"
        echo   驱动器 %%i: 总容量 !DISK_SIZE_GB! GB, 可用 !DISK_FREE_GB! GB
    )
)

REM ========================================
REM 2. Windows 包管理器
REM ========================================
echo.
echo ========================================
echo         2. Windows 包管理器
echo ========================================

echo %CHECK% 检查 winget...
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo %FOUND% winget 已安装
    for /f "delims=" %%i in ('winget --version') do echo   版本: %%i
) else (
    echo %NOT_FOUND% winget 未安装
)

REM ========================================
REM 3. 编程语言检查
REM ========================================
echo.
echo ========================================
echo         3. 编程语言检查
echo ========================================

echo %CHECK% 检查 Python...
where python >nul 2>&1
if %errorlevel% equ 0 (
    echo %FOUND% Python 已安装
    for /f "delims=" %%i in ('python --version 2^>^&1') do echo   %%i
    where python 2>nul
) else (
    echo %NOT_FOUND% Python 未安装
)

echo.
echo %CHECK% 检查 Node.js...
where node >nul 2>&1
if %errorlevel% equ 0 (
    echo %FOUND% Node.js 已安装
    for /f "delims=" %%i in ('node --version') do echo   Node.js %%i
    for /f "delims=" %%i in ('npm --version') do echo   npm %%i
    where node 2>nul
) else (
    echo %NOT_FOUND% Node.js 未安装
)

echo.
echo %CHECK% 检查 Go...
where go >nul 2>&1
if %errorlevel% equ 0 (
    echo %FOUND% Go 已安装
    for /f "delims=" %%i in ('go version') do echo   %%i
    where go 2>nul
    if defined GOPATH (
        echo   GOPATH: %GOPATH%
    )
) else (
    echo %NOT_FOUND% Go 未安装
)

echo.
echo %CHECK% 检查 Rust...
where cargo >nul 2>&1
if %errorlevel% equ 0 (
    echo %FOUND% Rust 已安装
    for /f "delims=" %%i in ('cargo --version') do echo   %%i
    where cargo 2>nul
    for /f "delims=" %%i in ('rustc --version 2^>nul') do echo   %%i
) else (
    echo %NOT_FOUND% Rust 未安装
)

REM ========================================
REM 4. Git 工具检查
REM ========================================
echo.
echo ========================================
echo         4. Git 工具检查
echo ========================================

echo %CHECK% 检查 Git...
where git >nul 2>&1
if %errorlevel% equ 0 (
    echo %FOUND% Git 已安装
    for /f "delims=" %%i in ('git --version') do echo   %%i
    where git 2>nul

    echo.
    echo %CHECK% Git 配置信息:
    for /f "delims=" %%i in ('git config --global user.name 2^>nul') do (
        echo   用户名: %%i
    )
    for /f "delims=" %%i in ('git config --global user.email 2^>nul') do (
        echo   邮箱: %%i
    )
) else (
    echo %NOT_FOUND% Git 未安装
)

echo.
echo %CHECK% 检查 GitHub CLI...
where gh >nul 2>&1
if %errorlevel% equ 0 (
    echo %FOUND% GitHub CLI 已安装
    for /f "tokens=1,2,3" %%i in ('gh --version') do echo   GitHub CLI %%i %%j %%k
    where gh 2>nul

    echo.
    echo %CHECK% 检查 GitHub CLI 认证状态...
    gh auth status >nul 2>&1
    if %errorlevel% equ 0 (
        echo %SUCCESS% GitHub CLI 已认证
        gh auth status
    ) else (
        echo %WARNING% GitHub CLI 未认证
        echo   请运行: gh auth login
    )
) else (
    echo %NOT_FOUND% GitHub CLI 未安装
)

REM ========================================
REM 5. WSL 检查
REM ========================================
echo.
echo ========================================
echo         5. WSL 检查
echo ========================================

echo %CHECK% 检查 WSL...
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    echo %FOUND% WSL 已安装
    for /f "delims=" %%i in ('wsl --version') do echo   %%i

    echo.
    echo %CHECK% 已安装的 WSL 发行版:
    wsl --list --verbose

    echo.
    echo ========================================
    echo         WSL 环境检查
    echo ========================================

    REM 检查 WSL 中的编程语言
    echo.
    echo %CHECK% WSL 中的编程语言:
    echo.

    echo [Python]
    wsl -d Ubuntu -- python3 --version 2>nul
    if %errorlevel% equ 0 (
        echo %FOUND% Python3 已安装
        wsl -d Ubuntu -- which python3
    ) else (
        echo %NOT_FOUND% Python3 未安装
    )

    echo.
    echo [Node.js]
    wsl -d Ubuntu -- node --version 2>nul
    if %errorlevel% equ 0 (
        echo %FOUND% Node.js 已安装
        wsl -d Ubuntu -- node --version
        wsl -d Ubuntu -- npm --version
        wsl -d Ubuntu -- which node
    ) else (
        echo %NOT_FOUND% Node.js 未安装
    )

    echo.
    echo [Go]
    wsl -d Ubuntu -- go version 2>nul
    if %errorlevel% equ 0 (
        echo %FOUND% Go 已安装
        wsl -d Ubuntu -- go version
        wsl -d Ubuntu -- which go
    ) else (
        echo %NOT_FOUND% Go 未安装
    )

    echo.
    echo [Rust]
    wsl -d Ubuntu -- cargo --version 2>nul
    if %errorlevel% equ 0 (
        echo %FOUND% Rust 已安装
        wsl -d Ubuntu -- cargo --version
        wsl -d Ubuntu -- which cargo
    ) else (
        echo %NOT_FOUND% Rust 未安装
    )

    REM 检查 WSL 中的工具
    echo.
    echo ========================================
    echo         WSL 工具检查
    echo ========================================

    echo.
    echo [rsync]
    wsl -d Ubuntu -- which rsync >nul 2>&1
    if %errorlevel% equ 0 (
        echo %FOUND% rsync 已安装
        wsl -d Ubuntu -- rsync --version | head -n 1
    ) else (
        echo %NOT_FOUND% rsync 未安装
    )

    echo.
    echo [nginx]
    wsl -d Ubuntu -- which nginx >nul 2>&1
    if %errorlevel% equ 0 (
        echo %FOUND% nginx 已安装
        wsl -d Ubuntu -- nginx -v 2>&1
    ) else (
        echo %NOT_FOUND% nginx 未安装
    )

    echo.
    echo [宝塔面板]
    wsl -d Ubuntu -- which bt >nul 2>&1
    if %errorlevel% equ 0 (
        echo %FOUND% 宝塔面板 已安装
        wsl -d Ubuntu -- bt 14
    ) else (
        echo %NOT_FOUND% 宝塔面板 未安装
    )

    REM 检查宝塔相关目录
    wsl -d Ubuntu -- test -d /www/server/panel >nul 2>&1
    if %errorlevel% equ 0 (
        echo %INFO% 检测到宝塔安装目录: /www/server/panel
    )

) else (
    echo %NOT_FOUND% WSL 未安装
    echo   安装命令: wsl --install
)

REM ========================================
REM 6. 网络信息
REM ========================================
echo.
echo ========================================
echo         6. 网络信息
echo ========================================

echo %CHECK% 网络接口...
ipconfig | findstr /R "IPv4 子网掩码 默认网关"
for /f "delims=" %%i in ('ipconfig ^| findstr /R "无线局域网适配器 以太网适配器"') do echo   %%i

REM ========================================
REM 7. 环境变量摘要
REM ========================================
echo.
echo ========================================
echo         7. 环境变量摘要
echo ========================================

echo %CHECK% PATH 环境变量 (关键路径):
echo %PATH% | findstr /R "python node go git cargo" >nul 2>&1
if %errorlevel% equ 0 (
    echo %PATH% | findstr /R "python" >nul && echo   ✓ Python 在 PATH 中
    echo %PATH% | findstr /R "node" >nul && echo   ✓ Node.js 在 PATH 中
    echo %PATH% | findstr /R "go" >nul && echo   ✓ Go 在 PATH 中
    echo %PATH% | findstr /R "git" >nul && echo   ✓ Git 在 PATH 中
    echo %PATH% | findstr /R "cargo" >nul && echo   ✓ Rust 在 PATH 中
)

REM ========================================
REM 8. 总结
REM ========================================
echo.
echo ========================================
echo         8. 检查总结
echo ========================================

set "MISSING_COUNT=0"
set "INSTALLED_COUNT=0"

echo.
echo 编程语言安装情况:
where python >nul 2>&1 && set /a INSTALLED_COUNT+=1 || set /a MISSING_COUNT+=1
where node >nul 2>&1 && set /a INSTALLED_COUNT+=1 || set /a MISSING_COUNT+=1
where go >nul 2>&1 && set /a INSTALLED_COUNT+=1 || set /a MISSING_COUNT+=1
where cargo >nul 2>&1 && set /a INSTALLED_COUNT+=1 || set /a MISSING_COUNT+=1
echo   已安装: !INSTALLED_COUNT! / 4

echo.
echo 开发工具安装情况:
set /a TOOLS_INSTALLED=0
set /a TOOLS_MISSING=0
where git >nul 2>&1 && set /a TOOLS_INSTALLED+=1 || set /a TOOLS_MISSING+=1
where gh >nul 2>&1 && set /a TOOLS_INSTALLED+=1 || set /a TOOLS_MISSING+=1
where winget >nul 2>&1 && set /a TOOLS_INSTALLED+=1 || set /a TOOLS_MISSING+=1
echo   已安装: !TOOLS_INSTALLED! / 3

echo.
echo ========================================
echo %SUCCESS% 系统检查完成！
echo ========================================
echo.
echo 报告生成时间: %date% %time%
echo.

pause
