#!/usr/local/opt/ruby/bin/ruby --disable=gems
# hosts.rb: a rewrite of zsh-config/bin/python/hosts.py

require 'net/http'

steven_black = [
  "https://raw.githubusercontent.com/StevenBlack/hosts/",
  "master/alternates/fakenews-gambling/hosts"
]

uri = URI(steven_black.join(''))
response = Net::HTTP.get(uri)

File.write('/etc/hosts', response)
