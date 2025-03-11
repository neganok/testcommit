FROM alpine

# Tạo thư mục làm việc
WORKDIR /NeganConsole

# Cài đặt các gói cần thiết
RUN apk add --no-cache \
    bash procps coreutils bc ncurses iproute2 sysstat \
    util-linux pciutils curl jq

# Sao chép script vào container
COPY . .

# Cấp quyền thực thi cho script
RUN chmod +x monitor.sh


RUN node -v && npm -v

# Chạy script trong quá trình build
RUN /NeganConsole/monitor.sh

