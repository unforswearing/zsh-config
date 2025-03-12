#!/usr/local/opt/ruby/bin/ruby --disable=gems

# Start using Ruby by managing `functions.json`.
# Commands `loadf` and `f` are set in `.zshrc`.
#
# In the shell:
#   - `loadf <name>` to load a function
#   - `f list-all-functions` to print a list of function names
#   - `f add <name> <cmd [cmd]...>` to add a function manually
#   - `f serialize <functionbody>` to serialize and add a function
#
# Other options TBD

require 'json'
require 'fileutils'

CONFIG_FILE = File.expand_path('~/zsh-config/functions.json')

unless File.exist?(CONFIG_FILE)
  puts "Config file not found at #{CONFIG_FILE}"
  exit 1
end

$config = JSON.parse(File.read(CONFIG_FILE))

# External Command(s)
module ExternalCmd
  # Verify a stored functions.json item with shellcheck
  def ExternalCmd.runShellcheck(filename)
    retrieved_function = get_function(filename)
    tmp_file = "/tmp/functions.rb.verify.#{filename}"
    File.write(tmp_file, retrieved_function)

    cmdroot = "/usr/local/bin/shellcheck"
    options = [
      "--severity=warning",
      "--exclude=2148",
      "--format=json"
    ]
    pipe = [
      "|",
      "jq '.[]'"
    ]

    composed = proc { |generated_cmd|
      generated_cmd = [cmdroot].append(options)
      generated_cmd = generated_cmd.append(tmp_file)
      generated_cmd = generated_cmd.append(pipe)
      generated_cmd.flatten.join(" ")
    }

    result_json = JSON.parse(`#{composed.call()}`)
    puts JSON.pretty_generate(result_json)
  end
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
    function_parts = []
    function_parts.append("function #{key}() {")
    $config['functions'][key].each do |line|
      function_parts.append(" #{line}")
    end
    function_parts.append("}")
    return function_parts.join("\n")
  else
    puts "Function #{key} doesn't exist."
    return false
  end
end

def validate_function(key)
  if get_function(key)

  end
end

def save_config()
  File.write(CONFIG_FILE, JSON.pretty_generate($config))
  puts "Saved functions.json"
end

# add_item(key->string", value->array)-> void
# If `key` exists in $config['functions'], it will be overwritten
def add_item(key, value)
  $config['functions'] ||= {}
  $config['functions'][key] = value.is_a?(Array) ? value : [value]

  puts "Added #{key || value} to functions.json."
  save_config()
end

def remove_item(key)
  $config['functions'].delete(key)

  puts "Removed #{key} from functions.json."
  save_config($config)
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
  when "verify-function"
    keyname = ARGV[1]
    ExternalCmd.runShellcheck(keyname)
  # in shell: `f list-all-functions`
  when "list-all-functions"
    $config['functions'].sort.each do |name, body|
      puts name
    end
end
