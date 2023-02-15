# use short directory names
# eg ~zbin instead of cd "$HOME/zsh-config/bin"
hash -d zbin="$HOME/zsh-config/bin"
hash -d zconf="$HOME/zsh-config"
hash -d zetc="$HOME/zsh-config/etc"
hash -d zlib="$HOME/zsh-config/lib"
hash -d zplug="$HOME/zsh-config/plugin"
hash -d cloud="/Users/unforswearing/Library/Mobile Documents/com~apple~CloudDocs"
################
# suffix aliases
alias -s git='git clone'
######################
# -g == global alias. global as in expands anywhere on the current line
# --------------------
alias -g @u='ssh 192.168.0.187'
alias -g @b='ssh 192.168.0.151'
alias -g @m='ssh 192.168.0.150'
######################
alias reload='exec zsh'
# reload all terminals. use with `trap "exec zsh" USR1` in .zshrc
alias {reload.all,rall}='pkill -usr1 zsh'
alias purj='sudo purge && sudo purge && sudo purge'
alias memory='nu -c "{free: (sys|get mem|get free), total: (sys|get mem|get total)}"'
alias pip='pip3'
# editor stuff ===========
alias edit='hx' #'nvim'
alias subl="/Applications/Sublime\ Text.app/Contents/MacOS/sublime_text"
# navigation ===============
alias prev="cd -"
# clipboard ===============
alias c="pbcopy"
alias p="pbpaste"
alias cf='pbpaste|pbcopy'
# file / dir stuff ===============
alias rm='rm -i'
alias cp='cp -i'
alias rmf='sudo rm -rf'
alias plux='chmod +x'
alias shuf='gshuf'
alias ll='exa $EXA_DEFAULT_OPTIONS'
alias namesingle='vidir'
##########################################################################
alias sed='/usr/local/bin/gsed'
##########################################################################
alias now="$(command -v gdate) \"+%Y-%m-%dT%H:%M\""
################
alias togglewifi='networksetup -setairportpower en1 off && sleep 3 && networksetup -setairportpower en1 on'
# ls | each; do echo "$line"; done
######################
