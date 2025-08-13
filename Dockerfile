# 使用官方 Python 镜像作为基础，并指定 slim 版本以减少体积
FROM python:3.11-slim-bookworm

# 设置元数据标签
LABEL maintainer="zhinianboke" \
      version="2.1.0" \
      description="闲鱼自动回复系统 - 企业级多用户版本" \
      repository="https://github.com/zhinianboke/xianyu-auto-reply" \
      license="仅供学习使用，禁止商业用途"

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=Asia/Shanghai \
    DOCKER_ENV=true \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    NODE_PATH=/usr/lib/node_modules

# 设置工作目录
WORKDIR /app

# 安装系统依赖（分阶段安装以提高构建速度）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # 基础工具
        curl \
        ca-certificates \
        tzdata \
        # Node.js 运行时（使用官方源）
        gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    # 安装 Playwright 系统依赖
    apt-get install -y --no-install-recommends \
        libnss3 \
        libnspr4 \
        libatk-bridge2.0-0 \
        libdrm2 \
        libxkbcommon0 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        libgbm1 \
        libxss1 \
        libasound2 \
        libgtk-3-0 \
        libgdk-pixbuf-2.0-0 \
        xdg-utils \
        # 字体支持
        fonts-dejavu-core \
        fonts-liberation \
        fonts-ubuntu \
        fonts-unifont \
        fonts-noto-color-emoji \
        # 图像处理
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev && \
    # 清理缓存
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 验证 Node.js 安装
RUN node --version && npm --version

# 先复制 requirements 文件单独安装依赖（利用 Docker 缓存层）
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 安装 Playwright（放在 Python 依赖之后）
RUN npm install -g playwright && \
    playwright install chromium && \
    playwright install-deps

# 复制项目文件
COPY . .

# 创建必要的目录并设置权限
RUN mkdir -p /app/{logs,data,backups,static/uploads/images} && \
    chmod -R 777 /app/{logs,data,backups,static/uploads}

# 创建非 root 用户并切换（增强安全性）
RUN useradd -m appuser && \
    chown -R appuser:appuser /app
USER appuser

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 使用 entrypoint 脚本
COPY --chown=appuser:appuser entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 启动命令
ENTRYPOINT ["/app/entrypoint.sh"]
