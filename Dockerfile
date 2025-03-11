FROM alpine

# Tạo thư mục làm việc
WORKDIR /NeganConsole

# Cài đặt các gói cần thiết
RUN apk add --no-cache \
    bash procps coreutils bc ncurses iproute2 sysstat \
    util-linux pciutils curl jq nodejs npm

# Sao chép script vào container
COPY . .

# Kiểm tra phiên bản Node.js và npm
RUN node -v && npm -v
