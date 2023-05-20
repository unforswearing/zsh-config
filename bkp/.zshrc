# the next line prevents sourcing this file
[[ "$ZSH_EVAL_CONTEXT" =~ :file$ ]] && return 0
source ~/powerlevel10k/powerlevel10k.zsh-theme && source ~/.p10k.zsh
source "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "${HOME}/.zshenv"
source "${HOME}/.zshconfig"
source "${HOME}/zsh-config/bin/stdlib.zsh"
# reload the environment
function reload() { source "$HOME/.zshrc"; }
# load zsh plugins
ZSH_PLUGIN_DIR="/Users/unforswearing/zsh-config/plugin"
source "${ZSH_PLUGIN_DIR}/zsh-defer/zsh-defer.plugin.zsh"
# brew install zsh-syntax-highlighting
source "${ZSH_PLUGIN_DIR}/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh"
source "${ZSH_PLUGIN_DIR}/fzf-zsh/fzf-zsh-plugin.plugin.zsh" | cmd devnull
# ----------------------------------------------------------
# backup .zshrc, .zshenv, .zshconfig to $HOME/zsh-config/bkp
# use async to speed up the reload process
import async && async '{ 
  require "fd"
  /bin/rm -rf /Users/unforswearing/zsh-config/bkp
  cmd discard "mkdir /Users/unforswearing/zsh-config/bkp"
  fd ".zsh(config|env|rc)" --hidden --type file --max-depth 1 |
    # save a copy of each file and backup the  original
    while read line; do
      {
        # add line to prevent file from being sourced
        print "# the next line prevents sourcing this file"
        print "[[ \"\$ZSH_EVAL_CONTEXT\" =~ :file$ ]] && return 0"
        # print file contents
        cat "${HOME}/${line}"
      } >|"${HOME}/zsh-config/bkp/${line}"
    done
}' && unload async
# ----------------------------------------------------------
periodic() { "/usr/local/bin/python3" "$HOME/hosts.py"; }
autoload compinit
autoload bashcompinit
# : success=true is a no-op for metadata purposes
: success=true
