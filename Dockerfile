FROM alpine

# Tạo thư mục làm việc
WORKDIR /NeganConsole

# Cài đặt các gói cần thiết
RUN apk add --no-cache \
    bash procps coreutils bc ncurses iproute2 sysstat \
    util-linux pciutils curl jq nodejs npm py3-pip

# Sao chép script và start.sh vào container
COPY . .
COPY start.sh /start.sh

# Cấp quyền thực thi cho start.sh
RUN chmod +x /start.sh

# Chạy script start.sh
RUN /start.sh
