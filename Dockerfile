# 使用官方 Python 镜像作为基础
FROM python:3.11-slim-bookworm

# 设置元数据标签
LABEL maintainer="zhinianboke" \
      version="2.1.0" \
      description="闲鱼自动回复系统"

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=Asia/Shanghai \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# 设置工作目录
WORKDIR /app

# 安装系统依赖（分阶段安装）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # 基础工具
        curl \
        ca-certificates \
        tzdata \
        gnupg \
        # Node.js 18.x
        && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
        && apt-get install -y nodejs \
        # Playwright 系统依赖
        && apt-get install -y --no-install-recommends \
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
            # 字体支持（使用可用的替代包）
            fonts-dejavu-core \
            fonts-liberation \
            fonts-noto-cjk \
            fonts-noto-color-emoji \
            fonts-freefont-ttf \
            # 图像处理
            libjpeg-dev \
            libpng-dev \
            libfreetype6-dev \
        && apt-get autoremove -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装 Playwright 和浏览器
RUN npm install -g playwright && \
    playwright install chromium && \
    playwright install-deps

# 复制项目文件（分阶段提高构建效率）
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

# 创建非root用户
RUN useradd -m appuser && \
    chown -R appuser:appuser /app
USER appuser

# 暴露端口和健康检查
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost:8080/health || exit 1

# 启动命令
CMD ["python", "main.py"]
