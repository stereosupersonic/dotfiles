#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-

$VERBOSE = false
puts "init irb"
puts "load #{__FILE__}"
def save_require(gem)
  require gem
rescue LoadError
  puts "ERROR: could not load: #{gem}"
end

# Break out of the Bundler jail
# from https://github.com/ConradIrwin/pry-debundle/blob/master/lib/pry-debundle.rb
if defined? Bundler
  Gem.post_reset_hooks.reject! { |hook| hook.source_location.first =~ %r{/bundler/} }
  Gem::Specification.reset
  #load 'rubygems/custom_require.rb'
end



# History
#siehe http://drnicwilliams.com/2006/10/12/my-irbrc-for-consoleirb/


save_require 'irb/ext/save-history'
# Activate auto-completion.
save_require 'irb/completion'
  # Setup permanent history.

 # begin
 #   histfile = File::expand_path(HISTFILE)
 #   if File::exists?(histfile)
 #     lines = IO::readlines(histfile).collect { |line| line.chomp }
 #     puts "Read #{lines.nitems} saved history commands from '#{histfile}'." if $VERBOSE
 #     Readline::HISTORY.push(*lines)
 #   else
 #     puts "History file '#{histfile}' was empty or non-existant." if $VERBOSE
 #   end
 #   Kernel::at_exit do
 #     lines = Readline::HISTORY.to_a.reverse.uniq.reverse
 #     lines = lines[-MAXHISTSIZE, MAXHISTSIZE] if lines.size > MAXHISTSIZE
 #     puts "Saving #{lines.length} history lines to '#{histfile}'." if $VERBOSE
 #     File::open(histfile, File::WRONLY|File::CREAT|File::TRUNC) { |io| io.puts lines.join("\n") }
 #   end
 # rescue => e
 #   puts "Error when configuring permanent history: #{e}" if $VERBOSE
 # end

# IRB Option
IRB.conf[:PROMPT_MODE] = :SIMPLE
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"
IRB.conf[:AUTO_INDENT] = true


#####################helpers

def y(obj)
  puts obj.to_yaml
end

def local_methods(obj = self)
  (obj.methods - (obj.class.superclass || obj.class).send(:instance_methods)).sort
end

class Object

  # list methods which aren't in superclass
  def local_methods(obj = self)
    (obj.methods - (obj.class.superclass || obj.class).send(:instance_methods)).sort
  end

end

def copy(str)
  str.to_clipboard
  puts "copied to the clipboard!"
end

def paste
  `pbpaste`
end

class String

  def to_file(file_name='output.txt')
    open(file_name, 'w') { |f| f << self.to_s}
  end

  def self.from_file(file_namee='output.txt')
    File.read(file_name)
  end

  def to_clipboard
     IO.popen('pbcopy', 'w') { |f| f << self.to_s }
  end

  def self.from_clipboard
    paste
  end
end

def c
  system('clear')
end

# Simple regular expression helper
# show_regexp - stolen from the pickaxe
def show_regexp(a, re)
  if a =~ re
    "#{$`}<<#{$&}>>#{$'}"
  else
    "no match"
  end
end

# Convenience method on Regexp so you can do
# /an/.show_match("banana") # => "b<>ana"
class Regexp
  def show_match(a)
    show_regexp(a, self)
  end
end

def ls(path='.')
  Dir[ File.join( path, '*' )].map{|filename| File.basename filename }
end
alias dir ls

# read file contents (also see ray for ruby source files ;) )
def cat(path)
  File.read path
end

# allows concise syntax like rq:mathn
def rq(lib)
  save_require lib.to_s
end

# load shortcut, not suited for non-rb
def ld(lib)
  load lib.to_s + '.rb'
end

# rerequire, not suited for non-rb, please note: can have non-intended side effects in rare cases
def rerequire(lib)
  $".dup.each{ |path|
    if path =~ %r</#{lib}\.rb$>
      $".delete path.to_s
      save_require path.to_s
    end
  }
  save_require lib.to_s
  true
end
alias rrq rerequire

# restart irb
def reset!
  # remember history...
  reset_irb = proc{ exec$0 }
  if defined?(Ripl) && Ripl.respond_to?(:started?) && Ripl.started?
    Ripl.shell.write_history if Ripl.shell.respond_to? :write_history
    reset_irb.call
  else
    at_exit(&reset_irb)
    exit
  end
end

save_require 'active_support' unless defined? Rails

save_require 'rubygems' unless defined? Gem

begin
  save_require 'hirb'
  Hirb.enable unless defined? Hirb
rescue => e
  puts e
end

begin
  save_require 'wirb'
  Wirb.start unless defined? Wirb
  require 'wirb/wp'

rescue => e
  puts e
end

if defined? Rails
  load File.join(File.dirname(__FILE__),".railsconsolerc")
end
