require 'rake'

desc "install the dot files into user's home directory"
task :install do
  File.open(File.join(File.expand_path(File.join(File.dirname(__FILE__))),'DOTFILE'), 'w') { |f| f << "DOTFILESPATH=#{File.expand_path(File.join(File.dirname(__FILE__)))}"}
  puts %x{chmod +x set_links}
  puts %x{./set_links}
end

desc "update the dot files form the repo"
task :update do
  puts %x{git pull origin master --rebase}
end
