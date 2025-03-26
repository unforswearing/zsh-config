# shellcheck shell=bash
export GITHUB_API_TOKEN
GITHUB_API_TOKEN=$(grep '^.*$' "$HOME/.github.token") >|/dev/null 2>&1

path=(
  "$path"
  "/bin"
  "/sbin"
  "/usr/bin"
  "/opt/local"
  "/opt/local/bin"
  "/usr/sbin"
  "/usr/local"
  "/usr/local/bin"
  "/usr/local/opt"
  "/usr/local/share/zsh-completions"
  "/usr/share"
  "/usr/share/zsh"
  "/usr/local/lib/node_modules"
  "/Library/TeX/texbin"
  "/usr/local/go/bin"
  "/Applications/Sublime Text.app/Contents/SharedSupport/bin"
  "/Users/unforswearing/.cargo/bin"
  "/Users/unforswearing/.local/bin"
  "/Users/unforswearing/.zsh_bin"
  "/Users/unforswearing/.deno/bin"
  "/Users/unforswearing/.dotnet/bin"
  "/Users/unforswearing/.bun/bin"
  "/Users/unforswearing/.iterm2/bin"
  "/Users/unforswearing/.fzf/bin"
)

eval "$(luarocks path)"
