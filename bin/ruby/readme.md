# Notes about using Ruby in the shell

## Best Practices

- Disable gems by default in the script shebang
  - `#!/usr/bin/env ruby --disable=gems`
  - or using `ruby` via `brew`
    - `#!/usr/local/opt/ruby/bin/ruby --disable=gems`

## Links / Resources

General Ruby

- https://learnxinyminutes.com/ruby/

File / Dir Processing

- [Dir](https://ruby-doc.org/3.4.1/Dir.html)
- [File](https://ruby-doc.org/3.4.1/File.html)
- [FileUtils](https://ruby-doc.org/3.4.1/stdlibs/fileutils/FileUtils.html)

General Shell Scripting

- https://stackoverflow.com/questions/166347/how-do-i-use-ruby-for-shell-scripting
- https://lucasoshiro.github.io/posts-en/2024-06-17-ruby-shellscript/
- https://www.devdungeon.com/content/enhanced-shell-scripting-ruby

HTTP Requests

- https://www.twilio.com/en-us/blog/5-ways-make-http-requests-ruby#The-standard-netHTTP
