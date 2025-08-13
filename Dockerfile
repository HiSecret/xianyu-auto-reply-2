# 使用更小的基础镜像（Alpine版）
FROM python:3.11-alpine

LABEL maintainer="zhinianboke" \
      version="2.1.0" \
      description="闲鱼自动回复系统 - 企业级多用户版本，支持自动发货和免拼发货" \
      repository="https://github.com/zhinianboke/xianyu-auto-reply" \
      license="仅供学习使用，禁止商业用途" \
      author="zhinianboke"

WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=Asia/Shanghai \
    DOCKER_ENV=true \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    NODE_PATH=/usr/lib/node_modules

# 安装系统依赖（精简版）
RUN apk update && \
    apk add --no-cache \
        nodejs \
        npm \
        tzdata \
        curl \
        ca-certificates \
        libjpeg \
        libpng \
        freetype \
        # 安装最小字体依赖
        ttf-dejavu \
        ttf-liberation \
        # 安装Playwright的浏览器依赖
        nss \
        atk \
        libdrm \
        libxkbcommon \
        libxcomposite \
        libxdamage \
        libxrandr \
        libxss \
        alsa-lib \
        at-spi2-atk \
        gtk3 \
        gdk-pixbuf \
        x11-utils \
        xdg-utils && \
    rm -rf /var/cache/apk/* /tmp/*

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 验证 Node.js 版本
RUN node --version && npm --version

# 复制 requirements.txt 并安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 复制项目文件
COPY . .

# 安装 Playwright 浏览器
RUN playwright install chromium

# 创建必要的目录并设置权限
RUN mkdir -p /app/logs /app/data /app/backups /app/static/uploads/images && \
    chmod 777 /app/logs /app/data /app/backups /app/static/uploads /app/static/uploads/images

EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 复制启动脚本
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
