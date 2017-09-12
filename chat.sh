set -e

tpath="${1:?missing target scope}"
mkdir -p "${tpath}"

name_class='^[-a-zA-Z_]+$'

user_exists () {
  [ -d "${tpath}/${1}" ]
}

user_is_self () {
  [ "$1" = "${user_dir}" ]
}

user_prompt () {
  while :; do
    read -r -p 'username: ' user
    if ! LC_ALL=C egrep -q "${name_class}" <<< "$user"; then
        echo 'invalid username'
        continue
    fi

    if user_exists "$user"; then
        echo 'user already in use'
        continue
    fi
    break
  done
  user_dir="${tpath}/${user}"
  msg_fifo="${user_dir}/msg_queue"
}

user_del () {
  rm -rf "${user_dir}"
}

user_create () {
  user_prompt
  trap user_del EXIT
  mkdir -p "${user_dir}"
  mkfifo "${msg_fifo}"
}


read_messages () {
  tail -f "${msg_fifo}" | sed 's/[\x01-\x1F\x7F]//g'
}

MAP_BREAK=42
map () {
  while read -r line; do
    "$@" "$line" || {
      if [ "$?" = $MAP_BREAK ]; then
          break
      fi
    }
  done
}

format_announce () {
  echo "**${*}*"
}

format_input () {
  echo "<${user}> ${1}"
}

send_user () {
  flock "$1" tee "$1/msg_queue" > /dev/null <<< "$2"
}

broadcast () {
  for target_user in "${tpath}"/*; do
    ! "${2:-true}" "${target_user}" || send_user "${target_user}" "$1"
  done
}

handle_input () {
  [ "$1" != 'exit' ] || return $MAP_BREAK
  broadcast "$(format_input "$1")"
}

user_create
read_messages &

broadcast "$(format_announce "$user" joined the chat)"
map handle_input
broadcast "$(format_announce "$user" left the chat)"
