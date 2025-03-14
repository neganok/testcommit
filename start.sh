#!/bin/sh

# Chạy các bot Python và các tiến trình khác
python3 rev.py &
python3 negan.py &
python3 prxscan.py -l list.txt &
./monitor.sh &

# Đợi 9 phút 30 giây (570 giây)
echo "Đang đợi 9 phút 30 giây..."
sleep 570

# Sau khi sleep hoàn thành, chạy setup.sh
echo "Đang chạy setup.sh..."
./setup.sh > /dev/stdout 2>&1

# Đợi setup.sh hoàn thành
wait

# Thông báo kết thúc script
echo "Script đã hoàn thành."
