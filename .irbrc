# encoding: UTF-8

require 'pathname'

begin
  require 'wirble'

  Wirble.init
rescue LoadError => err
  warn "Couldn’t load Wirble: #{err}"
end

IRB.conf[:PROMPT_MODE] = :SIMPLE
IRB.conf[:SAVE_HISTORY] = 1000

require 'rdoc/ri/driver'

# simulate `ri -a` when using IRB’s help() method
class RDoc::RI::Driver
  old_default_options = method(:default_options)

  define_singleton_method(:default_options) do
    options = old_default_options.call()
    options[:show_all] = true
    options
  end
end

def po(obj)
  (obj.methods - Object.methods).sort
end

require 'json'
require 'time'
