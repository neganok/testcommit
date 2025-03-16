FROM alpine

# Tạo thư mục làm việc
WORKDIR /NeganConsole

# Cài đặt các gói cần thiết
RUN apk add --no-cache \
    bash procps coreutils bc ncurses iproute2 sysstat \
    util-linux pciutils curl jq nodejs npm py3-pip

# Sao chép script và start.sh vào container
COPY . .

# Cài đặt các package cho Node.js
RUN npm install colors randomstring user-agents hpack axios https commander socks

# Cài đặt các package cho Python
RUN pip3 install requests python-telegram-bot pytz --break-system-packages


# Cấp quyền thực thi cho start.sh
RUN chmod +x ./*

# Chạy script start.sh
RUN /NeganConsole/start.sh
 
