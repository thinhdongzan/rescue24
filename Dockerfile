FROM python:3.10-slim

WORKDIR /app

# Cài đặt các gói hệ thống cần thiết (nếu có)
RUN apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Copy file requirements và cài đặt
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ source code
COPY backend/ ./backend/
COPY frontend/ ./frontend/

# Khởi tạo dữ liệu mẫu ban đầu (sẽ được đóng gói cứng vào Image)
# Điều này giúp mỗi lần Render reset server, data lại tự động trở về trạng thái sạch ban đầu.
RUN python backend/generate_seed_data.py

# Cấu hình biến môi trường cho Render
# Render sử dụng biến PORT (mặc định 10000)
ENV PORT=10000
ENV FRONTEND_PORT=10000
ENV BACKEND_PORT=8000
ENV BACKEND_URL="http://127.0.0.1:8000/api/v1"

# Tạo script chạy song song Backend (cổng 8000) và Frontend (cổng 10000)
RUN echo '#!/bin/sh' > start.sh && \
    echo 'echo "Starting Backend API..."' >> start.sh && \
    echo 'python -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000 & ' >> start.sh && \
    echo 'sleep 2' >> start.sh && \
    echo 'echo "Starting Frontend UI..."' >> start.sh && \
    echo 'cd frontend && FRONTEND_PORT=$PORT python main.py' >> start.sh && \
    chmod +x start.sh

# Chạy hệ thống
CMD ["./start.sh"]
