require 'rake'

desc "install the dot files into user's home directory"
task :install do
  puts %x{chmod +x set_links}
  puts %x{./set_links}
end

task :update do
  puts %x{git pull --rebase}
  #sh "source #{File.join(File.dirname(__FILE__),'bash','aliases')}"
end