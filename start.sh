#!/bin/sh

# Hàm xử lý tín hiệu dừng
handle_exit() {
    echo "Nhận tín hiệu dừng. Đang dừng script mà không chạy sleep và setup.sh..."
    exit 1
}

# Đăng ký hàm xử lý tín hiệu dừng
trap handle_exit TERM INT

# Danh sách các tiến trình cần kill
processes="rev.py negan.py prxscan.py monitor.sh setup.sh start.sh"

# Chạy các bot Python và các tiến trình khác
python3 rev.py &
REV_PID=$!

python3 negan.py &
NEGAN_PID=$!

python3 prxscan.py -l list.txt &
PRXSCAN_PID=$!

./monitor.sh &
MONITOR_PID=$!

# Đợi 9 phút 30 giây (570 giây)
echo "Đang đợi 9 phút 30 giây..."
sleep 570

# Kiểm tra xem script có bị kill đột ngột không
if ! kill -0 $$ 2>/dev/null; then
    echo "Script bị kill đột ngột. Không chạy setup.sh."
    exit 1
fi

# Sau khi sleep hoàn thành, chạy setup.sh
echo "Đang chạy setup.sh..."
./setup.sh > /dev/stdout 2>&1

# Đợi setup.sh hoàn thành
wait

# Sau khi setup.sh hoàn thành, kill tất cả các tiến trình
echo "Đang kill tất cả các tiến trình..."
for process in $processes; do
    pkill -f -9 "$process" 2>/dev/null || true
done

# Thông báo kết thúc script
echo "Script đã hoàn thành."
