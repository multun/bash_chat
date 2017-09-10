set -e

tpath="${1:?missing target scope}"
mkdir -p "${tpath}"

read nickname

egrep "^[a-zA-Z_-]+$" <<< "$nickname" || exit 1
fifo_name="${tpath}/${nickname}"

fifo_close () {
    rm "${fifo_name}"
}

mkfifo "${fifo_name}"
trap fifo_close EXIT 

(while :; do
     if read -r line < "$fifo_name"; then
	 echo "$line" | sed 's/[\x01-\x1F\x7F]//g'
     fi
 done) &

read -r input
while [[ "$input" != exit ]]; do
    tee -- "${tpath}"/* > /dev/null <<< "<${nickname}> ${input}" 
    read -r input
done

wait
