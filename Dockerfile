# 使用Python 3.11作为基础镜像
FROM python:3.11-slim

LABEL maintainer="zhinianboke" \
      version="2.1.0" \
      description="闲鱼自动回复系统 - 企业级多用户版本，支持自动发货和免拼发货" \
      repository="https://github.com/zhinianboke/xianyu-auto-reply" \
      license="仅供学习使用，禁止商业用途" \
      author="zhinianboke"

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=Asia/Shanghai \
    DOCKER_ENV=true \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    NODE_PATH=/usr/lib/node_modules

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nodejs \
        npm \
        tzdata \
        curl \
        ca-certificates \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
        fonts-dejavu-core \
        fonts-liberation2 \
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
        libatspi2.0-0 \
        libgtk-3-0 \
        libgdk-pixbuf-xlib-2.0-0 \
        libxcursor1 \
        libxi6 \
        libxrender1 \
        libxext6 \
        libx11-6 \
        libxft2 \
        libxinerama1 \
        libxtst6 \
        libappindicator3-1 \
        libx11-xcb1 \
        libxfixes3 \
        xdg-utils && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 验证 Node.js
RUN node --version && npm --version

# 复制 requirements.txt 并安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 复制项目文件
COPY . .

# 安装 Playwright 浏览器依赖和 Chromium
RUN playwright install chromium && \
    playwright install-deps chromium

# 创建必要的目录并设置权限
RUN mkdir -p /app/logs /app/data /app/backups /app/static/uploads/images && \
    chmod 777 /app/logs /app/data /app/backups /app/static/uploads /app/static/uploads/images

EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 启动脚本
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
