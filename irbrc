#!/usr/bin/ruby
$VERBOSE = false
puts "init irb"
puts "load #{__FILE__}"
def save_require(gem)
  require gem  
rescue LoadError
  puts "ERROR: could not load: #{gem}"
end
%w{ rubygems pp yaml what_methods hpricot wirble hirb}.each { |lib| save_require lib }
save_require 'looksee/shortcuts' #gem install looksee 

#s

# History
#siehe http://drnicwilliams.com/2006/10/12/my-irbrc-for-consoleirb/
unless defined? ETC_IRBRC_LOADED
save_require 'irb/ext/save-history'
  # Require RubyGems by default.


  # Activate auto-completion.
  save_require 'irb/completion'



  # Setup permanent history.
  HISTFILE = "~/.irb-save-history"
  MAXHISTSIZE = 1000
  begin
    histfile = File::expand_path(HISTFILE)
    if File::exists?(histfile)
      lines = IO::readlines(histfile).collect { |line| line.chomp }
      puts "Read #{lines.nitems} saved history commands from '#{histfile}'." if $VERBOSE
      Readline::HISTORY.push(*lines)
    else
      puts "History file '#{histfile}' was empty or non-existant." if $VERBOSE
    end
    Kernel::at_exit do
      lines = Readline::HISTORY.to_a.reverse.uniq.reverse
      lines = lines[-MAXHISTSIZE, MAXHISTSIZE] if lines.nitems > MAXHISTSIZE
      puts "Saving #{lines.length} history lines to '#{histfile}'." if $VERBOSE
      File::open(histfile, File::WRONLY|File::CREAT|File::TRUNC) { |io| io.puts lines.join("\n") }
    end
  rescue => e
    puts "Error when configuring permanent history: #{e}" if $VERBOSE
  end

  ETC_IRBRC_LOADED=true
end

# IRB Options
IRB.conf[:PROMPT_MODE] = :SIMPLE
IRB.conf[:AUTO_INDENT] = true
IRB.conf[:SAVE_HISTORY] = MAXHISTSIZE
IRB.conf[:EVAL_HISTORY] = 1000
# Use the simple prompt if possible.
IRB.conf[:PROMPT_MODE] = :SIMPLE if IRB.conf[:PROMPT_MODE] == :DEFAULT
# start wirble (with color)

Wirble.init
Wirble.colorize
# hirb (active record output format in table)

Hirb::View.enable

def edit_obj( obj )
  tempfile = File.join('/tmp',"yobj_#{ Time.now.to_i }")
  File.open( tempfile, 'w' ) { |f| f << obj.to_yaml }
  system( "#{ ENV['EDITOR'] || 'vi' } #{ tempfile }" )
  return obj unless File.exists?( tempfile )
  content = YAML::load( File.open( tempfile ) )
  File.delete( tempfile )
  content
end


def local_methods(obj = self)
  (obj.methods - (obj.class.superclass || obj.class).send(:instance_methods)).sort
end

class Object  
  
  def edit
    edit_obj(self)
  end
  # list methods which aren't in superclass
  def local_methods(obj = self)
    (obj.methods - (obj.class.superclass || obj.class).send(:instance_methods)).sort
  end
  
  # print documentation
  #
  #   ri 'Array#pop'
  #   Array.ri
  #   Array.ri :pop
  #   arr.ri :pop
  def ri(method = nil)
    unless method && method =~ /^[A-Z]/ # if class isn't specified
      klass = self.kind_of?(Class) ? name : self.class.name
      method = [klass, method].compact.join('#')
    end
    puts `ri '#{method}'`
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
  
  def self.from_file(file_name)
    File.read(file_name) 
  end
  
  def to_clipboard
     IO.popen('pbcopy', 'w') { |f| f << self.to_s }
  end
  
  def self.from_clipboard
    paste
  end
end

# paste it from the clipboeard
def c
  system('clear')
end

# Open in TextMate
def mate *args
  flattened_args = args.map {|arg| "\"#{arg.to_s}\""}.join ' '
  `mate #{flattened_args}`
  nil
end

#http://blog.bogojoker.com/index.php?s=ssh
# Awesome benchmarking function
# Source: http://ozmm.org/posts/time_in_irb.html
def time(times=1)
  require "benchmark"
  ret = nil
  Benchmark.bm { |x| x.report { times.times { ret = yield } } }
  ret
end
alias bench time

# A cool way to index in a hash
# h = { :alpha => 'bet', :beta => 'blocker' }
# h/:beta #=> 'blocker'
class Hash
  def /(key)
    self[key]
  end
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

def h
  y([
   "#{'#'*50}",
   "lp for looksee gem. Example: lp []",
   "local_methods #=> zeigt nur Mithoden des Objects", 
   "ap #=> for pretty print objects",
   "c #=> clearstring",
   "ri #=> print documentation ri 'Array#pop' Array.ri, arr.ri :pop",    
   "Object.edit", 
   "String.to_file s", 
   "String.from_file",
   "String.to_clipboard",
   "paste #=>paste it from the clipboard x = paste ",
   "mate #=> Opens Textmate",
   "show_regexp #=> show_regexp('bla',/a/) => bl<<a>>",
   "Regex.show_match #=> /an/.show_match('banana') # => 'b<<an>>ana'",
   "time{} #=> Benchmarks",
   "#{'#'*50}"
  ])
end


load '~/bin/dotfiles/railsrc' if $0 == 'irb' && ENV['RAILS_ENV']
save_require 'active_support' unless ENV['RAILS_ENV'] 
require "ap" #http://github.com/michaeldv/awesome_print
puts h
