# (Copied from:
# http://stackoverflow.com/questions/1197224/source-shell-script-into-environment-within-a-ruby-script)

# Read in the bash environment, after an optional command.
#   Returns Array of key/value pairs.
def bash_env(cmd=nil)
  env = `#{cmd + ';' if cmd} printenv`
  env.split(/\n/).map {|l| l.split(/=/)}
end

# Source a given file, and compare environment before and after.
#   Returns Hash of any keys that have changed.
def bash_source(file)
  Hash[ bash_env(". #{File.realpath file}") - bash_env() ]
end

# Find variables changed as a result of sourcing the given file, 
#   and update in ENV.
def source_env_from(file)
  bash_source(file).each {|k,v| ENV[k] = v }
end
