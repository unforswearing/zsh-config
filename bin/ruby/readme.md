# Notes about using Ruby in the shell

```cmd
ruby -v
ruby 3.3.5 (2024-09-03 revision ef084cc8f4) [x86_64-darwin23]
```

## Best Practices

- Disable gems by default in the script shebang
  - `#!/usr/bin/env ruby --disable=gems`
  - or using `ruby` via `brew`
    - `#!/usr/local/opt/ruby/bin/ruby --disable=gems`
  - or maybe this will help ruby scripts use the currently enabled zsh env and tools
    - `#!/usr/bin/env -S /usr/local/opt/ruby/bin/ruby --disable=gems`
- `.zshrc` contains a function called `rb` that uses the full path and `--disable=gems` option to run the above in functions / interactively.
- Oneliners can use `ARGV` like so:
  - `ruby --disable=gems -e "puts 'hello ${ARGV[0]}'" "world"` -> "hello world"

## Links / Resources

### Bookmarks (Public)

- https://raindrop.io/unforswearing/ruby-docs-53281973


### General Ruby

Overview

- https://learnxinyminutes.com/ruby/

File / Dir Processing

- [Dir](https://ruby-doc.org/3.3.5/Dir.html)
- [File](https://ruby-doc.org/3.3.5/File.html)
- [FileUtils](https://ruby-doc.org/3.3.5/stdlibs/fileutils/FileUtils.html)

General Shell Scripting

- https://stackoverflow.com/questions/166347/how-do-i-use-ruby-for-shell-scripting
- https://lucasoshiro.github.io/posts-en/2024-06-17-ruby-shellscript/
- https://www.devdungeon.com/content/enhanced-shell-scripting-ruby

HTTP Requests

- https://www.twilio.com/en-us/blog/5-ways-make-http-requests-ruby#The-standard-netHTTP

## To Do

- Make a script that will incrementally build a shell command of medium complexity.
  - See `runShellcheck` in `functions.rb` for an example of how this could work.
