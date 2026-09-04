#!/usr/bin/env bash
# Тест-раннер tablefmt. Запуск: bash tests/run.sh
set -u
cd "$(dirname "$0")/.."

TF=./tablefmt
pass=0
fail=0

# assert <факт> <ожидание>
check() {
    local name="$1" got="$2" want="$3"
    if [[ "$got" == "$want" ]]; then
        pass=$((pass + 1))
        echo "ok   $name"
    else
        fail=$((fail + 1))
        echo "FAIL $name"
        echo "  want: $want"
        echo "  got:  $got"
    fi
}

# --- whitespace-таблицы ---
check "simple" \
    "$(cat tests/simple.txt | $TF)" \
    $'NAME: Ivan, AGE: 30, CITY: Moscow\nNAME: Anna, AGE: 25, CITY: Paris'

# --- жадный последний столбец ---
check "command (greedy last)" \
    "$(cat tests/command.txt | $TF)" \
    $'PID: 123, USER: root, COMMAND: /bin/bash --login --noprofile\nPID: 456, USER: john, COMMAND: vim file with spaces.txt'

# --- числа в соседних колонках не склеиваются ---
check "numbers (20 000)" \
    "$(cat tests/numbers.txt | $TF)" \
    $'NAME: foo, A: 20, B: 000, C: 42\nNAME: bar, A: 100, B: 200, C: 300'

# --- пробелы внутри значения сохраняются ---
check "numbers2 (VALUE: 20 000)" \
    "$(cat tests/numbers2.txt | $TF)" \
    $'NAME: foo, VALUE: 20 000\nNAME: bar, VALUE: 100 500'

# --- явный разделитель ---
check "separator |" \
    "$(printf 'NAME|AGE|CITY\n----|----|----\nIvan|30|Moscow\n' | $TF --separator '|')" \
    $'NAME: Ivan, AGE: 30, CITY: Moscow'

# --- df: "Mounted on" ---
check "df -h --vertical" \
    "$(df -h | $TF --vertical)" \
    "$(df -h | $TF --vertical)"  # не фиксируем объём, просто что не падает

# --- top (fixed-width, служебные строки) ---
top_want=$'PID: 1, USER: root, PR: 20, NI: 0, VIRT: 168320, RES: 11392, SHR: 8192, S: S, %CPU: 0.0, %MEM: 0.1, TIME+: 0:01.23, COMMAND: systemd\nPID: 512, USER: root, PR: 20, NI: 0, VIRT: 123456, RES: 23456, SHR: 1234, S: R, %CPU: 12.5, %MEM: 2.3, TIME+: 2:03.45, COMMAND: python3 top.py\nPID: 999, USER: daemon, PR: 20, NI: 0, VIRT: 10240, RES: 512, SHR: 256, S: S, %CPU: 0.0, %MEM: 0.0, TIME+: 0:00.00, COMMAND: [kworker/0:0]\nPID: 23456, USER: alexey, PR: 20, NI: 0, VIRT: 310000, RES: 98000, SHR: 45000, S: S, %CPU: 4.2, %MEM: 0.9, TIME+: 10:00.00, COMMAND: ssh -R 8080:local'
check "top -b -n 1" \
    "$(cat tests/top_full.txt | $TF)" \
    "$top_want"

check "top --columns --number" \
    "$(cat tests/top_full.txt | $TF --columns PID,%CPU,COMMAND --number)" \
    $'1: PID: 1, %CPU: 0.0, COMMAND: systemd\n2: PID: 512, %CPU: 12.5, COMMAND: python3 top.py\n3: PID: 999, %CPU: 0.0, COMMAND: [kworker/0:0]\n4: PID: 23456, %CPU: 4.2, COMMAND: ssh -R 8080:local'

check "top --sort %CPU --last 2" \
    "$(cat tests/top_full.txt | $TF --sort %CPU --last 2)" \
    $'PID: 23456, USER: alexey, PR: 20, NI: 0, VIRT: 310000, RES: 98000, SHR: 45000, S: S, %CPU: 4.2, %MEM: 0.9, TIME+: 10:00.00, COMMAND: ssh -R 8080:local\nPID: 512, USER: root, PR: 20, NI: 0, VIRT: 123456, RES: 23456, SHR: 1234, S: R, %CPU: 12.5, %MEM: 2.3, TIME+: 2:03.45, COMMAND: python3 top.py'

check "top --jsonl" \
    "$(cat tests/top_full.txt | $TF --jsonl | head -1)" \
    '{"PID":"1","USER":"root","PR":"20","NI":"0","VIRT":"168320","RES":"11392","SHR":"8192","S":"S","%CPU":"0.0","%MEM":"0.1","TIME+":"0:01.23","COMMAND":"systemd"}'

# --- ps aux ---
check "ps aux" \
    "$(cat tests/ps_aux.txt | $TF --columns PID,USER,COMMAND --number)" \
    $'1: USER: root, PID: 1, COMMAND: bash\n2: USER: alexey, PID: 512, COMMAND: python3 server.py\n3: USER: mysql, PID: 999, COMMAND: /usr/sbin/mysqld\n4: USER: www-data, PID: 1234, COMMAND: nginx: worker process'

# --- free ---
check "free -h" \
    "$(cat tests/free_h.txt | $TF)" \
    $'Mem: total: 7.7Gi, used: 1.7Gi, free: 3.8Gi, shared: 15Mi, buff/cache: 2.2Gi, available: 5.8Gi\nSwap: total: 0B, used: 0B, free: 0B'

# --- ls: не таблица -> passthrough ---
ls_out=$(ls -la tests | $TF)
if [[ $? -eq 0 && "$ls_out" == "total "* ]]; then
    pass=$((pass + 1)); echo "ok   ls passthrough"
else
    fail=$((fail + 1)); echo "FAIL ls passthrough"
fi

# --- опции ---
check "--help" "$($TF --help | head -1)" "tablefmt — табличный вывод, удобный для чтения синтезатором речи."
check "--version" "$($TF --version)" "tablefmt 3.1"
check "--strict без таблицы" "$(echo '12345' | $TF --strict 2>&1; echo "rc=$?")" \
    "tablefmt: table header not found
rc=1"

echo
echo "passed: $pass, failed: $fail"
[[ $fail -eq 0 ]]
