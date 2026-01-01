#!/bin/bash

# Claude Code + GLM 一键配置脚本
# 所有参数必须通过命令行传递

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认值
API_KEY=""
MODEL_NAME=""
ZAI_API_KEY=""
SKIP_MCP=0

# 解析命令行参数
parse_args() {
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
            -z|--zai-key)
                ZAI_API_KEY="$2"
                shift 2
                ;;
            --skip-mcp)
                SKIP_MCP=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}错误: 未知选项 $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# 显示帮助信息
show_help() {
    echo "用法: $0 -k <API_KEY> -m <MODEL> [-z <ZAI_API_KEY>] [--skip-mcp]"
    echo ""
    echo "必需参数:"
    echo "  -k, --key <API_KEY>        指定GLM API密钥 (必需)"
    echo "  -m, --model <MODEL>        指定模型名称 (必需)"
    echo ""
    echo "可选参数:"
    echo "  -z, --zai-key <KEY>        指定ZAI API密钥 (用于MCP识图功能)"
    echo "  --skip-mcp                 跳过MCP服务器安装"
    echo "  -h, --help                 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -k your_api_key -m glm-4.7"
    echo "  $0 -k your_api_key -m glm-4.7 -z your_zai_key"
    echo "  $0 -k your_api_key -m glm-4-plus --skip-mcp"
    echo ""
    echo "可用模型版本:"
    echo "  glm-4.7       - GLM-4.7 (最新版本)"
    echo "  glm-4-plus    - GLM-4 Plus"
    echo "  glm-4-air     - GLM-4 Air (轻量版)"
    echo "  glm-4-airx    - GLM-4 AirX"
    echo "  glm-4-flash   - GLM-4 Flash (快速版)"
    echo "  glm-4-long    - GLM-4 Long (长文本)"
    echo "  glm-4v        - GLM-4V (视觉版)"
    echo "  glm-4v-plus   - GLM-4V Plus"
    echo ""
    echo "注意:"
    echo "  - API密钥和模型名称必须通过命令行参数指定"
    echo "  - 如需使用MCP功能(识图、联网搜索)，请提供ZAI密钥"
}

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

# 验证必需参数
validate_params() {
    if [[ -z "$API_KEY" ]]; then
        print_error "错误: 未指定API密钥"
        echo ""
        echo "使用 -k 或 --key 参数指定GLM API密钥"
        echo "使用 -h 查看帮助信息"
        echo ""
        exit 1
    fi

    if [[ -z "$MODEL_NAME" ]]; then
        print_error "错误: 未指定模型名称"
        echo ""
        echo "使用 -m 或 --model 参数指定模型"
        echo "使用 -h 查看帮助信息"
        echo ""
        exit 1
    fi
}

# 显示开始信息
show_header() {
    echo "========================================"
    echo "  Claude Code + GLM 一键配置脚本  "
    echo "========================================"
    echo "基于智谱AI官方推荐方式配置"
    echo "API密钥: ${API_KEY:0:10}...${API_KEY: -10}"
    echo "模型: $MODEL_NAME"
    if [[ -n "$ZAI_API_KEY" ]]; then
        echo "ZAI密钥: ${ZAI_API_KEY:0:10}...${ZAI_API_KEY: -10}"
    else
        echo "ZAI密钥: 未提供 (MCP功能将跳过)"
    fi
    echo ""
}

# 安装Node.js和npm（如果未安装）
install_nodejs() {
    print_step "检查Node.js和npm安装状态..."

    if ! command -v node >/dev/null 2>&1; then
        print_info "Node.js未安装，正在安装..."
        # 更新包列表
        apt update

        # 安装Node.js LTS版本
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
}

# 清理旧的Claude Code安装
clean_old_installation() {
    print_step "清理旧的Claude Code安装..."

    # 卸载npm包
    npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true

    # 删除可执行文件
    rm -f /usr/local/bin/claude 2>/dev/null || true
    rm -f /usr/bin/claude 2>/dev/null || true

    # 删除配置目录
    rm -rf ~/.claude 2>/dev/null || true
    rm -rf /root/.claude 2>/dev/null || true

    print_success "旧安装清理完成"
}

# 安装Claude Code
install_claude_code() {
    print_step "安装Claude Code..."

    # 使用npm安装全局包
    npm install -g @anthropic-ai/claude-code

    print_success "Claude Code安装完成"
}

# 配置GLM
configure_glm() {
    print_step "配置 $MODEL_NAME..."

    # 创建配置目录
    mkdir -p ~/.claude

    # 创建配置文件（基于智谱AI官方推荐）
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

    print_success "$MODEL_NAME 配置完成"
}

# 设置环境变量
setup_environment() {
    print_step "设置环境变量..."

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

    # 检查环境变量是否设置成功
    print_info "检查环境变量设置状态..."

    # 检查当前会话的环境变量
    if [[ -n "$ANTHROPIC_AUTH_TOKEN" ]]; then
        print_success "✓ 当前会话 ANTHROPIC_AUTH_TOKEN 已设置"
    else
        print_warning "⚠ 当前会话 ANTHROPIC_AUTH_TOKEN 未设置"
    fi

    if [[ -n "$ANTHROPIC_BASE_URL" ]]; then
        print_success "✓ 当前会话 ANTHROPIC_BASE_URL 已设置: $ANTHROPIC_BASE_URL"
    else
        print_warning "⚠ 当前会话 ANTHROPIC_BASE_URL 未设置"
    fi

    if [[ -n "$ANTHROPIC_MODEL" ]]; then
        print_success "✓ 当前会话 ANTHROPIC_MODEL 已设置: $ANTHROPIC_MODEL"
    else
        print_warning "⚠ 当前会话 ANTHROPIC_MODEL 未设置"
    fi

    if [[ ":$PATH:" == *":$npm_bin_path:"* ]]; then
        print_success "✓ 当前会话 PATH 包含npm bin路径"
    else
        print_warning "⚠ 当前会话 PATH 不包含npm bin路径: $npm_bin_path"
    fi

    # 检查shell配置文件是否正确写入
    print_info "检查shell配置文件写入状态..."

    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            # 检查API密钥是否写入
            if grep -q "ANTHROPIC_AUTH_TOKEN=\"${API_KEY}\"" "$config" 2>/dev/null; then
                print_success "✓ $config 包含正确的API密钥"
            else
                print_warning "⚠ $config 缺少正确的API密钥"
            fi

            # 检查API基础URL是否写入
            if grep -q "ANTHROPIC_BASE_URL=\"https://open.bigmodel.cn/api/anthropic\"" "$config" 2>/dev/null; then
                print_success "✓ $config 包含正确的API基础URL"
            else
                print_warning "⚠ $config 缺少正确的API基础URL"
            fi

            # 检查模型配置是否写入
            if grep -q "ANTHROPIC_MODEL=\"${MODEL_NAME}\"" "$config" 2>/dev/null; then
                print_success "✓ $config 包含正确的模型配置"
            else
                print_warning "⚠ $config 缺少正确的模型配置"
            fi

            # 检查PATH配置是否写入
            if grep -q "PATH=\"$npm_bin_path" "$config" 2>/dev/null; then
                print_success "✓ $config 包含正确的PATH配置"
            else
                print_warning "⚠ $config 缺少正确的PATH配置"
            fi
        fi
    done

    print_success "环境变量设置完成"
}

# 验证GLM配置
verify_glm_config() {
    print_step "验证 $MODEL_NAME 配置..."

    local config_file="$HOME/.claude/settings.json"

    if [[ -f "$config_file" ]]; then
        print_info "检查配置文件: $config_file"

        # 检查API密钥
        if grep -q "${API_KEY}" "$config_file" 2>/dev/null; then
            print_success "✓ API密钥配置正确"
        else
            print_error "✗ API密钥配置错误"
            return 1
        fi

        # 检查模型配置
        if grep -q "$MODEL_NAME" "$config_file" 2>/dev/null; then
            print_success "✓ 模型配置为 $MODEL_NAME"
        else
            print_error "✗ 模型配置错误"
            return 1
        fi

        # 检查API基础URL
        if grep -q "https://open.bigmodel.cn/api/anthropic" "$config_file" 2>/dev/null; then
            print_success "✓ API基础URL配置正确"
        else
            print_error "✗ API基础URL配置错误"
            return 1
        fi

        # 显示完整配置（隐藏敏感信息）
        print_info "配置文件内容预览："
        cat "$config_file" | sed "s/${API_KEY}/${API_KEY:0:10}...${API_KEY: -10}/g"

    else
        print_error "✗ 配置文件不存在: $config_file"
        return 1
    fi

    print_success "$MODEL_NAME 配置验证完成"
}

# 安装MCP服务器
install_mcp_servers() {
    if [[ "$SKIP_MCP" -eq 1 ]]; then
        print_info "已跳过MCP服务器安装 (--skip-mcp)"
        return
    fi

    if [[ -z "$ZAI_API_KEY" ]]; then
        print_info "未提供ZAI密钥，跳过MCP服务器安装"
        print_info "如需使用MCP功能(识图、联网搜索)，请使用 -z 参数提供ZAI密钥"
        return
    fi

    print_step "安装智谱MCP服务器..."

    # 1. 安装zai-mcp-server (识图MCP)
    print_install "安装zai-mcp-server (识图功能)..."
    if command -v claude >/dev/null 2>&1; then
        claude mcp add -s user zai-mcp-server --env Z_AI_API_KEY=$ZAI_API_KEY -- npx -y "@z_ai/mcp-server" 2>/dev/null || print_warning "zai-mcp-server安装可能失败，请手动检查"
        print_success "zai-mcp-server安装命令已执行"
    else
        print_warning "Claude Code不可用，跳过MCP安装"
    fi

    # 2. 安装web-search-prime (联网搜索MCP)
    print_install "安装web-search-prime (联网搜索)..."
    if command -v claude >/dev/null 2>&1; then
        claude mcp add -s user -t http web-search-prime https://open.bigmodel.cn/api/mcp/web_search_prime/mcp --header "Authorization: Bearer $ZAI_API_KEY" 2>/dev/null || print_warning "web-search-prime安装可能失败，请手动检查"
        print_success "web-search-prime安装命令已执行"
    else
        print_warning "Claude Code不可用，跳过MCP安装"
    fi

    print_success "MCP服务器安装完成"
}

# 验证安装
verify_installation() {
    print_step "验证安装..."

    # 确保PATH包含npm bin路径
    local npm_bin_path="$(npm root -g)/../bin"
    if [[ -d "$npm_bin_path" ]]; then
        export PATH="$npm_bin_path:$PATH"
        print_info "已更新PATH以包含npm bin路径: $npm_bin_path"
    fi

    # 清理命令缓存
    hash -r 2>/dev/null || true

    # 检查claude命令
    if command -v claude >/dev/null 2>&1; then
        print_success "✓ Claude Code命令可用: $(which claude)"

        # 显示版本信息
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
    if [[ -f ~/.claude/settings.json ]]; then
        print_success "✓ 配置文件存在: ~/.claude/settings.json"
        print_info "配置内容预览:"
        cat ~/.claude/settings.json | head -10
    else
        print_error "✗ 配置文件不存在"
        return 1
    fi

    # 检查环境变量
    if [[ -n "$ANTHROPIC_API_KEY" ]]; then
        print_success "✓ API密钥已设置: ${ANTHROPIC_API_KEY:0:10}...${ANTHROPIC_API_KEY: -10}"
    else
        print_warning "⚠ 当前会话环境变量未设置，请重新加载shell或运行: source ~/.bashrc"
    fi

    if [[ -n "$ANTHROPIC_BASE_URL" ]]; then
        print_success "✓ API基础URL已设置: $ANTHROPIC_BASE_URL"
    else
        print_warning "⚠ API基础URL未设置"
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    echo "========================================"
    echo "           配置完成！使用说明            "
    echo "========================================"
    echo ""
    echo "🚀 启动Claude Code:"
    echo "   claude"
    echo ""
    echo "🔧 强制指定 $MODEL_NAME 模型启动:"
    echo "   claude --model $MODEL_NAME"
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
    echo "   - 已配置模型: $MODEL_NAME"
    echo "   - API提供商: 智谱AI (bigmodel.cn)"
    echo "   - 配置文件: ~/.claude/settings.json"
    echo "   - npm bin路径: $(npm root -g)/../bin"
    echo ""
    if [[ -n "$ZAI_API_KEY" ]]; then
        echo "🔌 已安装MCP服务器:"
        echo "   - zai-mcp-server: 识图功能"
        echo "   - web-search-prime: 联网搜索"
        echo ""
        echo "💡 MCP使用方法:"
        echo "   - 在Claude Code中直接上传图片进行识图"
        echo "   - 使用联网搜索获取最新信息"
    else
        echo "🔌 MCP服务器: 未安装 (使用 -z 参数提供ZAI密钥以安装)"
    fi
    echo ""
    echo "========================================"
}

# 主函数
main() {
    # 解析参数
    parse_args "$@"

    # 验证参数
    validate_params

    show_header
    check_root

    # 安装步骤
    install_nodejs
    clean_old_installation
    install_claude_code
    configure_glm
    setup_environment

    # 安装MCP服务器
    install_mcp_servers

    # 验证和说明
    verify_glm_config
    verify_installation
    show_usage

    # 提供立即可用的启动方式
    print_info "立即可用的启动方式："
    print_info "npx @anthropic-ai/claude-code"
    echo ""
    print_success "🎉 Claude Code + $MODEL_NAME 配置完成！"
}

# 执行主函数
main "$@"
