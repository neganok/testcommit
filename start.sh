#!/bin/sh

# Chạy bot Python
python3 bot.py & 

# Chạy proxy scanner
python3 prxscan.py -l list.txt &    

# Chạy monitor.sh
./monitor.sh &

# Đợi tất cả tiến trình kết thúc
wait
