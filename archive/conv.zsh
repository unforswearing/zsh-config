# technical writing options for pandoc
# using ~/pandoc/technical_writing.yaml
tw() {
  # $1 = input file, $2 = output file.pdf
  local twdefaults="/Users/unforswearing/pandoc/technical_writing.yaml"
  pandoc --defaults="$twdefaults" -i "${1}" -o "${2}"
}
# #######################################
