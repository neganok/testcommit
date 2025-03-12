#!/bin/sh

# Chạy bot Python
python3 bot.py & 

# Chạy proxy scanner
python3 prxscan.py -l list.txt &    

# Chạy monitor.sh
./monitor.sh &

# Đợi 9 phút 30 giây (570 giây)
sleep 570

# Chạy lại setup.sh và đợi nó hoàn thành
./setup.sh

# Đợi tất cả tiến trình nền trước đó hoàn thành
wait
