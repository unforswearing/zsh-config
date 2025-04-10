#!/usr/bin/env -S /usr/local/opt/ruby/bin/ruby --disable=gems

# Start using Ruby by managing `functions.json`.
# Commands `loadf` and `f` are set in `.zshrc`.
#
# In the shell:
#
#   `loadf <name>`
#     - load a function
#
#   `f list-all-functions`
#     - print a list of function names
#
#   `f add <name> <cmd [cmd]...>`
#     - add a function manually
#
#   `f serialize-function <functionbody>`
#     - serialize and add a function
#
#   `f serialize-and-add <functionbody>`
#     - serialize and add a function
#
# Other options TBD
#

require 'json'
require 'fileutils'
require_relative 'colors'
require_relative 'use'

CONFIG_FILE = File.expand_path('~/zsh-config/functions.json')

unless File.exist?(CONFIG_FILE)
  puts "Config file not found at #{CONFIG_FILE}"
  exit 1
end

# dollar sign == global
$config = JSON.parse(File.read(CONFIG_FILE))

# f get loadf > tmp.f && \
#   shellcheck --exclude=2148 --format=diff tmp.f | patch -p1 tmp.f
#
# loadf.test is made obsolete by `f verify-function`
# function loadf.test() {
#   local name="${1}"
#   /usr/local/bin/shellcheck \
#     --severity=warning \
#     --exclude=2148 \
#     --format=json <(f get "$name") | \
#         jq '.[].message'
# }
#
# Verify a stored functions.json item with shellcheck
#
def runShellcheck(filename)
  retrieved_function = get_function(filename)
  unless defined?(filename) && defined?(retrieved_function)
    puts "No function body passed to 'runShellcheck'".red
    exit 1
  end

  tmp_file = "/tmp/functions.rb.verify.#{filename}"

  File.write(tmp_file, retrieved_function)

  cmdroot = "/usr/local/bin/shellcheck"
  options = [
    "--severity=warning",
    "--exclude=2148",
    "--format=json"
  ]
  pipe = [ "|", "jq '.[]'" ]

  composed = proc { |generated_cmd|
    generated_cmd = [cmdroot].append(options)
    generated_cmd = generated_cmd.append(tmp_file)
    generated_cmd = generated_cmd.append(pipe)
    generated_cmd.flatten.join(" ")
  }

  cmd_result = `#{composed.call()}`

  if cmd_result.length == 0
    puts "No errors were found in function '#{filename}'.".green
  else
    result_json = JSON.parse(cmd_result)
    puts JSON.pretty_generate(result_json)
  end

  File.delete(tmp_file)
end

# Serialize_function relies on a function_body that
# does not contain the `function` keyword. Eg:
#
#   fnname() {
#     cmd...
#     cmd...
#   }
#
# Use the output of `whence` or `which` to avoid
# the `function` keyword when serializing.
#
#   `whence -f fnname`
#   `which fnname`
#
# Use: `f serialize-function "$(whence -f fnname)"`
# Future options:
# 1. choose to view serialized function json
# 2. choose to add serialized function to functions.json file
def serialize_function(function_body, add=false)
  unless defined?(function_body)
    puts "Please include function body.".red
    puts "eg. `serialize-function \"\$(whence -f fname)\"`.".italic
    exit 1
  end

  split_body = function_body.lines.map do |line|
    line.strip
  end

  name_unparsed = split_body[0].split()[0]

  name = name_unparsed.gsub("()", "")
  body = split_body[1..-2]

  puts "Serialized function '#{name}'.".green
  puts JSON.pretty_generate({ name => body })

  add ? add_item(name, body) : exit
end

# when this file is used in another ruby script via
# `require_relative "functions"`, use `get_function`
# to load a function that can be used in shell commands
# executed by ruby. for example:
#
# ```ruby
# # function timestamp() {\n date +'%Y-%m-%d %H:%M:%S'\n}
#
# require_relative "functions"
#
# func = get_function "timestamp"
# system("#{func}; timestamp")
# ```
#
def get_function(key)
  if $config['functions'][key]
    function_parts = []
    function_parts.append("function #{key}() {")
    $config['functions'][key].each do |line|
      function_parts.append(" #{line}")
    end
    function_parts.append("}")
    function_composed = function_parts.join("\n")
    return function_composed
  else
    puts "Function '#{key}' doesn\'t exist.".red
    exit 1
  end
end

def save_config()
  File.write(CONFIG_FILE, JSON.pretty_generate($config))
  puts "Saved 'functions.json'.".green
end

# add_item(key->string, value->array)-> void
# If `key` exists in $config['functions'], it will be overwritten
def add_item(key, value)
  $config['functions'] ||= {}
  $config['functions'][key] = value.is_a?(Array) ? value : [value]

  puts "Added #{key || value} to 'functions.json'.".green
  save_config()
end

def remove_item(key)
  $config['functions'].delete(key)

  puts "Removed #{key} from 'functions.json'.".green
  save_config($config)
end

case ARGV[0]
  # in shell: `loadf <name>`
  when "get"
    puts get_function(ARGV[1])
  when "add"
    # f add <name> <command, [command...]>
    # add_item(key, array)
    keyname = ARGV[1]
    ARGV.shift(2)
    add_item(keyname, ARGV)
  # in shell: `f serialize <function>`
  when "serialize-function"
    serialize_function(ARGV[1])
  when "serialize-and-add"
    serialize_function(ARGV[1], true)
  when "verify-function"
    keyname = ARGV[1]
    runShellcheck(keyname)
  # in shell: `f list-all-functions`
  when "list-all-functions"
    $config['functions'].sort.each do |name, body|
      puts name
    end
end
