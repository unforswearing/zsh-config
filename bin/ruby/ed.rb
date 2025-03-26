#!/usr/local/opt/ruby/bin/ruby --disable=gems

require 'json'

ED_FILE = File.expand_path('~/zsh-config/ed.json')

unless File.exist?(ED_FILE)
  puts "Ellipsis Directory file not found at #{ED_FILE}"
  exit 1
end

unmodified = ARGV[0]
ed = JSON.parse(File.read(ED_FILE))

if ARGV[1] == "expand"
  puts ed[ARGV[0]]
  return
end

if ARGV[0]
  current = ARGV[0].split('/')
else
  current = Dir.pwd.split('/')
end

if current.length < 3
  puts current.join('/')
  return
end

head = current[3..4]
chunk = current[5..-2]
tail = current[-2..]

if current[3..] && current[3..].length > 1
  composed = [ '~', head, '..', tail ].join('/')
  ed[composed] = unmodified

  File.write(ED_FILE, JSON.pretty_generate(ed))

  puts composed
else
  puts current.join('/')
end
