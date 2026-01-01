@echo off
chcp 65001 >nul
REM Claude Code + GLM-4.6 安装配置脚本 (Windows版本)

setlocal enabledelayedexpansion

REM 你的API密钥（硬编码）
set "API_KEY=4fcc9acbf7a64159b430332ac62d03a1.Z2ngxJocffMxNEwi"

REM 颜色定义
set "INFO=[信息]"
set "SUCCESS=[成功]"
set "WARNING=[警告]"
set "ERROR=[错误]"
set "INSTALL=[安装]"

REM 显示开始信息
echo ========================================
echo   Claude Code + GLM-4.6 安装脚本
echo ========================================
echo 安装 Claude Code → 配置 GLM-4.6
echo API密钥: %API_KEY:~0,10%...%API_KEY:~-10%
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
REM 第一阶段：安装 Claude Code
REM ========================================
echo.
echo ========================================
echo         第一阶段：安装 Claude Code
echo ========================================

REM 步骤1: 检查Node.js和npm
echo %INSTALL% 步骤1: 检查Node.js和npm安装状态...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% Node.js未安装
    echo 请先安装Node.js: https://nodejs.org/
    pause
    exit /b 1
) else (
    for /f "delims=" %%i in ('node --version') do echo %SUCCESS% Node.js已安装: %%i
)

where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% npm未安装，请手动安装
    pause
    exit /b 1
) else (
    for /f "delims=" %%i in ('npm --version') do echo %SUCCESS% npm已安装: %%i
)

REM 步骤2: 安装Claude Code
echo %INSTALL% 步骤2: 安装Claude Code...
call npm install -g @anthropic-ai/claude-code
if %errorlevel% neq 0 (
    echo %ERROR% Claude Code安装失败
    pause
    exit /b 1
)
echo %SUCCESS% Claude Code安装完成

REM ========================================
REM 第二阶段：配置 GLM-4.6
REM ========================================
echo.
echo ========================================
echo         第二阶段：配置 GLM-4.6
echo ========================================

REM 步骤1: 创建配置目录
echo %INSTALL% 步骤1: 创建GLM-4.6配置文件...
if not exist "%USERPROFILE%\.claude" mkdir "%USERPROFILE%\.claude"

REM 步骤2: 创建配置文件
(
echo {
echo   "env": {
echo     "ANTHROPIC_AUTH_TOKEN": "%API_KEY%",
echo     "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
echo     "ANTHROPIC_MODEL": "glm-4.6"
echo   },
echo   "permissions": {
echo     "allow": ["Read", "Write", "Execute"],
echo     "deny": []
echo   },
echo   "model": "glm-4.6",
echo   "max_tokens": 4096,
echo   "temperature": 0.7
echo }
) > "%USERPROFILE%\.claude\settings.json"

echo %SUCCESS% GLM-4.6配置文件创建完成

REM 步骤3: 设置环境变量
echo %INSTALL% 步骤2: 设置环境变量...

REM 设置用户级环境变量
setx ANTHROPIC_AUTH_TOKEN "%API_KEY%" >nul
setx ANTHROPIC_BASE_URL "https://open.bigmodel.cn/api/anthropic" >nul
setx ANTHROPIC_MODEL "glm-4.6" >nul

REM 设置当前会话的环境变量
set "ANTHROPIC_AUTH_TOKEN=%API_KEY%"
set "ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/anthropic"
set "ANTHROPIC_MODEL=glm-4.6"

echo %SUCCESS% 环境变量设置完成

REM ========================================
REM 第三阶段：安装MCP服务器
REM ========================================
echo.
echo ========================================
echo         第三阶段：安装MCP服务器
echo ========================================

echo %INSTALL% 开始安装智谱MCP服务器...

REM 1. 安装zai-mcp-server (识图MCP)
echo %INSTALL% 安装zai-mcp-server (识图功能)...
where claude >nul 2>&1
if %errorlevel% equ 0 (
    call claude mcp add -s user zai-mcp-server --env Z_AI_API_KEY=4fcc9acbf7a64159b430332ac62d03a1.Z2ngxJocffMxNEwi -- npx -y "@z_ai/mcp-server" 2>nul || echo %WARNING% zai-mcp-server安装可能失败，请手动检查
    echo %SUCCESS% zai-mcp-server安装命令已执行
) else (
    echo %WARNING% Claude Code不可用，跳过MCP安装
)

REM 2. 安装web-search-prime (联网搜索MCP)
echo %INSTALL% 安装web-search-prime (联网搜索)...
where claude >nul 2>&1
if %errorlevel% equ 0 (
    call claude mcp add -s user -t http web-search-prime https://open.bigmodel.cn/api/mcp/web_search_prime/mcp --header "Authorization: Bearer 4fcc9acbf7a64159b430332ac62d03a1.Z2ngxJocffMxNEwi" 2>nul || echo %WARNING% web-search-prime安装可能失败，请手动检查
    echo %SUCCESS% web-search-prime安装命令已执行
) else (
    echo %WARNING% Claude Code不可用，跳过MCP安装
)

echo %SUCCESS% 🔌 MCP服务器安装完成！

REM ========================================
REM 第四阶段：验证安装
REM ========================================
echo.
echo ========================================
echo         第四阶段：验证安装
echo ========================================

echo %INSTALL% 开始验证安装...

REM 检查claude命令
echo %INSTALL% 步骤1: 检查Claude Code命令...
where claude >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('where claude') do echo %SUCCESS% ✓ Claude Code命令可用: %%i
    echo %INFO% Claude Code版本信息:
    call claude --version 2>nul
) else (
    echo %WARNING% ✗ Claude Code命令不可用
    echo %INFO% 可能的解决方案：
    echo %INFO% 1. 重新打开命令提示符窗口
    echo %INFO% 2. 使用npx运行: npx @anthropic-ai/claude-code
    echo %INFO% 3. 检查npm全局bin路径是否在PATH中
)

REM 检查配置文件
echo %INSTALL% 步骤2: 检查配置文件...
if exist "%USERPROFILE%\.claude\settings.json" (
    echo %SUCCESS% ✓ 配置文件存在: %USERPROFILE%\.claude\settings.json
    echo %INFO% 配置内容预览：
    type "%USERPROFILE%\.claude\settings.json"
) else (
    echo %ERROR% ✗ 配置文件不存在
)

REM 检查环境变量
echo %INSTALL% 步骤3: 检查环境变量...
if defined ANTHROPIC_AUTH_TOKEN (
    echo %SUCCESS% ✓ ANTHROPIC_AUTH_TOKEN 已设置
) else (
    echo %WARNING% ⚠ ANTHROPIC_AUTH_TOKEN 未设置
)

if defined ANTHROPIC_BASE_URL (
    echo %SUCCESS% ✓ ANTHROPIC_BASE_URL 已设置: %ANTHROPIC_BASE_URL%
) else (
    echo %WARNING% ⚠ ANTHROPIC_BASE_URL 未设置
)

if defined ANTHROPIC_MODEL (
    echo %SUCCESS% ✓ ANTHROPIC_MODEL 已设置: %ANTHROPIC_MODEL%
) else (
    echo %WARNING% ⚠ ANTHROPIC_MODEL 未设置
)

echo %SUCCESS% 🎯 安装验证完成！

REM ========================================
REM 使用说明
REM ========================================
echo.
echo ========================================
echo           安装完成！使用说明
echo ========================================
echo.
echo 🚀 启动Claude Code:
echo    claude
echo.
echo 🔧 强制指定GLM-4.6模型启动:
echo    claude --model glm-4.6
echo.
echo 🔧 检查当前使用的模型:
echo    在Claude Code中输入: /model
echo.
echo ⚙️  查看配置:
echo    type "%USERPROFILE%\.claude\settings.json"
echo.
echo 📝 测试连接:
echo    claude --help
echo.
echo 🔍 如果claude命令找不到:
echo    1. 重新打开命令提示符窗口
echo    2. 使用npx运行: npx @anthropic-ai/claude-code
echo    3. 检查PATH环境变量
echo.
echo 💡 备选方案:
echo    - 直接使用npx: npx @anthropic-ai/claude-code
echo.
echo 📋 配置信息:
echo    - 已配置模型: GLM-4.6
echo    - API提供商: 智谱AI (bigmodel.cn)
echo    - 配置文件: %USERPROFILE%\.claude\settings.json
echo.
echo 🔌 已安装MCP服务器:
echo    - zai-mcp-server: 识图功能
echo    - web-search-prime: 联网搜索
echo.
echo 💡 MCP使用方法:
echo    - 在Claude Code中直接上传图片进行识图
echo    - 使用联网搜索获取最新信息
echo.
echo ========================================
echo.
echo %SUCCESS% 🎉 Claude Code + GLM-4.6 安装完成！
echo %SUCCESS% 现在可以使用GLM-4.6模型了！
echo.

pause

