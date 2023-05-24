# the next line prevents sourcing this file
[[ "$ZSH_EVAL_CONTEXT" =~ :file$ ]] && return 0
integer rc_success=1
function reload() { source "$HOME/.zshrc"; }
# ----------------------------------------------------------
declare ZSH_PLUGIN_DIR="/Users/unforswearing/zsh-config/plugin"
source "${ZSH_PLUGIN_DIR}/zsh-defer/zsh-defer.plugin.zsh" &&
  function defer() { zsh-defer "$@"; }
source ~/powerlevel10k/powerlevel10k.zsh-theme && source ~/.p10k.zsh
zsh-defer source "${HOME}/zsh-config/bin/stdlib.zsh"
# load zsh plugins
() {
  unsetopt warncreateglobal
  local substring_search="zsh-history-substring-search"
  zsh-defer source "${ZSH_PLUGIN_DIR}/${substring_search}/${substring_search}.plugin.zsh"
  zsh-defer source "${ZSH_PLUGIN_DIR}/fzf-zsh/fzf-zsh-plugin.plugin.zsh"
  setopt warncreateglobal
}
# ----------------------------------------------------------
# backup .zshrc, .zshenv, .zshconfig to $HOME/zsh-config/bkp
({ 
  eval 'require "fd"
  /bin/rm -rf /Users/unforswearing/zsh-config/bkp
  cmd discard "mkdir /Users/unforswearing/zsh-config/bkp"
  fd ".z(profile|shenv|shrc)" --hidden --type file --max-depth 1 |
    # save a copy of each file and backup the  original
    while read line; do
      {
        # add line to prevent file from being sourced
        print "# the next line prevents sourcing this file"
        print "[[ \"\$ZSH_EVAL_CONTEXT\" =~ :file$ ]] && return 0"
        # print file contents
        cat "${HOME}/${line}"
      } >|"${HOME}/zsh-config/bkp/${line}"
    done' & 
  }) >/dev/null 2>&1 
 
# ----------------------------------------------------------
# PERIOD=90000; insect "$PERIOD seconds -> hours" == 25 h
function periodic() { "/usr/local/bin/python3" "$HOME/hosts.py"; }
# ----------------------------------------------------------
autoload compinit
autoload bashcompinit
# keep the syntax highlighting at the bottom, see faq
# https://github.com/zsh-users/zsh-syntax-highlighting#faq
# brew install zsh-syntax-highlighting
source "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
rc_success=0