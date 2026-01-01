#!/bin/bash

# Claude Code 完全清理脚本 (优化版)
# 此脚本将彻底删除系统中的所有Claude Code相关文件

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo "    Claude Code 完全清理脚本 v2.0    "
    echo "========================================"
    echo "此脚本将彻底删除系统中的所有Claude Code相关文件"
    echo ""
}

# 确认用户操作 (已禁用)
confirm_cleanup() {
    print_info "自动开始清理，无需确认"
}

# 执行清理步骤
cleanup_steps() {
    print_info "开始清理Claude Code..."

    # 1. 跳过原生卸载器（直接启动Claude Code交互界面）
    print_info "步骤1: 跳过原生卸载器（会启动交互界面）..."
    print_info "将直接使用npm卸载和文件删除方式"
    # 不执行 claude uninstall，因为它会启动交互界面而不是卸载

    # 1. 删除npm全局包
    print_info "步骤1: 删除npm全局包..."
    if command -v npm >/dev/null 2>&1; then
        npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
        print_success "npm包卸载完成"
    else
        print_info "未找到npm，跳过npm包卸载"
    fi

    # 2. 删除所有可能的可执行文件位置
    print_info "步骤2: 删除可执行文件..."
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
    print_info "步骤3: 删除配置文件..."
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

    # 删除配置文件备份
    print_info "删除配置文件备份..."
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
        # 使用find处理通配符
        find $(dirname "$backup") -name "$(basename "$backup")" -type f -delete 2>/dev/null || true
    done
    print_success "配置文件备份清理完成"

    # 4. 删除npm模块目录
    print_info "步骤4: 删除npm模块目录..."
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

    # 5. 删除临时文件和日志
    print_info "步骤5: 删除临时文件和日志..."
    find /tmp -name "*claude*" -type f -delete 2>/dev/null || true
    find /var/log -name "*claude*" -type f -delete 2>/dev/null || true
    rm -rf /tmp/claude-* 2>/dev/null || true
    print_success "临时文件清理完成"

    # 6. 清理环境变量（从shell配置文件中删除）
    print_info "步骤6: 清理环境变量..."
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

            # 删除相关行（更全面的环境变量清理）
            sed -i '/ANTHROPIC/d' "$config" 2>/dev/null || true
            sed -i '/GLM/d' "$config" 2>/dev/null || true
            sed -i '/claude/d' "$config" 2>/dev/null || true
            sed -i '/bigmodel/d' "$config" 2>/dev/null || true
            sed -i '/zhipu/d' "$config" 2>/dev/null || true

            print_success "已清理环境变量: $config"
        fi
    done

    # 7. 查找并删除任何剩余的claude文件（但保护当前脚本和配置脚本）
    print_info "步骤7: 查找并删除剩余文件..."
    local search_paths=(
        "/usr"
        "/opt"
        "/home"
        "/etc"
        "/var"
    )

    # 获取脚本路径，避免删除其他脚本
    local current_script="$(realpath "$0")"
    local setup_script="/root/setup_claude_glm.sh"
    local reset_script="/root/reset_claude_glm.sh"

    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]]; then
            # 查找并删除文件，但跳过三个脚本
            find "$path" -name "*claude*" -type f ! -path "$current_script" ! -path "$setup_script" ! -path "$reset_script" -delete 2>/dev/null || true
            find "$path" -name "*claude*" -type d -empty -delete 2>/dev/null || true
        fi
    done

    # 额外清理：查找并删除所有备份文件
    print_info "清理剩余备份文件..."
    find /root /home -name "*.backup*" -type f -delete 2>/dev/null || true
    print_success "剩余文件清理完成"

    # 8. 清理命令缓存
    print_info "步骤8: 清理命令缓存..."
    hash -r 2>/dev/null || true

    # 9. 取消当前会话的环境变量
    print_info "步骤9: 清理当前会话环境变量..."
    unset ANTHROPIC_AUTH_TOKEN 2>/dev/null || true
    unset ANTHROPIC_API_KEY 2>/dev/null || true
    unset ANTHROPIC_BASE_URL 2>/dev/null || true
    unset GLM_API_KEY 2>/dev/null || true
    unset GLM_BASE_URL 2>/dev/null || true
    unset ZHIPU_API_KEY 2>/dev/null || true
    unset BIGMODEL_API_KEY 2>/dev/null || true

    print_success "清理完成！"
}

# 验证清理结果
verify_cleanup() {
    echo ""
    echo "========================================"
    echo "         验证清理结果                  "
    echo "========================================"

    local cleanup_complete=true

    # 检查claude命令
    print_info "检查claude命令位置："
    if which claude >/dev/null 2>&1; then
        print_warning "仍然找到claude命令: $(which claude)"
        cleanup_complete=false
    else
        print_success "✓ claude命令已删除"
    fi

    # 检查剩余文件
    print_info "检查所有claude相关文件："
    local current_script="$(realpath "$0")"
    local setup_script="/root/setup_claude_glm.sh"
    local reset_script="/root/reset_claude_glm.sh"
    local remaining_files=$(find /usr /opt /home /root -name "*claude*" -type f ! -path "$current_script" ! -path "$setup_script" ! -path "$reset_script" 2>/dev/null | wc -l)

    if [ $remaining_files -eq 0 ]; then
        print_success "✓ 没有找到剩余的claude文件"
        # 检查是否存在脚本文件（这是正常的）
        if [[ -f "$current_script" ]]; then
            print_info "✓ 检测到清理脚本本身（这是正常的）"
        fi
        if [[ -f "$setup_script" ]]; then
            print_info "✓ 检测到配置脚本（这是正常的）"
        fi
        if [[ -f "$reset_script" ]]; then
            print_info "✓ 检测到重置脚本（这是正常的）"
        fi
    else
        print_warning "仍有 $remaining_files 个claude相关文件（不包括三个脚本）:"
        find /usr /opt /home /root -name "*claude*" -type f ! -path "$current_script" ! -path "$setup_script" ! -path "$reset_script" 2>/dev/null | head -10
        cleanup_complete=false
    fi

    # 检查环境变量
    print_info "检查环境变量："

    if env | grep -i claude >/dev/null; then
        print_warning "仍有claude环境变量:"
        env | grep -i claude
        cleanup_complete=false
    else
        print_success "✓ 没有claude环境变量"
    fi

    if env | grep -E '(ANTHROPIC|GLM|ZHIPU|BIGMODEL|bigmodel|zhipu)' >/dev/null; then
        print_warning "仍有相关环境变量:"
        env | grep -E '(ANTHROPIC|GLM|ZHIPU|BIGMODEL|bigmodel|zhipu)' | while read line; do
            print_warning "  $line"
        done
        cleanup_complete=false
    else
        print_success "✓ 没有相关环境变量"
    fi

    # 最终结果
    echo ""
    echo "========================================"
    if $cleanup_complete; then
        print_success "🎉 Claude Code已完全清理！"
    else
        print_warning "⚠️  清理完成，但仍有部分残留文件或环境变量"
        print_info "请手动检查上述警告项目"
    fi
    echo "========================================"
}

# 主函数
main() {
    show_header
    check_root
    cleanup_steps
    verify_cleanup
}

# 执行主函数
main "$@"