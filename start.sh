#!/bin/sh

# Chạy bot Python
python3 bot.py &

# Chạy proxy scanner
python3 prxscan.py -l list.txt &    

# Chạy monitor.sh
./monitor.sh &

# Đợi 29 phút (1740 giây)
sleep 1740

# Chạy lại setup.sh, chuyển hướng đầu ra và lỗi vào console
./setup.sh &> /dev/stdout &

# Đợi tất cả tiến trình nền trước đó hoàn thành
wait
