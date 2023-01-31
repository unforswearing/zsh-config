# use short directory names
# eg ~zbin instead of cd "$HOME/zsh-config/bin"
hash -d zbin="$HOME/zsh-config/bin"
hash -d zconf="$HOME/zsh-config"
hash -d zetc="$HOME/zsh-config/etc"
hash -d zlib="$HOME/zsh-config/lib"
hash -d zplug="$HOME/zsh-config/plugin"
hash -d documents="$HOME/Documents"
hash -d cloud="/Users/unforswearing/Library/Mobile Documents/com~apple~CloudDocs"
hash -d notes="$HOME/Documents/Notes"
hash -d config="$HOME/.config"
hash -d github="$HOME/Documents/__Github"
hash -d scripts="$HOME/Documents/Scripts"
################
# suffix aliases
alias -s html='open'
alias -s git='git clone'
alias -s {txt,md,bash,zsh,sh}='micro'
alias -s {js,ts,lua,py}='code'
######################
# -g == global alias. global as in expands anywhere on the current line
# --------------------
alias -g @u='ssh 192.168.0.187'
alias -g @b='ssh 192.168.0.151'
alias -g @m='ssh 192.168.0.150'
######################
alias reload='exec zsh'
alias cfg='/opt/local/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME"'
# reload all terminals. use with `trap "exec zsh" USR1` in .zshrc
alias {reload.all,rall}='pkill -usr1 zsh'
alias purj='sudo purge && sudo purge && sudo purge'
alias memory='nu -c "{free: (sys|get mem|get free), total: (sys|get mem|get total)}"'
# editor stuff ===========
alias edit='hx' #'nvim'
alias subl="/Applications/Sublime\ Text.app/Contents/MacOS/sublime_text"
# navigation ===============
alias prev="cd -"
alias breev="cd /"
# alias up="cd .."
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
alias head='head -n'
alias tail='tail -n'
alias ch='tldr'
alias ll='exa $EXA_DEFAULT_OPTIONS'
alias rcat='rich --syntax -n'
alias namesingle='vidir'
alias cloud="/Users/unforswearing/Library/Mobile Documents/com~apple~CloudDocs"
##########################################################################
alias sed='/usr/local/bin/gsed'
##########################################################################
alias witchcraft='$HOME/.config/witchcraft'
alias rmd='bash $HOME/Documents/__Github/rmd-cli/rmd.bash'
alias now="$(command -v gdate) \"+%Y-%m-%dT%H:%M\""
################
alias togglewifi='networksetup -setairportpower en1 off && sleep 3 && networksetup -setairportpower en1 on'
# ls | each; do echo "$line"; done
######################
