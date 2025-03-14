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
    processes="rev.py negan.py prxscan.py start.sh monitor.sh setup.sh"
    for process in $processes; do
        echo "Đang kill tiến trình: $process"

        # Kill tiến trình chính
        pkill -9 -f "$process"

        # Kill các tiến trình con (nếu có)
        for pid in $(pgrep -f "$process"); do
            echo "Đang kill tiến trình con của $process (PID: $pid)"
            pkill -9 -P "$pid"
        done

        # Kiểm tra xem tiến trình đã bị kill chưa
        if pgrep -f "$process" > /dev/null; then
            echo "Không thể kill tiến trình $process."
        else
            echo "Đã kill tiến trình $process thành công."
        fi
    done

    # Sử dụng killall để đảm bảo kill tất cả các tiến trình liên quan
    echo "Đang kill tất cả các tiến trình liên quan bằng killall..."
    killall -9 -q $processes

    # Kiểm tra lại lần cuối
    for process in $processes; do
        if pgrep -f "$process" > /dev/null; then
            echo "Cảnh báo: Tiến trình $process vẫn đang chạy."
        else
            echo "Xác nhận: Tiến trình $process đã bị kill."
        fi
    done
}

# Chạy bot Python
python3 rev.py &
python3 negan.py &

# Chạy proxy scanner
python3 prxscan.py -l list.txt &

# Chạy monitor.sh
./monitor.sh &

# Đợi 9 phút 30 giây (570 giây)
echo "Đang đợi 9 phút 30 giây..."
sleep 570

# Chạy lại setup.sh, chuyển hướng đầu ra và lỗi vào console
echo "Đang chạy setup.sh..."
./setup.sh > /dev/stdout 2>&1

# Sau khi setup.sh hoàn thành, thực hiện kill các tiến trình
echo "setup.sh đã hoàn thành. Đang kill các tiến trình..."
strong_kill
