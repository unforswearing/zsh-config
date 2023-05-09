# add stuff  from insect - add, subtract, and convert from and to
# seconds, minutes, hours, days; inches, feet, miles
# grams, miligrams, kilograms; milimeters, centimenters, meters, kilometers
# eg. 50 minutes in seconds, 10 miles in meters, 4 days + 33 hours
rgb~hex() {
  unsetopt warncreateglobal
  for var in "$@"; do
    printf '%x' "$var"
  done
  printf '\n'
}
hex~rgb() {
  unsetopt warncreateglobal
  hex="$@"
  printf "%d %d %d\n" 0x${hex:0:2} 0x${hex:2:2} 0x${hex:4:2}
}
# #######################################
html~md() { pandoc -f html -t markdown "${1}"; }
md~html() { pandoc -f markdown -t html "${1}"; }
md~jupyter() { pandoc -f markdown -t ipynb "${1}"; }
# #######################################
mp4~wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp4 <output_file>.wav"
  else
    ffmpeg -i "$1" "$2"
  fi
}
mp4~mp3() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42mp3 <input_file>.mp4 <output_file>.mp3"
  else
    ffmpeg -i "$1" -vn -acodec mp3 -ab 320k -ar 44100 -ac 2 "$2"
  fi
}
wav~mp3() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: wav2mp3 <input_file>.wav <output_file>.mp3"
  else
    echo "converting $1 to $2"
    sox "$1" -C 256 -r 44.1k "$2"
  fi
}
mp3~wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp3 <output_file>.wav"
  else
    sox "$1" "$2"
  fi
}
m4a~wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp3 <output_file>.wav"
  else
    ffmpeg -i "$1" -f sox - | sox -p "$2"
  fi
}
###
