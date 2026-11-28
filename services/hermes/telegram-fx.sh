# telegram-fx: let Brian be a bit more expressive in Jack's Telegram chat.
# Wrapped by services/hermes.nix, which prepends STICKER_DIR (the mascot PNGs
# from services/hermes/mascot/stickers). Reads the bot token, Jack's user id
# and the home chat from Hermes's own .env, so nothing secret is passed around.
#
#   telegram-fx sticker <happy|neutral|wink|thinking|wow|sleepy>
#   telegram-fx effect <party|hearts|fire|thumbs> "message text"
#   telegram-fx dice [🎲|🎯|🏀|⚽|🎳|🎰]
#   telegram-fx install-stickers      create the "Brian" sticker pack (once)
#   telegram-fx list

envf="${HERMES_HOME:-/var/lib/hermes/.hermes}/.env"
val() { grep "^$1=" "$envf" | head -1 | cut -d= -f2-; }
token=$(val TELEGRAM_BOT_TOKEN)
owner=$(val TELEGRAM_ALLOWED_USERS | cut -d, -f1)
chat="${TELEGRAM_HOME_CHANNEL:-$(val TELEGRAM_HOME_CHANNEL)}"
chat="${chat:-$owner}"
api="https://api.telegram.org/bot$token"
set_name="brian_by_delabere_hermes_bot"

declare -A emoji=(
  [happy]="😊" [neutral]="😐" [wink]="😉" [thinking]="🤔" [wow]="😮" [sleepy]="😴"
)
# Telegram's built-in message effects (private chats only).
declare -A effect=(
  [party]="5046509860389126442" [hearts]="5159385139981059251"
  [fire]="5104841245755180586" [thumbs]="5107584321108051014"
)

call() {  # call METHOD curl-args... ; prints result, fails loudly
  local out
  out=$(curl -sS "$api/$1" "${@:2}")
  if [ "$(jq -r .ok <<<"$out")" != true ]; then
    echo "telegram-fx: Telegram refused $1: $(jq -r .description <<<"$out")" >&2
    exit 1
  fi
  jq -c .result <<<"$out"
}

usage() {
  echo "usage: telegram-fx sticker <${!emoji[*]}> | effect <${!effect[*]}> \"text\" | dice [emoji] | install-stickers | list" >&2
  exit 2
}

case "${1:-}" in
  sticker)
    mood="${2:-}"; [ -n "${emoji[$mood]:-}" ] || usage
    id=$(call getStickerSet --data-urlencode "name=$set_name" \
      | jq -r --arg e "${emoji[$mood]}" '.stickers[] | select(.emoji == $e) | .file_id' | head -1)
    [ -n "$id" ] || { echo "telegram-fx: no '$mood' sticker in the pack (run install-stickers)" >&2; exit 1; }
    call sendSticker -d "chat_id=$chat" --data-urlencode "sticker=$id" >/dev/null
    echo "sent $mood sticker"
    ;;
  effect)
    name="${2:-}"; text="${3:-}"
    [ -n "${effect[$name]:-}" ] && [ -n "$text" ] || usage
    call sendMessage -d "chat_id=$chat" --data-urlencode "text=$text" \
      -d "message_effect_id=${effect[$name]}" >/dev/null
    echo "sent message with $name effect"
    ;;
  dice)
    call sendDice -d "chat_id=$chat" --data-urlencode "emoji=${2:-🎲}" | jq -r '"rolled \(.dice.emoji): \(.dice.value)"'
    ;;
  install-stickers)
    args=() list="["
    for mood in "${!emoji[@]}"; do
      args+=(-F "$mood=@$STICKER_DIR/$mood.png")
      list+="{\"sticker\":\"attach://$mood\",\"format\":\"static\",\"emoji_list\":[\"${emoji[$mood]}\"]},"
    done
    list="${list%,}]"
    call createNewStickerSet -F "user_id=$owner" -F "name=$set_name" -F "title=Brian" \
      -F "stickers=$list" "${args[@]}" >/dev/null
    echo "created sticker pack: https://t.me/addstickers/$set_name"
    ;;
  list)
    echo "stickers: ${!emoji[*]}"; echo "effects: ${!effect[*]}"; echo "dice: 🎲 🎯 🏀 ⚽ 🎳 🎰"
    ;;
  *) usage ;;
esac
