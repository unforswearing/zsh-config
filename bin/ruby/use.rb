#!/usr/local/opt/ruby/bin/ruby --disable=gems

# The `use` function from `.zshrc` ported for ruby scripts.
# Note: this script only searches for executable scripts that
# are in my $PATH.
#   - Since ruby scripts can't access my `.zshrc` environment,
#     there is no reason to try and check for loaded zsh functions.
#

def use?(program)
  ENV['PATH'].split(File::PATH_SEPARATOR).any? do |directory|
    File.executable?(File.join(directory, program.to_s))
  end
end
