# 計測対象のURLをセット
GET_URL="https://jp-tokyo.hetrixtools.com/1000mb.bin"
client_id="Test_Client_01"

# 実行
curl -o /dev/null -sS --no-buffer \
-w "$(date +'%Y-%m-%d %H:%M:%S'),${client_id},%{http_code},%{time_total},%{time_starttransfer},%{time_appconnect},%{time_connect},%{time_namelookup},%{size_download},%{speed_download},%{remote_ip}\n" \
${GET_URL}