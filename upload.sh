#!/bin/bash
# Run from the source root: ./upload.sh <codename>
# BOT_TOKEN & CHAT_ID must be exported as env variable

[[ $# -eq 0 ]] && { echo "Usage: ./upload.sh <codename>"; exit 1; }

CODENAME="$1"
OUT="out/target/product/$CODENAME"

[[ -d "$OUT" ]] || { echo "ERROR: $OUT not found"; exit 1; }

ZIP=$(find "$OUT" -maxdepth 1 -type f -name "*.zip" -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)
[[ -n "$ZIP" ]] || { echo "ERROR: No ROM zip found in $OUT"; exit 1; }

# gofile <file> [folderId] [token] -> prints the JSON response
gofile() {
    local args=(-F "file=@$1")
    [[ -n "$2" ]] && args+=(-F "folderId=$2" -H "Authorization: Bearer $3")
    echo "Uploading: $(basename "$1")" >&2
    curl --progress-bar -X POST "${args[@]}" "https://upload.gofile.io/uploadfile"
}

BUTTONS='[]'
button() {  # button "Label" url
    BUTTONS=$(jq -c --arg t "$1" --arg u "$2" '. + [[{text:$t,url:$u}]]' <<<"$BUTTONS")
}

add() {  # add "Label" file
    [[ -f "$2" ]] || { echo "Skipping (not found): $2" >&2; return; }
    local resp link
    resp=$(gofile "$2")
    link=$(jq -r '.data.downloadPage // empty' <<<"$resp")
    [[ -n "$link" ]] || { echo "Upload failed: $resp" >&2; return; }
    button "$1" "$link"
}

# All .json files in the out dir go into one GoFile folder (one link)
add_json() {
    local f resp link="" folder="" token=""
    while IFS= read -r f; do
        resp=$(gofile "$f" "$folder" "$token")
        if [[ -z "$folder" ]]; then
            link=$(jq -r '.data.downloadPage // empty' <<<"$resp")
            folder=$(jq -r '.data.parentFolder // empty' <<<"$resp")
            token=$(jq -r '.data.guestToken // empty' <<<"$resp")
            [[ -n "$link" ]] || { echo "Upload failed: $resp" >&2; folder=""; continue; }
        elif [[ "$(jq -r .status <<<"$resp")" != "ok" ]]; then
            echo "Upload failed: $f" >&2
        fi
        done < <(find "$OUT" -maxdepth 1 -type f -name "*.json" ! -name "installed-files*.json" ! -name "module-info.json" | sort)
    [[ -n "$link" ]] && button "Download JSON" "$link"
}

add "Download ROM"         "$ZIP"
add "Download Recovery"    "$OUT/recovery.img"
add "Download Boot"        "$OUT/boot.img"
add "Download Init Boot"   "$OUT/init_boot.img"
add "Download Vendor Boot" "$OUT/vendor_boot.img"
add_json

[[ "$(jq length <<<"$BUTTONS")" -gt 0 ]] || { echo "Nothing uploaded."; exit 1; }

NAME=$(basename "$ZIP" .zip)
RAW=$(grep -oE '[0-9]{8}' <<<"$NAME" | head -1)
DATE=${RAW:+${RAW:0:4}-${RAW:4:2}-${RAW:6:2}}
DATE=${DATE:-$(date +%F)}
SIZE=$(awk -v s="$(wc -c < "$ZIP")" 'BEGIN{printf "%.2f GB", s/1073741824}')
MD5=$(md5sum "$ZIP" | cut -d' ' -f1)

printf -v TEXT '#%s | #stable | #unofficial\n\n🌟 Flash responsibly and enjoy!\n\n• ROM: %s\n• SIZE: %s\n\n• DEVICE: %s\n• DATE: %s\n\n• MD5SUM: <code>%s</code>' \
    "$CODENAME" "$NAME" "$SIZE" "$CODENAME" "$DATE" "$MD5"

TG=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${TEXT}" \
    --data-urlencode "parse_mode=HTML" \
    --data-urlencode "disable_web_page_preview=true" \
    --data-urlencode "reply_markup=$(jq -cn --argjson k "$BUTTONS" '{inline_keyboard:$k}')")

[[ "$(jq -r .ok <<<"$TG")" == "true" ]] && echo "Posted to Telegram." || { echo "Telegram failed: $TG"; exit 1; }
