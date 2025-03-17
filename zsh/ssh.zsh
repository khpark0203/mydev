zstyle ':completion:*:*:ssh:*' hosts off
zstyle ':completion:*:*:ssh:*' users off

_custom_ssh_hosts() {
    local -a hosts_array matches
    local cur

    # 현재 입력 중인 문자열 가져오기
    cur=${words[CURRENT]}

    # ~/.ssh/config에서 Host 항목 가져오기
    hosts_array+=($(awk '/^Host / {for (i=2; i<=NF; i++) print $i}' ~/.ssh/config))

    # /etc/hosts에서 유효한 호스트 가져오기
    hosts_array+=($(awk '{if ($1 !~ /^#/ && NF > 1) print $2}' /etc/hosts))

    # 기본적으로 포함하고 싶은 항목 추가
    hosts_array+=(localhost 127.0.0.1)

    # 중복 제거
    hosts_array=("${(@u)hosts_array}")

    # 현재 입력한 단어(cur)로 필터링
    matches=(${(M)hosts_array:#$cur*})

    # 자동 완성 목록 적용 (필터링된 목록만 추가)
    compadd -U -- $matches
}

# ssh 명령어에서 자동 완성 활성화
compdef _custom_ssh_hosts ssh scp
