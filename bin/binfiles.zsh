# shellcheck shell=bash
environ "stdlib"
## ---------------------------------------------
# create a standalone, top-level file for *almost* any zsh function
# -> functions that use the ${1:-$(cat -)} construction wont work
#
# for use with lua scripts via "luash". for example:
#
# ```lua
# require("luash")
# generate_binfile("incr")
# print(incr(5))
# ```
# generated files are added to "/Users/unforswearing/zsh-config/src/bin"
#
function delete_binfiles() {
  /bin/rm -r /Users/unforswearing/zsh-config/src/bin/*
  generate_binfile "generate_binfile"
  generate_binfile "delete_binfiles"
}
function generate_binfile() {
  unsetopt no_append_create
  unsetopt no_clobber
  local bindir="/Users/unforswearing/zsh-config/src/bin"
  # path+="$bindir"
  typeset PATH="${bindir}:$PATH"

  local functionname="${1}"
  local functionbody
  functionbody=$(declare -f "$functionname")

  local binfile="${bindir}/${functionname}"
  # shellcheck disable=2140
  local argitems=("\\"" "$" "@" "\\"")

  print "#!/usr/local/bin/zsh" >"$binfile"

  {
    print "source \"${stdlib}\""
    print "$functionbody"
    # shellcheck disable=2128
    print "$functionname \"$(print "$argitems" | sd " " "")\""
  } >>"$binfile"

  chmod +x "$binfile"
  setopt no_append_create
  setopt no_clobber
}
generate_binfile "generate_binfile"
generate_binfile "delete_binfiles"
