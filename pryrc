# https://github.com/pry/pry/wiki/Pry-rc

# === EDITOR ===
Pry.editor = 'atom'

if defined?(PryDebugger)
  Pry.commands.alias_command 'c', 'continue' #Continue program execution and end the Pry session
  Pry.commands.alias_command 's', 'step'  # Step execution into the next line or method
  Pry.commands.alias_command 'n', 'next'  # Step over to the next line within the same frame
  Pry.commands.alias_command 'f', 'finish' # Execute until current stack frame returns
end
