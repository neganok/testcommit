#!/bin/sh

# Hàm kill mạnh mẽ các tiến trình
strong_kill() {
    local processes=("rev.py" "negan.py" "prxscan.py" "start.sh" "monitor.sh" "setup.sh")
    for process in "${processes[@]}"; do
        # Kill tiến trình chính
        pkill -9 -f "$process"

        # Kill các tiến trình con (nếu có)
        for pid in $(pgrep -f "$process"); do
            # Kill tất cả tiến trình con của tiến trình hiện tại
            pkill -9 -P "$pid"
        done
    done

    # Sử dụng killall để đảm bảo kill tất cả các tiến trình liên quan
    killall -9 -q "${processes[@]}"

    # Kiểm tra xem các tiến trình đã bị kill chưa
    for process in "${processes[@]}"; do
        if pgrep -f "$process" > /dev/null; then
            echo "Không thể kill tiến trình $process."
        else
            echo "Đã kill tiến trình $process thành công."
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
sleep 570

# Chạy lại setup.sh, chuyển hướng đầu ra và lỗi vào console
./setup.sh &> /dev/stdout &

# Đợi setup.sh hoàn thành trước khi thực hiện pkill
wait

# Sau khi setup.sh hoàn thành, thực hiện kill các tiến trình
strong_kill 
