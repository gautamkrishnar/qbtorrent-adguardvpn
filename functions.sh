VAR_STORE="/adguard-config/vars.txt"

read_var() {
  VAR_NAME=$1

  if [[ ! -f $VAR_STORE ]]; then
    echo
    return 1
  fi

  VALUE=$(grep "^$VAR_NAME=" "$VAR_STORE" | cut -d '=' -f 2)
  if [[ -z $VALUE ]]; then
    echo
    return 1
  else
    echo $VALUE
    return 0
  fi
}

write_var() {
  VAR_NAME=$1
  NEW_VALUE=$2

  if [[ ! -f $VAR_STORE ]]; then
    touch "$VAR_STORE"
  fi

  if grep -q "^$VAR_NAME=" "$VAR_STORE"; then
    sed -i "s/^$VAR_NAME=.*/$VAR_NAME=$NEW_VALUE/" "$VAR_STORE"
  else
    echo "$VAR_NAME=$NEW_VALUE" >> "$VAR_STORE"
  fi
}

get_ip () {
  echo $(curl -s --connect-timeout 5 https://api.ipify.org/?format=text)
  return 0
}
