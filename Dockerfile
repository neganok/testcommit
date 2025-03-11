FROM alpine

# Cài đặt các gói cần thiết
RUN apk update && apk add --no-cache \
    bash \
    procps \
    coreutils \
    bc \
    ncurses \
    iproute2 \
    sysstat \
    util-linux \
    pciutils \
    curl \
    jq

# Tạo thư mục làm việc
WORKDIR /app

# Copy toàn bộ file từ thư mục hiện tại vào container
COPY . .

# Cấp quyền thực thi cho monitor.sh
RUN chmod +x /app/monitor.sh

# Chạy script ngay khi build
RUN /app/monitor.sh
