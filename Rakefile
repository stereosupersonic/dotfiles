require 'rake'

desc "install the dot files into user's home directory"
task :install do
  puts %x{chmod +x set_links}
  puts %x{./set_links}
end

desc "update the dot files form the repo"
task :update do
  puts %x{git pull --rebase}
end