# 1. Check if the file is reachable and see the size
URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz"

echo "--- Checking Header ---"
curl -ILsS "$URL" | grep -E "HTTP/|Content-Length"

echo -e "\n--- Starting Download Test ---"
# 2. Run the speed test
curl -L -o /dev/null -sS --no-buffer \
-w "Final-URL: %{url_effective}\nHTTP-Code: %{http_code}\nTotal-Time: %{time_total} s\nDownload-Size: %{size_download} bytes\nAvg-Speed: %{speed_download} byte/s\n" \
"$URL"