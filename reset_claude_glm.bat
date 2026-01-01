@echo off
chcp 65001 >nul
REM Claude Code + GLM 重置脚本 (Windows版本)
REM 先完全清理，然后重新安装配置
REM 所有参数必须通过命令行传递

setlocal enabledelayedexpansion

REM 解析命令行参数
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="-k" (
    set "API_KEY=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--key" (
    set "API_KEY=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-m" (
    set "MODEL_NAME=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--model" (
    set "MODEL_NAME=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-z" (
    set "ZAI_API_KEY=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--zai-key" (
    set "ZAI_API_KEY=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--skip-mcp" (
    set "SKIP_MCP=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="/?" goto :show_help

echo 未知选项: %~1
goto :show_help

:show_help
echo 用法: %~nx0 -k ^<API_KEY^> -m ^<MODEL^> [-z ^<ZAI_API_KEY^>] [--skip-mcp]
echo.
echo 必需参数:
echo   -k, --key ^<API_KEY^>        指定GLM API密钥 (必需)
echo   -m, --model ^<MODEL^>        指定模型名称 (必需)
echo.
echo 可选参数:
echo   -z, --zai-key ^<KEY^>        指定ZAI API密钥 (用于MCP识图功能)
echo   --skip-mcp                   跳过MCP服务器安装
echo   -h, --help, /?              显示此帮助信息
echo.
echo 示例:
echo   %~nx0 -k your_api_key -m glm-4.7
echo   %~nx0 -k your_api_key -m glm-4.7 -z your_zai_key
echo   %~nx0 -k your_api_key -m glm-4-plus --skip-mcp
echo.
echo 可用模型版本:
echo   glm-4.7       - GLM-4.7 (最新版本)
echo   glm-4-plus    - GLM-4 Plus
echo   glm-4-air     - GLM-4 Air (轻量版)
echo   glm-4-airx    - GLM-4 AirX
echo   glm-4-flash   - GLM-4 Flash (快速版)
echo   glm-4-long    - GLM-4 Long (长文本)
echo   glm-4v        - GLM-4V (视觉版)
echo   glm-4v-plus   - GLM-4V Plus
echo.
echo 注意:
echo   - API密钥和模型名称必须通过命令行参数指定
echo   - 如需使用MCP功能(识图、联网搜索)，请提供ZAI密钥
exit /b 0

:args_done

REM 验证必需参数
if not defined API_KEY (
    echo %ERROR% 错误: 未指定API密钥
    echo.
    echo 使用 -k 或 --key 参数指定GLM API密钥
    echo 使用 -h 查看帮助信息
    echo.
    pause
    exit /b 1
)

if not defined MODEL_NAME (
    echo %ERROR% 错误: 未指定模型名称
    echo.
    echo 使用 -m 或 --model 参数指定模型
    echo 使用 -h 查看帮助信息
    echo.
    pause
    exit /b 1
)

REM 颜色定义
set "INFO=[信息]"
set "SUCCESS=[成功]"
set "WARNING=[警告]"
set "ERROR=[错误]"
set "CLEAN=[清理]"
set "INSTALL=[安装]"

REM 显示开始信息
echo ========================================
echo   Claude Code + GLM 重置脚本
echo ========================================
echo 完整清理 → 重新安装 → 配置GLM模型
echo API密钥: %API_KEY:~0,10%...%API_KEY:~-10%
echo 模型: %MODEL_NAME%
if defined ZAI_API_KEY (
    echo ZAI密钥: %ZAI_API_KEY:~0,10%...%ZAI_API_KEY:~-10%
) else (
    echo ZAI密钥: 未提供 (MCP功能将跳过)
)
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
REM 第一阶段：完全清理
REM ========================================
echo.
echo ========================================
echo         第一阶段：完全清理
echo ========================================

echo %CLEAN% 开始完全清理Claude Code...

REM 步骤1: 卸载npm全局包
echo %CLEAN% 步骤1: 卸载npm全局包...
where npm >nul 2>&1
if %errorlevel% equ 0 (
    call npm uninstall -g @anthropic-ai/claude-code 2>nul
    echo %SUCCESS% npm包卸载完成
) else (
    echo %INFO% npm未安装，跳过npm包卸载
)

REM 步骤2: 删除配置文件
echo %CLEAN% 步骤2: 删除配置文件...

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

REM 步骤3: 删除配置文件备份
echo %CLEAN% 步骤3: 删除配置文件备份...
del /F /Q "%USERPROFILE%\.claude.json.backup*" 2>nul
echo %SUCCESS% 配置文件备份清理完成

REM 步骤4: 删除npm模块目录
echo %CLEAN% 步骤4: 删除npm模块目录...
if exist "%APPDATA%\npm\node_modules\@anthropic-ai" (
    rmdir /S /Q "%APPDATA%\npm\node_modules\@anthropic-ai" 2>nul
    echo %SUCCESS% 已删除npm模块
)

REM 步骤5: 删除临时文件和日志
echo %CLEAN% 步骤5: 删除临时文件...
del /F /Q "%TEMP%\*claude*" 2>nul
for /d %%i in ("%TEMP%\claude-*") do rmdir /S /Q "%%i" 2>nul
echo %SUCCESS% 临时文件清理完成

REM 步骤6: 清理环境变量
echo %CLEAN% 步骤6: 清理环境变量...
setx ANTHROPIC_AUTH_TOKEN "" >nul 2>&1
setx ANTHROPIC_API_KEY "" >nul 2>&1
setx ANTHROPIC_BASE_URL "" >nul 2>&1
setx ANTHROPIC_MODEL "" >nul 2>&1
setx GLM_API_KEY "" >nul 2>&1
setx GLM_BASE_URL "" >nul 2>&1
setx ZHIPU_API_KEY "" >nul 2>&1
setx BIGMODEL_API_KEY "" >nul 2>&1

set "ANTHROPIC_AUTH_TOKEN="
set "ANTHROPIC_API_KEY="
set "ANTHROPIC_BASE_URL="
set "ANTHROPIC_MODEL="
set "GLM_API_KEY="
set "GLM_BASE_URL="
set "ZHIPU_API_KEY="
set "BIGMODEL_API_KEY="

echo %SUCCESS% 环境变量清理完成

REM 步骤7: 查找并删除全局安装
echo %CLEAN% 步骤7: 查找并删除全局安装...
for /f "delims=" %%i in ('npm root -g 2^>nul') do set "NPM_GLOBAL=%%i"
if defined NPM_GLOBAL (
    if exist "%NPM_GLOBAL%\@anthropic-ai" (
        rmdir /S /Q "%NPM_GLOBAL%\@anthropic-ai" 2>nul
        echo %SUCCESS% 已删除全局npm模块
    )
)

echo %SUCCESS% 🧹 Claude Code完全清理完成！

REM ========================================
REM 第二阶段：重新安装
REM ========================================
echo.
echo ========================================
echo         第二阶段：重新安装
echo ========================================

echo %INSTALL% 开始重新安装Claude Code...

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
REM 第三阶段：配置 GLM
REM ========================================
echo.
echo ========================================
echo         第三阶段：配置 %MODEL_NAME%
echo ========================================

echo %INSTALL% 开始配置 %MODEL_NAME%...

REM 步骤1: 创建配置文件
echo %INSTALL% 步骤1: 创建GLM配置文件...
if not exist "%USERPROFILE%\.claude" mkdir "%USERPROFILE%\.claude"

(
echo {
echo   "env": {
echo     "ANTHROPIC_AUTH_TOKEN": "%API_KEY%",
echo     "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
echo     "ANTHROPIC_MODEL": "%MODEL_NAME%"
echo   },
echo   "permissions": {
echo     "allow": ["Read", "Write", "Execute"],
echo     "deny": []
echo   },
echo   "model": "%MODEL_NAME%",
echo   "max_tokens": 4096,
echo   "temperature": 0.7
echo }
) > "%USERPROFILE%\.claude\settings.json"

echo %SUCCESS% GLM配置文件创建完成 (模型: %MODEL_NAME%)

REM 步骤2: 设置环境变量
echo %INSTALL% 步骤2: 设置环境变量...

REM 设置用户级环境变量
setx ANTHROPIC_AUTH_TOKEN "%API_KEY%" >nul
setx ANTHROPIC_BASE_URL "https://open.bigmodel.cn/api/anthropic" >nul
setx ANTHROPIC_MODEL "%MODEL_NAME%" >nul

REM 设置当前会话的环境变量
set "ANTHROPIC_AUTH_TOKEN=%API_KEY%"
set "ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/anthropic"
set "ANTHROPIC_MODEL=%MODEL_NAME%"

echo %SUCCESS% 环境变量设置完成

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
REM 第五阶段：安装MCP服务器
REM ========================================
echo.
echo ========================================
echo         第五阶段：安装MCP服务器
echo ========================================

if "%SKIP_MCP%"=="1" (
    echo %INFO% 已跳过MCP服务器安装 (--skip-mcp)
    goto :skip_mcp
)

if not defined ZAI_API_KEY (
    echo %INFO% 未提供ZAI密钥，跳过MCP服务器安装
    echo %INFO% 如需使用MCP功能(识图、联网搜索)，请使用 -z 参数提供ZAI密钥
    goto :skip_mcp
)

echo %INSTALL% 开始安装智谱MCP服务器...

REM 1. 安装zai-mcp-server (识图MCP)
echo %INSTALL% 安装zai-mcp-server (识图功能)...
where claude >nul 2>&1
if %errorlevel% equ 0 (
    call claude mcp add -s user zai-mcp-server --env Z_AI_API_KEY=%ZAI_API_KEY% -- npx -y "@z_ai/mcp-server" 2>nul || echo %WARNING% zai-mcp-server安装可能失败，请手动检查
    echo %SUCCESS% zai-mcp-server安装命令已执行
) else (
    echo %WARNING% Claude Code不可用，跳过MCP安装
)

REM 2. 安装web-search-prime (联网搜索MCP)
echo %INSTALL% 安装web-search-prime (联网搜索)...
where claude >nul 2>&1
if %errorlevel% equ 0 (
    call claude mcp add -s user -t http web-search-prime https://open.bigmodel.cn/api/mcp/web_search_prime/mcp --header "Authorization: Bearer %ZAI_API_KEY%" 2>nul || echo %WARNING% web-search-prime安装可能失败，请手动检查
    echo %SUCCESS% web-search-prime安装命令已执行
) else (
    echo %WARNING% Claude Code不可用，跳过MCP安装
)

echo %SUCCESS% 🔌 MCP服务器安装完成！

:skip_mcp

REM ========================================
REM 使用说明
REM ========================================
echo.
echo ========================================
echo           重置完成！使用说明
echo ========================================
echo.
echo 🚀 启动Claude Code:
echo    claude
echo.
echo 🔧 强制指定模型启动:
echo    claude --model %MODEL_NAME%
echo.
echo 🔧 检查当前使用的模型:
echo    在Claude Code中输入: /model
echo.
echo ⚙️  查看配置:
echo    type "%USERPROFILE%\.claude\settings.json"
echo.
echo 🔄 重新加载环境变量:
echo    重新打开命令提示符窗口
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
echo    - 已配置模型: %MODEL_NAME%
echo    - API提供商: 智谱AI (bigmodel.cn)
echo    - 配置文件: %USERPROFILE%\.claude\settings.json
echo.
if defined ZAI_API_KEY (
    echo 🔌 已安装MCP服务器:
    echo    - zai-mcp-server: 识图功能
    echo    - web-search-prime: 联网搜索
    echo.
    echo 💡 MCP使用方法:
    echo    - 在Claude Code中直接上传图片进行识图
    echo    - 使用联网搜索获取最新信息
) else (
    echo 🔌 MCP服务器: 未安装 (使用 -z 参数提供ZAI密钥以安装)
)
echo.
echo ========================================
echo.
echo %SUCCESS% 🎉 Claude Code + %MODEL_NAME% 重置完成！
echo %SUCCESS% 现在可以使用 %MODEL_NAME% 模型了！
echo.
echo %INFO% 立即可用的启动方式：
echo %INFO% npx @anthropic-ai/claude-code
echo.

pause
