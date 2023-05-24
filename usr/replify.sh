# shellcheck shell=bash
environ "stdlib"
replify() {
  command="${*}"
  printf "Initialized REPL for [%s]
  " "$command"
  printf "%s> " "$command"
  read -r input
  while [ "$input" != "" ];
  do
      	eval "$command $input"
  	printf "
  %s> " "$command"
      	read -r input
  done
}
