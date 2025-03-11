FROM alpine

# Cài đặt bash và curl
RUN apk update && apk add --no-cache \
    bash \
    curl \
    jq

# Tạo thư mục làm việc
WORKDIR /app

# Copy toàn bộ file từ thư mục hiện tại vào container
COPY . .

# Kiểm tra xem file có tồn tại không
RUN ls -lah /app

# Cấp quyền thực thi cho script
RUN chmod +x /app/monitor.sh

# Kiểm tra quyền thực thi
RUN ls -lah /app/monitor.sh

# Chạy script bằng Bash
RUN /bin/bash /app/monitor.sh
