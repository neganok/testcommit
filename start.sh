#!/bin/sh

# Hàm xử lý tín hiệu dừng
handle_exit() {
    echo "Nhận tín hiệu dừng. Đang dừng script mà không chạy sleep và setup.sh..."
    strong_kill
    exit 1
}

# Đăng ký hàm xử lý tín hiệu dừng
trap handle_exit TERM INT

# Hàm kill mạnh mẽ các tiến trình
strong_kill() {
    processes="rev.py negan.py prxscan.py monitor.sh setup.sh"  # Danh sách các tiến trình cần kill
    for process in $processes; do
        echo "Đang kill tiến trình: $process"

        # Kill tiến trình chính và các tiến trình con
        pids=$(pgrep -f "$process")
        if [ -n "$pids" ]; then
            for pid in $pids; do
                echo "Đang kill tiến trình $process (PID: $pid) và các tiến trình con của nó..."
                pkill -9 -P "$pid" 2>/dev/null || true  # Kill các tiến trình con
                kill -9 "$pid" 2>/dev/null || true      # Kill tiến trình chính
            done
        fi

        # Kiểm tra xem tiến trình đã bị kill chưa
        if pgrep -f "$process" > /dev/null; then
            echo "Cảnh báo: Không thể kill tiến trình $process."
        else
            echo "Đã kill tiến trình $process thành công."
        fi
    done
}

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

wait

# Sau khi setup.sh hoàn thành, thực hiện kill các tiến trình
echo "setup.sh đã hoàn thành. Đang kill các tiến trình..."
strong_kill

# Thông báo kết thúc script
echo "Script đã hoàn thành."
