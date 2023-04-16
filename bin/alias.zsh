# use short directory names
# eg ~zbin instead of cd "$HOME/zsh-config/bin"
hash -d zbin="$HOME/zsh-config/bin"
hash -d zconf="$HOME/zsh-config"
hash -d zetc="$HOME/zsh-config/etc"
hash -d zlib="$HOME/zsh-config/lib"
hash -d zplug="$HOME/zsh-config/plugin"
hash -d cloud="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
hash -d documents="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents"
hash -d github="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/__Github"
hash -d writing="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Freelance Writing/freelance_writing_obsidian"
## ---------------------------------------------
# suffix aliases
alias -s git='git clone'
## ---------------------------------------------
# -g == global alias. global as in expands anywhere on the current line
# --------------------
alias -g @u='ssh 192.168.0.187'
alias -g @b='ssh 192.168.0.151'
alias -g @m='ssh 192.168.0.150'
## ---------------------------------------------
# reload all terminals. use with `trap "exec zsh" USR1` in .zshrc
alias reload.all='pkill -usr1 zsh'
alias reload='exec zsh'
alias purj='sudo purge && sudo purge && sudo purge'
alias memory='nu -c "{free: (sys|get mem|get free), total: (sys|get mem|get total)}"'
alias pip='pip3'
# editor stuff ===========
alias edit='micro' #'nvim'
alias subl="/Applications/Sublime\ Text.app/Contents/MacOS/sublime_text"
# navigation ===============
alias prev="cd -"
# alias prev="cd $(db get previous_dir)"
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
alias namesingle='vidir'
## ---------------------------------------------
alias sed='/usr/local/bin/gsed'
alias julia='/Applications/Julia-1.8.app/Contents/Resources/julia/bin/julia'
## ---------------------------------------------
alias togglewifi='networksetup -setairportpower en1 off && sleep 3 && networksetup -setairportpower en1 on'
## ---------------------------------------------
alias poyml='python "/Users/unforswearing/Library/Mobile Documents/com~apple~CloudDocs/Documents/__Github/poyml/poyml.py"'
