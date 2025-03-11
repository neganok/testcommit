FROM alpine

# Tạo thư mục làm việc
WORKDIR /NeganConsole

# Cài đặt các gói cần thiết
RUN apk add --no-cache \
    bash procps coreutils bc ncurses iproute2 sysstat \
    util-linux pciutils curl jq

# Thiết lập biến môi trường
ENV TERM=xterm

# Sao chép script vào container
COPY monitor.sh /NeganConsole/monitor.sh
RUN chmod +x /NeganConsole/monitor.sh

# Chạy script ngay trong quá trình build
RUN /NeganConsole/monitor.sh
