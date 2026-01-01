@echo off
chcp 65001 >nul
REM Claude Code 完全清理脚本 (Windows版本)
REM 此脚本将彻底删除系统中的所有Claude Code相关文件

setlocal enabledelayedexpansion

REM 颜色定义 (使用echo命令)
set "INFO=[信息]"
set "SUCCESS=[成功]"
set "WARNING=[警告]"
set "ERROR=[错误]"

REM 检查管理员权限
echo ========================================
echo     Claude Code 完全清理脚本 v2.0
echo ========================================
echo 此脚本将彻底删除系统中的所有Claude Code相关文件
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% 此脚本需要管理员权限运行
    echo 请右键点击此脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

echo %INFO% 自动开始清理，无需确认
echo.

REM ========================================
REM 步骤1: 删除npm全局包
REM ========================================
echo %INFO% 步骤1: 删除npm全局包...
where npm >nul 2>&1
if %errorlevel% equ 0 (
    call npm uninstall -g @anthropic-ai/claude-code 2>nul
    echo %SUCCESS% npm包卸载完成
) else (
    echo %INFO% 未找到npm，跳过npm包卸载
)

REM ========================================
REM 步骤2: 删除配置文件和缓存
REM ========================================
echo %INFO% 步骤2: 删除配置文件和缓存...

if exist "%USERPROFILE%\.claude" (
    rmdir /S /Q "%USERPROFILE%\.claude" 2>nul
    echo %SUCCESS% 已删除: %USERPROFILE%\.claude
)

if exist "%USERPROFILE%\.claude.json" (
    del /F /Q "%USERPROFILE%\.claude.json" 2>nul
    echo %SUCCESS% 已删除: %USERPROFILE%\.claude.json
)

if exist "%APPDATA%\claude-code" (
    rmdir /S /Q "%APPDATA%\claude-code" 2>nul
    echo %SUCCESS% 已删除: %APPDATA%\claude-code
)

if exist "%LOCALAPPDATA%\claude-code" (
    rmdir /S /Q "%LOCALAPPDATA%\claude-code" 2>nul
    echo %SUCCESS% 已删除: %LOCALAPPDATA%\claude-code
)

if exist "%APPDATA%\npm\node_modules\@anthropic-ai" (
    rmdir /S /Q "%APPDATA%\npm\node_modules\@anthropic-ai" 2>nul
    echo %SUCCESS% 已删除npm模块: %APPDATA%\npm\node_modules\@anthropic-ai
)

REM ========================================
REM 步骤3: 删除备份文件
REM ========================================
echo %INFO% 步骤3: 删除备份文件...
del /F /Q "%USERPROFILE%\.claude.json.backup*" 2>nul
echo %SUCCESS% 配置文件备份清理完成

REM ========================================
REM 步骤4: 删除临时文件
REM ========================================
echo %INFO% 步骤4: 删除临时文件...
del /F /Q "%TEMP%\*claude*" 2>nul
for /d %%i in ("%TEMP%\claude-*") do rmdir /S /Q "%%i" 2>nul
echo %SUCCESS% 临时文件清理完成

REM ========================================
REM 步骤5: 清理环境变量
REM ========================================
echo %INFO% 步骤5: 清理环境变量...

REM 删除用户环境变量
setx ANTHROPIC_AUTH_TOKEN "" >nul 2>&1
setx ANTHROPIC_API_KEY "" >nul 2>&1
setx ANTHROPIC_BASE_URL "" >nul 2>&1
setx ANTHROPIC_MODEL "" >nul 2>&1
setx GLM_API_KEY "" >nul 2>&1
setx GLM_BASE_URL "" >nul 2>&1
setx ZHIPU_API_KEY "" >nul 2>&1
setx BIGMODEL_API_KEY "" >nul 2>&1

REM 从当前会话清除
set "ANTHROPIC_AUTH_TOKEN="
set "ANTHROPIC_API_KEY="
set "ANTHROPIC_BASE_URL="
set "ANTHROPIC_MODEL="
set "GLM_API_KEY="
set "GLM_BASE_URL="
set "ZHIPU_API_KEY="
set "BIGMODEL_API_KEY="

echo %SUCCESS% 环境变量清理完成

REM ========================================
REM 步骤6: 删除可能的全局安装路径
REM ========================================
echo %INFO% 步骤6: 查找并删除全局安装...

REM 查找npm全局安装路径
for /f "delims=" %%i in ('npm root -g 2^>nul') do set "NPM_GLOBAL=%%i"
if defined NPM_GLOBAL (
    if exist "%NPM_GLOBAL%\@anthropic-ai" (
        rmdir /S /Q "%NPM_GLOBAL%\@anthropic-ai" 2>nul
        echo %SUCCESS% 已删除全局npm模块
    )
)

echo %SUCCESS% 清理完成！

REM ========================================
REM 验证清理结果
REM ========================================
echo.
echo ========================================
echo          验证清理结果
echo ========================================

set "CLEANUP_COMPLETE=1"

REM 检查claude命令
echo %INFO% 检查claude命令位置：
where claude >nul 2>&1
if %errorlevel% equ 0 (
    echo %WARNING% 仍然找到claude命令
    set "CLEANUP_COMPLETE=0"
) else (
    echo %SUCCESS% ✓ claude命令已删除
)

REM 检查配置文件
echo %INFO% 检查配置文件：
if exist "%USERPROFILE%\.claude" (
    echo %WARNING% 配置目录仍然存在
    set "CLEANUP_COMPLETE=0"
) else (
    echo %SUCCESS% ✓ 没有找到配置文件
)

REM 最终结果
echo.
echo ========================================
if "%CLEANUP_COMPLETE%"=="1" (
    echo %SUCCESS% 🎉 Claude Code已完全清理！
) else (
    echo %WARNING% ⚠️  清理完成，但仍有部分残留
    echo %INFO% 请手动检查上述警告项目
)
echo ========================================
echo.

pause

