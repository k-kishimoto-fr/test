# Ubuntu 24.04 LTS Desktop ISO (約2.6GB)
URL="http://ftp.jaist.ac.jp/pub/Linux/ubuntu-releases/24.04/ubuntu-24.04-desktop-amd64.iso"

curl -L -o /dev/null -sS --no-buffer \
-w "\n[結果確認]\n取得サイズ: %{size_download} bytes\n経過時間: %{time_total} s\n平均受信速度: %{speed_download} byte/s\n" \
$URL