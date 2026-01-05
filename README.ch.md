# XuguDB MCP 服务器

用于 [XuguDB](https://docs.xugudb.com/content/development/python) (虚谷数据库) 的模型上下文协议 (MCP) 服务器，支持完整的 DDL/DML 操作、多 LLM 提供商集成和 Chat2SQL（自然语言转 SQL）功能。

## 功能特性

- **完整数据库操作**：支持 SELECT、INSERT、UPDATE、DELETE、CREATE、ALTER、DROP
- **模式内省**：列出表、描述表结构、查看关系
- **Chat2SQL**：使用 LLM 将自然语言查询转换为 SQL（Claude、OpenAI、本地模型）
- **多 LLM 支持**：灵活的 LLM 提供商配置（Claude、OpenAI、zAI/智谱、本地/Ollama）
- **连接池**：高效的数据库连接管理
- **审计日志**：全面的安全操作日志
- **查询优化**：EXPLAIN 支持和优化建议

## 安装

### 前置要求

- Python 3.11+
- XuguDB 数据库实例
- （可选）用于 Chat2SQL 功能的 LLM API 密钥

### 使用 uv 安装

```bash
# 克隆仓库
git clone <repository-url>
cd xugu-mcp

# 安装依赖
uv sync

# 或以开发模式安装
uv pip install -e ".[dev]"
```

### 使用 pip 安装

```bash
pip install -e .
```

## 配置

### 环境变量

复制 `.env.example` 到 `.env` 并配置：

```bash
cp .env.example .env
```

关键配置：

```bash
# 数据库
XUGU_DB_HOST=localhost
XUGU_DB_PORT=5138
XUGU_DB_DATABASE=SYSTEM
XUGU_DB_USER=SYSDBA
XUGU_DB_PASSWORD=your_password

# LLM（用于 Chat2SQL）
CHAT2SQL_MODE=lightweight  # 'lightweight'（默认，无需 API key）或 'standalone'（需要 API key）
LLM_PROVIDER=claude  # 或 openai, zai, zhipu, local, ollama
LLM_MODEL=claude-3-5-sonnet-20241022
LLM_API_KEY=your_api_key  # 仅在 standalone 模式下需要
LLM_BASE_URL=  # 可选的自定义 API URL
LLM_TEMPERATURE=0.0
LLM_MAX_TOKENS=4096
```

### 配置文件

你也可以使用 `config/config.yaml` 进行配置（环境变量会覆盖文件配置）。

### LLM 提供商

服务器支持多个 LLM 提供商用于 Chat2SQL 功能：

| 提供商 | 描述 | 默认模型 | 需要 API 密钥 |
|--------|------|----------|---------------|
| **claude** | Anthropic Claude | claude-3-5-sonnet-20241022 | 是 |
| **openai** | OpenAI GPT | gpt-4o-mini | 是 |
| **zai** | zAI (智谱 AI) | glm-4 | 是 |
| **zhipu** | 同 zai | glm-4 | 是 |
| **local** | 通过 Ollama 的本地模型 | llama3.2 | 否 |
| **ollama** | 同 local | llama3.2 | 否 |

**提供商注意事项：**
- **zAI/智谱**：API 基础 URL 默认为 `https://open.bigmodel.cn/api/paas/v4/`
- **本地/Ollama**：期望 Ollama 运行在 `http://localhost:11434/v1/`

**Chat2SQL 模式：**

#### 轻量级模式（Lightweight，默认）
- **无需 LLM API 密钥**
- MCP 提供模式上下文和 SQL 验证
- 由现有 LLM（如 Claude Desktop 中的 Claude）生成 SQL
- 更低延迟，更好的上下文感知
- 设置 `CHAT2SQL_MODE=lightweight`（或不设置，因为这是默认值）

#### 独立模式（Standalone）
- **需要配置 LLM_API_KEY**
- MCP 使用内部 LLM 生成 SQL
- 适用于纯 API 访问或客户端没有 LLM 的场景
- 设置 `CHAT2SQL_MODE=standalone` 并配置 `LLM_API_KEY`

**各模式的要求：**

| 模式 | 需要 API 密钥 | 使用场景 |
|------|---------------|----------|
| **lightweight** | 否 | Claude Desktop、带 LLM 的本地开发 |
| **standalone** | 是 | 纯 API 访问、远程服务器 |

**一般说明：**
- 其他数据库操作（查询、模式、DML、DDL）无需任何 LLM 配置即可工作
- 云提供商（claude、openai、zai、zhipu）在 standalone 模式下需要 `LLM_API_KEY`
- 本地提供商（local、ollama）不需要 API 密钥，但需要运行 Ollama

**可用模型：**
- Claude: claude-3-5-sonnet、claude-3-5-haiku、claude-3-opus
- OpenAI: gpt-4o、gpt-4o-mini、gpt-4-turbo、gpt-3.5-turbo
- zAI: glm-4、glm-4-plus、glm-4-air、glm-4-flash
- 本地: llama3.2、qwen2.5、mistral、codellama、gemma

## 使用方法

### 运行服务器

XuguDB MCP 服务器支持 **两种传输模式** 用于不同场景：

---

### 模式 1：Stdio 模式（本地开发）

**适用于：** 本地开发、Claude Desktop 集成

**传输方式：** 标准输入/输出 (stdio)

**启动命令：**

```bash
# 使用 uv（推荐）
uv run xugu-mcp

# 或直接使用 Python
python -m xugu_mcp.main
```

**工作原理：**
- 作为本地子进程运行
- 通过 stdin/stdout 通信
- 被 Claude Desktop 用于本地 MCP 连接
- 不需要网络端口

---

### 模式 2：HTTP/SSE 模式（远程/网络）

**适用于：** 远程服务器、网络访问、多客户端

**传输方式：** 带服务器发送事件 (SSE) 的 HTTP

**启动命令：**

```bash
# 设置环境变量
export XUGU_DB_HOST=your_database_host
export XUGU_DB_PORT=5138
export XUGU_DB_DATABASE=SYSTEM
export XUGU_DB_USER=SYSDBA
export XUGU_DB_PASSWORD=your_password

# 可选：配置 HTTP 服务器
export HTTP_SERVER_HOST=0.0.0.0    # 监听所有接口
export HTTP_SERVER_PORT=8000       # HTTP 端口

# 启动 HTTP 服务器
uv run xugu-mcp-http

# 或直接使用 Python
python -m xugu_mcp.http_server
```

**HTTP 服务器启动地址：** `http://0.0.0.0:8000`（默认）

**HTTP 端点：**
- **SSE 连接：** `http://your-host:8000/sse` - 用于流式传输的服务器发送事件
- **消息 POST：** `http://your-host:8000/messages/` - 客户端消息端点

**HTTP 服务器配置选项：**

```bash
# 服务器绑定
HTTP_SERVER_HOST=0.0.0.0          # 0.0.0.0 监听所有接口，127.0.0.1 仅本地
HTTP_SERVER_PORT=8000             # HTTP 端口号

# 安全（可选）
HTTP_SERVER_ENABLE_CORS=false     # 为 Web 客户端启用 CORS
HTTP_SERVER_ENABLE_AUTH=false     # 启用身份验证
HTTP_SERVER_AUTH_TOKEN=token      # 身份验证令牌

# 端点（通常无需更改）
HTTP_SERVER_SSE_ENDPOINT=/sse     # SSE 连接端点
HTTP_SERVER_MESSAGE_ENDPOINT=/messages/  # 消息 POST 端点
```

---

### 模式对比

| 功能 | Stdio 模式 | HTTP/SSE 模式 |
|------|------------|---------------|
| **传输方式** | 标准 I/O | HTTP (SSE) |
| **使用场景** | 本地开发 | 远程/网络访问 |
| **启动命令** | `uv run xugu-mcp` | `uv run xugu-mcp-http` |
| **需要端口** | 否 | 是（默认：8000）|
| **远程访问** | 否 | 是 |
| **多客户端** | 否 | 是 |
| **Claude Desktop** | ✅ 原生支持 | ✅ 通过 URL |
| **配置文件** | `claude_desktop_config.json` | `claude_desktop_config_http.json` |

---

### Claude Desktop 配置

#### 选项 1：Stdio 模式（本地）

使用此配置进行 stdio 传输的本地开发：

**位置：** `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)

```json
{
  "mcpServers": {
    "xugu": {
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "/Users/sp/workspace/xugu/xugu-mcp",
        "xugu-mcp"
      ],
      "env": {
        "XUGU_DB_HOST": "10.147.20.226",
        "XUGU_DB_PORT": "5138",
        "XUGU_DB_DATABASE": "SYSTEM",
        "XUGU_DB_USER": "SYSDBA",
        "XUGU_DB_PASSWORD": "SYSDBA",
        "LLM_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

#### 选项 2：HTTP/SSE 模式（远程/网络）

使用此配置进行远程服务器或需要网络访问的场景：

```json
{
  "mcpServers": {
    "xugu-remote": {
      "url": "http://127.0.0.1:8000/sse",
      "transport": "sse"
    }
  }
}
```

**注意：** 对于 HTTP 模式，在启动 Claude Desktop 之前确保 HTTP 服务器正在运行：

```bash
# 终端 1：启动 HTTP 服务器
XUGU_DB_HOST=10.147.20.226 \
XUGU_DB_PORT=5138 \
XUGU_DB_DATABASE=SYSTEM \
XUGU_DB_USER=SYSDBA \
XUGU_DB_PASSWORD=SYSDBA \
uv run xugu-mcp-http

# 终端 2：启动 Claude Desktop（它将连接到运行中的服务器）
open -a "Claude Desktop"
```

#### 选项 3：同时运行两种模式

你可以同时运行两种模式：

```json
{
  "mcpServers": {
    "xugu-local": {
      "command": "uv",
      "args": ["run", "--directory", "/Users/sp/workspace/xugu/xugu-mcp", "xugu-mcp"],
      "env": {
        "XUGU_DB_HOST": "10.147.20.226",
        "XUGU_DB_PORT": "5138",
        "XUGU_DB_DATABASE": "SYSTEM",
        "XUGU_DB_USER": "SYSDBA",
        "XUGU_DB_PASSWORD": "SYSDBA"
      }
    },
    "xugu-remote": {
      "url": "http://127.0.0.1:8000/sse",
      "transport": "sse"
    }
  }
}
```

---

### 快速开始示例

#### 本地开发 (Stdio)

```bash
# 1. 配置环境
export XUGU_DB_HOST=10.147.20.226
export XUGU_DB_PORT=5138
export XUGU_DB_DATABASE=SYSTEM
export XUGU_DB_USER=SYSDBA
export XUGU_DB_PASSWORD=SYSDBA

# 2. 启动服务器（stdio 模式）
uv run xugu-mcp

# 3. Claude Desktop 将自动连接
```

#### 远程服务器 (HTTP/SSE)

```bash
# 1. 配置环境
export XUGU_DB_HOST=10.147.20.226
export XUGU_DB_PORT=5138
export XUGU_DB_DATABASE=SYSTEM
export XUGU_DB_USER=SYSDBA
export XUGU_DB_PASSWORD=SYSDBA
export HTTP_SERVER_HOST=0.0.0.0
export HTTP_SERVER_PORT=8000

# 2. 启动 HTTP 服务器
uv run xugu-mcp-http

# 3. 测试 SSE 端点
curl http://localhost:8000/sse

# 预期响应：
# event: endpoint
# data: /messages/?session_id=<session_id>

# 4. 配置 Claude Desktop 使用 HTTP URL
# 参见上面的配置示例
```

### 故障排查

#### 端口已被占用

```bash
# 查找并终止占用端口 8000 的进程
lsof -ti:8000 | xargs kill -9

# 或使用不同的端口
export HTTP_SERVER_PORT=8001
uv run xugu-mcp-http
```

#### 连接被拒绝

```bash
# 检查 HTTP 服务器是否正在运行
curl http://localhost:8000/sse

# 检查服务器日志中的错误
# 确保 XUGU_DB_* 变量设置正确
```

#### Stdio 模式无响应

```bash
# 验证命令是否有效
uv run xugu-mcp

# 检查 Python 版本（需要 3.11+）
python --version

# 如需要重新安装依赖
uv sync
```

## MCP 工具

### 查询执行

| 工具 | 描述 |
|------|------|
| `execute_query` | 执行 SELECT 查询，可选限制返回行数 |
| `explain_query` | 获取查询执行计划 |
| `execute_batch` | 在事务中执行多个查询 |

### 模式内省

| 工具 | 描述 |
|------|------|
| `list_tables` | 列出所有表及其元数据 |
| `describe_table` | 获取详细的表结构 |
| `get_table_stats` | 获取表统计信息（行数、大小）|
| `list_indexes` | 列出表的索引 |
| `get_foreign_keys` | 获取外键关系 |
| `search_tables` | 按名称模式搜索表 |
| `list_views` | 列出所有数据库视图 |
| `list_columns` | 获取详细的列信息 |

### DML 操作

| 工具 | 描述 |
|------|------|
| `insert_rows` | 插入单行或多行 |
| `update_rows` | 更新符合 WHERE 条件的行 |
| `delete_rows` | 删除符合 WHERE 条件的行 |
| `upsert_rows` | 插入或更新行（UPSERT）|
| `truncate_table` | 清空表（快速删除所有）|
| `bulk_import` | 批量导入数据 |

### DDL 操作

| 工具 | 描述 |
|------|------|
| `create_database` | 创建新数据库 |
| `drop_database` | 删除数据库 |
| `create_schema` | 创建新 schema |
| `drop_schema` | 删除 schema |
| `create_table` | 创建包含列和约束的新表 |
| `drop_table` | 删除表（可选级联）|
| `alter_table` | 修改表结构（添加/删除/修改列）|
| `create_index` | 在表上创建索引 |
| `drop_index` | 删除索引 |
| `create_view` | 从 SELECT 语句创建视图 |
| `drop_view` | 删除视图 |
| `backup_table` | 创建表的备份副本 |

### Chat2SQL 操作

Chat2SQL 支持两种模式：

#### 轻量级模式（Lightweight，默认）
- **无需 LLM API 密钥** - 使用现有的 LLM（如 Claude Desktop 中的 Claude）
- MCP 仅提供模式上下文和验证
- 更低延迟，更好的上下文感知

| 工具 | 描述 |
|------|------|
| `get_schema_for_llm` | 获取数据库模式供 LLM 生成 SQL |
| `validate_sql_only` | 验证 SQL 安全性和语法 |
| `execute_validated_sql` | 执行经过验证的 SELECT 查询 |
| `get_table_schema_for_llm` | 获取详细的表模式 |
| `suggest_sql_from_schema` | 验证和改进用户 SQL |
| `get_lightweight_mode_info` | 获取轻量级模式信息 |

#### 独立模式（Standalone）
- **需要 LLM_API_KEY** - MCP 使用内部 LLM 生成 SQL
- 适用于纯 API 访问

| 工具 | 描述 |
|------|------|
| `natural_language_query` | 将自然语言转换为 SQL 并执行 |
| `explain_sql` | 用自然语言解释 SQL 查询 |
| `suggest_query` | 为自然语言问题建议 SQL |
| `validate_sql` | 使用安全检查验证 SQL |
| `optimize_query` | 获取优化建议 |
| `fix_sql` | 根据错误信息修复 SQL |
| `get_schema_context` | 获取查询相关的模式 |
| `clear_schema_cache` | 清除模式缓存 |
| `get_schema_info` | 获取模式缓存信息 |

### 安全与审计

| 工具 | 描述 |
|------|------|
| `get_audit_log` | 获取最近的审计日志条目 |
| `get_audit_statistics` | 获取最近时期的审计统计信息 |
| `get_rate_limit_stats` | 获取速率限制器统计信息 |
| `list_roles` | 列出所有可用角色 |
| `get_role_details` | 获取特定角色的详细信息 |
| `check_permission` | 检查角色是否有操作权限 |
| `get_security_status` | 获取整体安全状态 |

### 管理与监控

| 工具 | 描述 |
|------|------|
| `health_check` | 对 MCP 服务器执行健康检查 |
| `get_server_metrics` | 获取全面的服务器指标 |
| `get_connections` | 获取数据库连接池信息 |
| `test_query` | 测试数据库连接 |
| `get_server_info` | 获取服务器信息和配置 |
| `reload_config` | 重新加载配置 |
| `get_query_history` | 从审计日志获取最近的查询历史 |
| `clear_all_caches` | 清除所有服务器缓存 |
| `diagnose_connection` | 诊断数据库连接问题 |

### 数据库信息

| 工具 | 描述 |
|------|------|
| `get_database_info` | 获取数据库版本和信息 |

## MCP 资源

| 资源 URI | 描述 |
|----------|------|
| `schema://database/tables` | 完整的表目录 |
| `schema://database/info` | 数据库元数据 |
| `schema://database/relationships` | 外键关系 |
| `schema://database/indexes` | 所有数据库索引 |
| `schema://database/views` | 所有视图定义 |
| `schema://database/table/{name}` | 特定表的 schema |
| `meta://database/info` | 数据库版本和配置 |
| `meta://database/stats` | 数据库统计信息 |

## 开发状态

### 已完成 ✅

- **阶段 1**：基础框架
  - 包含所有目录的项目结构
  - 使用 Pydantic 的配置管理
  - 带事务的数据库连接管理器
  - 日志和错误处理工具
  - 带查询工具的基本 MCP 服务器

- **阶段 2**：查询工具和模式内省
  - 13 个 MCP 工具（查询、模式、数据库信息）
  - 8 个 MCP 资源（表、关系、索引、视图、元数据）
  - 模式探索工具（索引、外键、视图）

- **阶段 3**：DML 操作
  - 6 个 DML 工具（insert、update、delete、upsert、truncate、bulk_import）
  - 单行和批量操作
  - 参数化 WHERE 子句支持
  - 大数据集的批处理

- **阶段 4**：DDL 操作
  - 8 个 DDL 工具（create_table、drop_table、alter_table、create_index、drop_index、create_view、drop_view、backup_table）
  - 表和索引管理
  - 视图创建和管理
  - 表备份功能

- **阶段 5**：LLM 集成
  - 4 个 LLM 提供商（Claude、OpenAI、zAI/智谱、本地/Ollama）
  - LLM 基础接口和提供商工厂
  - 支持流式响应
  - 每个提供商的多模型支持

- **阶段 6**：Chat2SQL 引擎
  - 9 个 Chat2SQL 工具（自然语言转 SQL、解释、验证、优化、修复）
  - 带智能缓存的模式管理器
  - 带安全检查的 SQL 验证器
  - 用于注入防护的 SQL 清洁器
  - 带少样本学习的提示构建器

- **阶段 7**：安全与审计
  - 7 个安全与审计工具（审计日志、统计、角色、权限）
  - 所有操作的全面审计日志
  - 带滑动窗口和令牌桶的速率限制
  - 基于角色的访问控制（5 个预定义角色）
  - 查询执行钩子（执行前/执行后/错误）
  - 每客户端速率限制
  - 慢查询跟踪

- **阶段 8**：生产就绪
  - 9 个管理工具（健康检查、指标、诊断）
  - 系统指标收集（CPU、内存、磁盘使用）
  - 数据库连接池监控
  - 从审计日志获取查询历史
  - 缓存管理
  - 连接诊断
  - 服务器信息检索

### 进行中 🚧

### 计划中 📋

## HTTP 部署

### 生产部署

对于生产部署，建议使用：

1. **反向代理**：使用 Nginx 或 Traefik 作为反向代理
2. **进程管理器**：使用 systemd、supervisor 或 PM2
3. **SSL/TLS**：启用 HTTPS 以确保通信安全

#### Nginx 配置示例

```nginx
upstream xugu_mcp {
    server localhost:8000;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location /sse {
        proxy_pass http://xugu_mcp;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        proxy_cache off;
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
    }

    location /messages/ {
        proxy_pass http://xugu_mcp;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### Systemd 服务示例

```ini
[Unit]
Description=XuguDB MCP HTTP Server
After=network.target

[Service]
Type=simple
User=xugu
WorkingDirectory=/path/to/xugu-mcp
Environment="PATH=/path/to/uv/.local/bin"
ExecStart=/path/to/uv/.local/bin/uv run xugu-mcp-http
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Docker 部署

创建 `Dockerfile`：

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir uv && \
    uv pip install --system -e .

ENV HTTP_SERVER_HOST=0.0.0.0
ENV HTTP_SERVER_PORT=8000

EXPOSE 8000

CMD ["uv", "run", "xugu-mcp-http"]
```

构建和运行：

```bash
docker build -t xugu-mcp .
docker run -d -p 8000:8000 --env-file .env xugu-mcp
```

### 监控

HTTP 服务器公开了几个用于监控的端点：

- **健康检查**：使用 `health_check` 工具
- **指标**：使用 `get_server_metrics` 工具
- **审计日志**：使用 `get_audit_log` 工具

使用 curl 的示例：

```bash
# 健康检查（如果添加了专用的 HTTP 端点）
curl http://your-host:8000/health

# 通过 MCP 工具获取服务器指标
#（需要 MCP 客户端）
```

## 开发

### 项目结构

```
xugu-mcp/
├── src/xugu_mcp/
│   ├── main.py              # MCP 服务器入口点（stdio 模式）
│   ├── http_server.py       # MCP 服务器入口点（HTTP/SSE 模式）
│   ├── config/              # 配置管理
│   ├── db/                  # 数据库连接和操作
│   ├── llm/                 # LLM 提供商实现
│   ├── chat2sql/            # Chat2SQL 引擎
│   ├── mcp_tools/           # MCP 工具实现
│   ├── mcp_resources/       # MCP 资源实现
│   ├── security/            # 安全和审计
│   └── utils/               # 工具函数
├── config/                  # 配置文件
├── tests/                   # 测试套件
└── pyproject.toml           # 项目配置
```

### 运行测试

```bash
uv run pytest
```

### 代码质量

```bash
# 格式化代码
uv run black src/

# 检查
uv run ruff check src/

# 类型检查
uv run mypy src/
```

## 安全性

- **SQL 注入防护**：参数化查询和输入验证
- **审计日志**：所有数据库操作都被记录
- **速率限制**：可配置的查询速率限制
- **连接安全**：数据库连接的 SSL/TLS 支持

## 许可证

[你的许可证信息]

## 贡献

欢迎贡献！请提交问题或拉取请求。

## 参考资料

- [XuguDB Python 文档](https://docs.xugudb.com/content/development/python)
- [模型上下文协议](https://modelcontextprotocol.io/docs/)
