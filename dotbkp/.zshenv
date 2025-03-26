#!/usr/local/bin/zsh

export GITHUB_API_TOKEN=$(grep '^.*$' "$HOME/.github.token") >|/dev/null 2>&1

path=(
  $path
  "/bin"
  "/sbin"
  "/usr/bin"
  "/usr/opt"
  "/usr/opt/local/bin"
  "/usr/opt/local/sbin"
  "/usr/sbin"
  "/usr/local"
  "/usr/local/bin"
  "/usr/local/opt"
  "/usr/local/opt/fzf/bin"
  "/usr/local/share/zsh-completions"
  "/usr/share"
  "/usr/share/zsh"
  "/usr/local/lib/node_modules"
  "/Library/TeX/texbin"
  "/usr/local/go/bin"
  "/Applications/Sublime Text.app/Contents/SharedSupport/bin"
  "/Users/unforswearing/bin"
  "/Users/unforswearing/go/bin"
  # "/Users/unforswearing/zsh-config/bin"
  "/Users/unforswearing/.cargo/bin"
  "/Users/unforswearing/.local/bin"
  "/Users/unforswearing/.deno/bin"
  "/Users/unforswearing/.dotnet/bin"
  "/Users/unforswearing/.bun/bin"
  "/Users/unforswearing/.iterm2/bin"
  "/Users/unforswearing/.fzf/bin"
)

eval $(luarocks path)
