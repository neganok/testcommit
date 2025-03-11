FROM alpine


# Tạo thư mục làm việc
WORKDIR /NeganConsole


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

# Thiết lập biến môi trường
ENV TERM=xterm

# Tạo script để chạy
COPY . .


RUN chmod +x monitor.sh

# Chạy script khi container khởi động
RUN monitor.sh
 