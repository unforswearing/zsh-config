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

# def print_functions()
#   if $config['functions'] && !$config['functions'].empty?
#     puts "# Functions"
#     $config['functions'].each do |name, body|
#       puts "function #{name}() {"
#       if body.is_a?(Array)
#         # Handle array of lines
#         body.each do |line|
#           puts "  #{line}"
#         end
#       else
#         body.each_line do |line|
#           puts "  #{line.chomp}"
#         end
#       end
#       puts "}"
#       puts
#     end
#   end
# end

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
    # add_item(key, array)
    keyname = ARGV[1]
    ARGV.shift(2)
    add_item(keyname, ARGV)
  # in shell: `loadf.list`
  when "list-all-functions"
    $config['functions'].each do |name, body|
      puts name
    end
end
