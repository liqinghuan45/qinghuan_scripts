#!/bin/bash

# Claude Code + GLM 重置脚本
# 先完全清理，然后重新安装配置
# 支持传入自定义API密钥和模型名称

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 默认API密钥和模型
DEFAULT_API_KEY="783e0488aa65474bb5336ab0dc00c23a.BI733taKT0HBNcd0"
DEFAULT_MODEL="glm-4.7"

# 解析命令行参数
API_KEY="${DEFAULT_API_KEY}"
MODEL_NAME="${DEFAULT_MODEL}"

show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -k, --key <API_KEY>      指定API密钥 (默认: ${DEFAULT_API_KEY:0:10}...)"
    echo "  -m, --model <MODEL>      指定模型名称 (默认: ${DEFAULT_MODEL})"
    echo "  -h, --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                                    # 使用默认配置"
    echo "  $0 -k your_api_key                    # 使用自定义API密钥"
    echo "  $0 -m glm-4-plus                      # 使用自定义模型"
    echo "  $0 -k your_api_key -m glm-4-plus      # 同时指定密钥和模型"
    echo ""
    echo "可用模型版本:"
    echo "  glm-4.7       - GLM-4.7 (默认，最新版本)"
    echo "  glm-4-plus    - GLM-4 Plus"
    echo "  glm-4-air     - GLM-4 Air (轻量版)"
    echo "  glm-4-airx    - GLM-4 AirX"
    echo "  glm-4-flash   - GLM-4 Flash (快速版)"
    echo "  glm-4-long    - GLM-4 Long (长文本)"
    echo "  glm-4v        - GLM-4V (视觉版)"
    echo "  glm-4v-plus   - GLM-4V Plus"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--key)
            API_KEY="$2"
            shift 2
            ;;
        -m|--model)
            MODEL_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "未知选项: $1"
            show_help
            ;;
    esac
done

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_clean() {
    echo -e "${MAGENTA}[CLEAN]${NC} $1"
}

print_install() {
    echo -e "${GREEN}[INSTALL]${NC} $1"
}

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 显示开始信息
show_header() {
    echo "========================================"
    echo "  Claude Code + GLM 重置脚本          "
    echo "========================================"
    echo "完整清理 → 重新安装 → 配置GLM模型"
    echo "API密钥: ${API_KEY:0:10}...${API_KEY: -10}"
    echo "模型: ${MODEL_NAME}"
    echo ""
}

# 清理阶段
clean_claude_code() {
    echo ""
    echo "========================================"
    echo "         第一阶段：完全清理              "
    echo "========================================"

    print_clean "开始完全清理Claude Code..."

    # 1. 卸载npm全局包
    print_clean "步骤1: 卸载npm全局包..."
    if command -v npm >/dev/null 2>&1; then
        npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
        print_success "npm包卸载完成"
    else
        print_info "npm未安装，跳过npm包卸载"
    fi

    # 2. 删除可执行文件
    print_clean "步骤2: 删除可执行文件..."
    local executables=(
        "/usr/local/bin/claude"
        "/usr/bin/claude"
        "/opt/claude/bin/claude"
        "/snap/bin/claude"
        "/usr/local/sbin/claude"
        "/usr/sbin/claude"
    )

    for exe in "${executables[@]}"; do
        if [[ -f "$exe" ]]; then
            rm -f "$exe"
            print_success "已删除: $exe"
        fi
    done

    # 3. 删除配置文件
    print_clean "步骤3: 删除配置文件..."
    local config_dirs=(
        "$HOME/.claude"
        "$HOME/.claude.json"
        "$HOME/.config/claude-code"
        "$HOME/.cache/claude-code"
        "$HOME/.local/share/claude-code"
        "/root/.claude"
        "/root/.claude.json"
        "/root/.config/claude-code"
        "/root/.cache/claude-code"
        "/root/.local/share/claude-code"
    )

    for config in "${config_dirs[@]}"; do
        if [[ -e "$config" ]]; then
            rm -rf "$config"
            print_success "已删除: $config"
        fi
    done

    # 4. 删除配置文件备份
    print_clean "步骤4: 删除配置文件备份..."
    local backup_files=(
        "$HOME/.claude.json.backup"
        "$HOME/.claude.json.backup.*"
        "/root/.claude.json.backup"
        "/root/.claude.json.backup.*"
        "$HOME/.bashrc.backup.*"
        "$HOME/.zshrc.backup.*"
        "$HOME/.profile.backup.*"
        "$HOME/.bash_profile.backup.*"
        "/root/.bashrc.backup.*"
        "/root/.zshrc.backup.*"
        "/root/.profile.backup.*"
        "/root/.bash_profile.backup.*"
        "/etc/environment.backup.*"
        "/etc/profile.backup.*"
    )

    for backup in "${backup_files[@]}"; do
        find $(dirname "$backup") -name "$(basename "$backup")" -type f -delete 2>/dev/null || true
    done
    print_success "配置文件备份清理完成"

    # 5. 删除npm模块目录
    print_clean "步骤5: 删除npm模块目录..."
    local npm_dirs=(
        "/usr/local/lib/node_modules/@anthropic-ai"
        "/usr/lib/node_modules/@anthropic-ai"
        "/opt/node_modules/@anthropic-ai"
    )

    for dir in "${npm_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_success "已删除npm模块: $dir"
        fi
    done

    # 6. 删除临时文件和日志
    print_clean "步骤6: 删除临时文件和日志..."
    find /tmp -name "*claude*" -type f -delete 2>/dev/null || true
    find /var/log -name "*claude*" -type f -delete 2>/dev/null || true
    rm -rf /tmp/claude-* 2>/dev/null || true
    print_success "临时文件清理完成"

    # 7. 清理环境变量
    print_clean "步骤7: 清理环境变量..."
    local shell_configs=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
        "$HOME/.bash_profile"
        "/root/.bashrc"
        "/root/.zshrc"
        "/root/.profile"
        "/root/.bash_profile"
        "/etc/environment"
        "/etc/profile"
    )

    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            # 备份原文件
            cp "$config" "$config.backup.$$" 2>/dev/null || true

            # 删除相关行
            sed -i '/ANTHROPIC/d' "$config" 2>/dev/null || true
            sed -i '/GLM/d' "$config" 2>/dev/null || true
            sed -i '/claude/d' "$config" 2>/dev/null || true
            sed -i '/bigmodel/d' "$config" 2>/dev/null || true
            sed -i '/zhipu/d' "$config" 2>/dev/null || true

            print_success "已清理环境变量: $config"
        fi
    done

    # 8. 查找并删除任何剩余的claude文件
    print_clean "步骤8: 查找并删除剩余文件..."
    local search_paths=(
        "/usr"
        "/opt"
        "/home"
        "/etc"
        "/var"
    )

    # 保护三个脚本不被删除
    local current_script="$(realpath "$0")"
    local setup_script="/root/setup_claude_glm.sh"
    local clean_script="/root/clean_claude.sh"

    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]]; then
            find "$path" -name "*claude*" -type f ! -path "$current_script" ! -path "$setup_script" ! -path "$clean_script" -delete 2>/dev/null || true
            find "$path" -name "*claude*" -type d -empty -delete 2>/dev/null || true
        fi
    done

    # 额外清理：查找并删除所有备份文件
    print_clean "清理剩余备份文件..."
    find /root /home -name "*.backup*" -type f -delete 2>/dev/null || true

    # 9. 清理命令缓存
    print_clean "步骤9: 清理命令缓存..."
    hash -r 2>/dev/null || true

    # 10. 取消当前会话的环境变量
    print_clean "步骤10: 清理当前会话环境变量..."
    unset ANTHROPIC_AUTH_TOKEN 2>/dev/null || true
    unset ANTHROPIC_API_KEY 2>/dev/null || true
    unset ANTHROPIC_BASE_URL 2>/dev/null || true
    unset GLM_API_KEY 2>/dev/null || true
    unset GLM_BASE_URL 2>/dev/null || true
    unset ZHIPU_API_KEY 2>/dev/null || true
    unset BIGMODEL_API_KEY 2>/dev/null || true

    print_success "🧹 Claude Code完全清理完成！"
}

# 安装阶段
install_claude_code() {
    echo ""
    echo "========================================"
    echo "         第二阶段：重新安装              "
    echo "========================================"

    print_install "开始重新安装Claude Code..."

    # 1. 检查Node.js和npm
    print_install "步骤1: 检查Node.js和npm安装状态..."
    if ! command -v node >/dev/null 2>&1; then
        print_info "Node.js未安装，正在安装..."
        apt update
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt-get install -y nodejs
        print_success "Node.js安装完成"
    else
        print_success "Node.js已安装: $(node --version)"
    fi

    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm未安装，请手动安装"
        exit 1
    else
        print_success "npm已安装: $(npm --version)"
    fi

    # 2. 安装Claude Code
    print_install "步骤2: 安装Claude Code..."
    npm install -g @anthropic-ai/claude-code
    print_success "Claude Code安装完成"
}

# 配置阶段
configure_glm() {
    echo ""
    echo "========================================"
    echo "         第三阶段：配置GLM模型           "
    echo "========================================"

    print_install "开始配置 ${MODEL_NAME}..."

    # 1. 创建配置文件
    print_install "步骤1: 创建GLM配置文件..."
    mkdir -p ~/.claude

    cat > ~/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${API_KEY}",
    "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
    "ANTHROPIC_MODEL": "${MODEL_NAME}"
  },
  "permissions": {
    "allow": ["Read", "Write", "Execute"],
    "deny": []
  },
  "model": "${MODEL_NAME}",
  "max_tokens": 4096,
  "temperature": 0.7
}
EOF

    # 设置正确的文件权限
    chmod 600 ~/.claude/settings.json
    print_success "GLM配置文件创建完成 (模型: ${MODEL_NAME})"

    # 2. 设置环境变量
    print_install "步骤2: 设置环境变量..."

    # 添加到当前会话
    export ANTHROPIC_AUTH_TOKEN="${API_KEY}"
    export ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic"
    export ANTHROPIC_MODEL="${MODEL_NAME}"

    # 确保npm全局bin路径在PATH中
    local npm_bin_path="$(npm root -g)/../bin"
    if [[ -d "$npm_bin_path" ]]; then
        export PATH="$npm_bin_path:$PATH"
        print_info "已添加npm bin路径到PATH: $npm_bin_path"
    fi

    # 添加到shell配置文件
    local shell_configs=(
        "/root/.bashrc"
        "/root/.zshrc"
        "/root/.profile"
    )

    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            # 备份原文件
            cp "$config" "$config.backup.$$" 2>/dev/null || true

            # 删除旧的配置
            sed -i '/ANTHROPIC_API_KEY/d' "$config" 2>/dev/null || true
            sed -i '/ANTHROPIC_AUTH_TOKEN/d' "$config" 2>/dev/null || true
            sed -i '/ANTHROPIC_BASE_URL/d' "$config" 2>/dev/null || true
            sed -i '/ANTHROPIC_MODEL/d' "$config" 2>/dev/null || true
            sed -i '/npm.*bin.*PATH/d' "$config" 2>/dev/null || true

            # 添加新配置
            echo "export ANTHROPIC_AUTH_TOKEN=\"${API_KEY}\"" >> "$config"
            echo "export ANTHROPIC_BASE_URL=\"https://open.bigmodel.cn/api/anthropic\"" >> "$config"
            echo "export ANTHROPIC_MODEL=\"${MODEL_NAME}\"" >> "$config"

            # 添加npm bin路径到PATH
            echo "export PATH=\"$npm_bin_path:\$PATH\"" >> "$config"
            print_info "已添加PATH配置到: $config"

            print_success "已配置环境变量: $config"
        fi
    done

    print_success "环境变量设置完成"
}

# 验证阶段
verify_installation() {
    echo ""
    echo "========================================"
    echo "         第四阶段：验证安装              "
    echo "========================================"

    print_install "开始验证安装..."

    # 确保PATH包含npm bin路径
    local npm_bin_path="$(npm root -g)/../bin"
    if [[ -d "$npm_bin_path" ]]; then
        export PATH="$npm_bin_path:$PATH"
        print_info "已更新PATH以包含npm bin路径: $npm_bin_path"
    fi

    # 清理命令缓存
    hash -r 2>/dev/null || true

    # 检查claude命令
    print_install "步骤1: 检查Claude Code命令..."
    if command -v claude >/dev/null 2>&1; then
        print_success "✓ Claude Code命令可用: $(which claude)"
        print_info "Claude Code版本信息:"
        claude --version 2>/dev/null || print_warning "无法获取版本信息"
    else
        print_error "✗ Claude Code命令不可用"
        print_info "可能的解决方案："
        print_info "1. 重新加载shell配置: source ~/.bashrc"
        print_info "2. 手动添加PATH: export PATH=\"$npm_bin_path:\$PATH\""
        print_info "3. 使用npx运行: npx @anthropic-ai/claude-code"
        print_info "4. 重启终端或重新登录"
        return 1
    fi

    # 检查配置文件
    print_install "步骤2: 检查配置文件..."
    local config_file="$HOME/.claude/settings.json"
    if [[ -f "$config_file" ]]; then
        print_success "✓ 配置文件存在: $config_file"
        print_info "配置内容预览："
        cat "$config_file" | sed "s/${API_KEY}/${API_KEY:0:10}...${API_KEY: -10}/g"
    else
        print_error "✗ 配置文件不存在: $config_file"
        return 1
    fi

    # 检查环境变量
    print_install "步骤3: 检查环境变量..."
    if [[ -n "$ANTHROPIC_AUTH_TOKEN" ]]; then
        print_success "✓ ANTHROPIC_AUTH_TOKEN 已设置"
    else
        print_warning "⚠ ANTHROPIC_AUTH_TOKEN 未设置"
    fi

    if [[ -n "$ANTHROPIC_BASE_URL" ]]; then
        print_success "✓ ANTHROPIC_BASE_URL 已设置: $ANTHROPIC_BASE_URL"
    else
        print_warning "⚠ ANTHROPIC_BASE_URL 未设置"
    fi

    if [[ -n "$ANTHROPIC_MODEL" ]]; then
        print_success "✓ ANTHROPIC_MODEL 已设置: $ANTHROPIC_MODEL"
    else
        print_warning "⚠ ANTHROPIC_MODEL 未设置"
    fi

    print_success "🎯 安装验证完成！"
}

# 安装MCP服务器
install_mcp_servers() {
    print_install "步骤4: 安装智谱MCP服务器..."

    # 1. 安装zai-mcp-server (识图MCP)
    print_install "安装zai-mcp-server (识图功能)..."
    if command -v claude >/dev/null 2>&1; then
        claude mcp add -s user zai-mcp-server --env Z_AI_API_KEY=4fcc9acbf7a64159b430332ac62d03a1.Z2ngxJocffMxNEwi -- npx -y "@z_ai/mcp-server" 2>/dev/null || print_warning "zai-mcp-server安装可能失败，请手动检查"
        print_success "zai-mcp-server安装命令已执行"
    else
        print_warning "Claude Code不可用，跳过MCP安装"
    fi

    # 2. 安装web-search-prime (联网搜索MCP)
    print_install "安装web-search-prime (联网搜索)..."
    if command -v claude >/dev/null 2>&1; then
        claude mcp add -s user -t http web-search-prime https://open.bigmodel.cn/api/mcp/web_search_prime/mcp --header "Authorization: Bearer 4fcc9acbf7a64159b430332ac62d03a1.Z2ngxJocffMxNEwi" 2>/dev/null || print_warning "web-search-prime安装可能失败，请手动检查"
        print_success "web-search-prime安装命令已执行"
    else
        print_warning "Claude Code不可用，跳过MCP安装"
    fi

    print_success "🔌 MCP服务器安装完成！"
}

# 显示使用说明
show_usage() {
    echo ""
    echo "========================================"
    echo "           重置完成！使用说明            "
    echo "========================================"
    echo ""
    echo "🚀 启动Claude Code:"
    echo "   claude"
    echo ""
    echo "🔧 强制指定模型启动:"
    echo "   claude --model ${MODEL_NAME}"
    echo ""
    echo "🔧 检查当前使用的模型:"
    echo "   在Claude Code中输入: /model"
    echo ""
    echo "⚙️  查看配置:"
    echo "   cat ~/.claude/settings.json"
    echo ""
    echo "🔄 重新加载环境变量:"
    echo "   source ~/.bashrc"
    echo ""
    echo "📝 测试连接:"
    echo "   claude --help"
    echo ""
    echo "🔍 如果claude命令找不到:"
    echo "   1. 重新加载shell: source ~/.bashrc"
    echo "   2. 手动设置PATH: export PATH=\"\$(npm root -g)/../bin:\$PATH\""
    echo "   3. 使用npx运行: npx @anthropic-ai/claude-code"
    echo "   4. 重启终端会话"
    echo ""
    echo "💡 备选方案 (如果PATH问题持续):"
    echo "   - 直接使用npx: npx @anthropic-ai/claude-code"
    echo "   - 或使用完整路径: \$(npm root -g)/../bin/claude"
    echo ""
    echo "📋 配置信息:"
    echo "   - 已配置模型: ${MODEL_NAME}"
    echo "   - API提供商: 智谱AI (bigmodel.cn)"
    echo "   - 配置文件: ~/.claude/settings.json"
    echo "   - npm bin路径: $(npm root -g)/../bin"
    echo ""
    echo "🔌 已安装MCP服务器:"
    echo "   - zai-mcp-server: 识图功能"
    echo "   - web-search-prime: 联网搜索"
    echo ""
    echo "💡 MCP使用方法:"
    echo "   - 在Claude Code中直接上传图片进行识图"
    echo "   - 使用联网搜索获取最新信息"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    show_header
    check_root

    # 执行四个阶段
    clean_claude_code
    install_claude_code
    configure_glm
    verify_installation

    # 安装MCP服务器
    install_mcp_servers

    show_usage

    # 提供立即可用的启动方式
    print_info "立即可用的启动方式："
    print_info "npx @anthropic-ai/claude-code"
    echo ""

    print_success "🎉 Claude Code + ${MODEL_NAME} 重置完成！"
    print_success "现在可以使用 ${MODEL_NAME} 模型了！"
}

# 执行主函数
main "$@"