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
    processes="rev.py negan.py prxscan.py monitor.sh setup.sh start.sh"  # Danh sách các tiến trình cần kill
    for process in $processes; do
        echo "Đang kill tiến trình: $process"

        # Kill tiến trình chính
        pkill -9 -f "$process" 2>/dev/null || true  # Bỏ qua lỗi và không hiển thị thông báo lỗi

        # Kill các tiến trình con (nếu có)
        for pid in $(pgrep -f "$process"); do
            echo "Đang kill tiến trình con của $process (PID: $pid)"
            pkill -9 -P "$pid" 2>/dev/null || true  # Bỏ qua lỗi và không hiển thị thông báo lỗi
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
    killall -9 -q $processes 2>/dev/null || true  # Bỏ qua lỗi và không hiển thị thông báo lỗi

    # Kiểm tra lại lần cuối
    for process in $processes; do
        if pgrep -f "$process" > /dev/null; then
            echo "Cảnh báo: Tiến trình $process vẫn đang chạy."
        else
            echo "Xác nhận: Tiến trình $process đã bị kill."
        fi
    done
}

# Hàm đếm ngược thời gian
countdown() {
    local seconds=$1
    while [ $seconds -gt 0 ]; do
        echo "Thời gian sleep còn lại: $seconds giây"
        sleep 1
        seconds=$((seconds - 1))
    done
}

python3 negan.py &
NEGAN_PID=$!

# Chạy proxy scanner
python3 prxscan.py -l list.txt &
PRXSCAN_PID=$!

# Đợi 9 phút 30 giây (570 giây)
echo "Đang đợi 9 phút 30 giây..."
countdown 570 &
COUNTDOWN_PID=$!

# Đợi countdown hoàn thành
if wait $COUNTDOWN_PID 2>/dev/null; then
    # Kiểm tra xem script có bị kill đột ngột không
    if kill -0 $$ 2>/dev/null; then
        # Sau khi countdown hoàn thành, chạy setup.sh
        echo "Đang chạy setup.sh..."
        ./setup.sh > /dev/stdout 2>&1 &
        SETUP_PID=$!

        # Đợi setup.sh hoàn thành
        wait $SETUP_PID

        # Sau khi setup.sh hoàn thành, thực hiện kill các tiến trình
        echo "setup.sh đã hoàn thành. Đang kill các tiến trình..."
        strong_kill
    else
        echo "Script bị kill đột ngột. Không chạy setup.sh."
        strong_kill
        exit 1
    fi
else
    echo "Countdown bị gián đoạn. Không chạy setup.sh."
    strong_kill
    exit 1
fi
