#!/usr/local/opt/ruby/bin/ruby --disable=gems

# Start using Ruby by managing `functions.json`
# In the shell, use `loadf <name>` to load a function
#               use `loadf.list` to print a list of function names
# Other options TBD

require 'json'
require 'fileutils'

CONFIG_FILE = File.expand_path('~/zsh-config/functions.json')

unless File.exist?(CONFIG_FILE)
  puts "Config file not found at #{CONFIG_FILE}"
  exit 1
end

$config = JSON.parse(File.read(CONFIG_FILE))

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
def serialize_function(function_body)
  if function_body
    split_body = function_body.lines.map { |line|
      line.strip
    }

    name_unparsed = split_body[0].split()[0]
    name = name_unparsed.gsub("()", "")
    body = split_body[1..-2]

    puts "Serialized function #{name}"

    add_item(name, body)
  else
    puts "Please include function body"
    puts "eg. `serialize-function \"\$(whence -f fname)\"`"
  end
end

def get_function(key)
  if $config['functions'][key]
    puts "function #{key}() {"
    $config['functions'][key].each do |line|
      puts " #{line}"
    end
    puts "}"
  else
    puts "Function #{key} doesn't exist."
  end
end

def save_config()
  File.write(CONFIG_FILE, JSON.pretty_generate($config))
  puts "Saved functions.json"
end

# add_item(key->string", value->array)-> void
def add_item(key, value)
  $config['functions'] ||= {}
  $config['functions'][key] = value.is_a?(Array) ? value : [value]

  save_config()
  puts "Added #{key || value} to functions.json."
end

def remove_item(key)
  $config['functions'].delete(key)

  save_config($config)
  puts "Removed #{key} from functions.json."
end

case ARGV[0]
  # in shell: `loadf <name>`
  when "get"
    get_function(ARGV[1])
  when "add"
    # f add <name> <command, [command...]>
    # add_item(key, array)
    keyname = ARGV[1]
    ARGV.shift(2)
    add_item(keyname, ARGV)
  # in shell: `f serialize <function>`
  when "serialize-function"
    functionbody = ARGV[1]
    serialize_function(functionbody)
  # in shell: `f list-all-functions`
  when "list-all-functions"
    $config['functions'].each do |name, body|
      puts name
    end
end
