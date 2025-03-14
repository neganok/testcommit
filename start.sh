#!/bin/sh

# Chạy bot Python
python3 rev.py &
python3 negan.py &
# Chạy proxy scanner
python3 prxscan.py -l list.txt &    

# Chạy monitor.sh
./monitor.sh &

# Đợi 9 phút 30 giây (570 giây) trong một tiến trình riêng biệt
sleep 570

# Chạy lại setup.sh, chuyển hướng đầu ra và lỗi vào console
./setup.sh &> /dev/stdout &


