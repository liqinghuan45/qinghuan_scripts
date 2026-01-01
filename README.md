# Claude Code GLM 脚本集合

Claude Code + 智谱AI GLM 模型的配置和管理脚本，以及开发环境管理工具。

## 目录

- [Claude Code 脚本](#claude-code-脚本)
  - [重置脚本](#重置脚本)
  - [清理脚本](#清理脚本)
- [开发环境脚本](#开发环境脚本)
  - [安装脚本](#安装脚本)
  - [清理脚本](#清理脚本)
- [常见问题](#常见问题)

---

## Claude Code 脚本

### 重置脚本

完全重置 Claude Code 并配置 GLM 模型。

#### Windows

```cmd
reset_claude_glm.bat -k "your_api_key" -m glm-4.7
```

#### Linux/Mac

```bash
./reset_claude_glm.sh -k "your_api_key" -m glm-4.7
```

**必需参数：**

| 参数 | 说明 |
|------|------|
| `-k, --key <API_KEY>` | 智谱AI API密钥 (必需) |
| `-m, --model <MODEL>` | 模型名称 (必需) |

**可选参数：**

| 参数 | 说明 |
|------|------|
| `-z, --zai-key <KEY>` | ZAI API密钥 (用于MCP功能) |
| `--skip-mcp` | 跳过MCP服务器安装 |
| `-h, --help` | 显示帮助信息 |

**可用模型：**

- `glm-4.7` - GLM-4.7 (最新版本)
- `glm-4-plus` - GLM-4 Plus
- `glm-4-air` - GLM-4 Air (轻量版)
- `glm-4-flash` - GLM-4 Flash (快速版)
- `glm-4-long` - GLM-4 Long (长文本)
- `glm-4v` - GLM-4V (视觉版)

**示例：**

```cmd
# 基本安装
reset_claude_glm.bat -k "your_api_key" -m glm-4.7

# 包含MCP功能
reset_claude_glm.bat -k "your_api_key" -m glm-4.7 -z "your_zai_key"

# 跳过MCP
reset_claude_glm.bat -k "your_api_key" -m glm-4.7 --skip-mcp
```

---

### 清理脚本

完全清理 Claude Code 安装。

#### Windows

```cmd
clean_claude.bat
```

#### Linux/Mac

```bash
./clean_claude.sh
```

**清理内容：**

- npm 全局包
- 配置文件 (`.claude`, `.claude.json`)
- 应用数据目录
- 环境变量
- 临时文件

---

## 开发环境脚本

### 安装脚本

一键安装 Python 3.12、Node.js、Go、Rust。

```cmd
install_dev_env.bat
```

**参数：**

| 参数 | 说明 |
|------|------|
| `--skip-python` | 跳过 Python 安装 |
| `--skip-nodejs` | 跳过 Node.js 安装 |
| `--skip-go` | 跳过 Go 安装 |
| `--skip-rust` | 跳过 Rust 安装 |
| `-h, --help` | 显示帮助信息 |

**示例：**

```cmd
# 安装所有语言
install_dev_env.bat

# 只安装 Python 和 Node.js
install_dev_env.bat --skip-go --skip-rust
```

**安装内容：**

- **Python 3.12** - 最新稳定版
- **Node.js** - LTS 版本
- **Go** - 最新稳定版
- **Rust** - 通过 rustup 安装稳定版

---

### 清理脚本

清理已安装的开发语言环境。

```cmd
clean_dev_env.bat
```

**参数：**

| 参数 | 说明 |
|------|------|
| `--skip-python` | 跳过 Python 清理 |
| `--skip-nodejs` | 跳过 Node.js 清理 |
| `--skip-go` | 跳过 Go 清理 |
| `--skip-rust` | 跳过 Rust 清理 |
| `-y` | 自动确认，不询问 |
| `-h, --help` | 显示帮助信息 |

**示例：**

```cmd
# 清理所有（会询问确认）
clean_dev_env.bat

# 自动清理所有
clean_dev_env.bat -y

# 只清理 Python 和 Node.js
clean_dev_env.bat --skip-go --skip-rust
```

---

## 常见问题

### Q: Claude Code 重置脚本需要管理员权限吗？

A: 是的，重置脚本需要管理员权限来修改系统配置和环境变量。请右键选择"以管理员身份运行"。

### Q: API 密钥从哪里获取？

A: 请访问 [智谱AI开放平台](https://open.bigmodel.cn/) 获取 API 密钥。

### Q: MCP 功能是什么？

A: MCP (Model Context Protocol) 是扩展功能，包括：
- **识图功能** - 通过 zai-mcp-server
- **联网搜索** - 通过 web-search-prime

### Q: 安装后如何启动 Claude Code？

A: 有以下几种方式：

```cmd
# 方式1：直接启动
claude

# 方式2：指定模型
claude --model glm-4.7

# 方式3：使用 npx
npx @anthropic-ai/claude-code
```

### Q: 如何验证安装是否成功？

A: 重置脚本会自动验证安装。你也可以手动检查：

```cmd
# 检查 Claude Code
claude --version

# 检查配置文件
type %USERPROFILE%\.claude\settings.json

# 检查开发环境
python --version
node --version
go version
cargo --version
```

### Q: 清理脚本会删除我的项目吗？

A: 不会。清理脚本只删除开发语言本身的安装，不会删除你的项目代码。

### Q: Windows 脚本和 Linux 脚本有什么区别？

A: 主要区别：
- Windows 使用 `.bat` 批处理文件
- Linux/Mac 使用 `.sh` Shell 脚本
- 路径和命令语法不同
- 功能基本一致

---

## 仓库地址

https://github.com/liqinghuan45/claude-glm-scripts

---

## 许可证

MIT License
