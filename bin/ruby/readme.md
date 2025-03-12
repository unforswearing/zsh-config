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
