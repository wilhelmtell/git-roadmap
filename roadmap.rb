#!/usr/bin/env ruby

require 'yaml'

# Configuration wrapper {{{1
class ConfigValueNotFoundError < RuntimeError
end

class Configuration
  def initialize
    @memoized = {
      "file" => "ROADMAP",
      "branch" => "napkin"
    }
  end

  def of(param, default = nil)
    param = param.downcase
    return @memoized[param] if @memoized.include? param
    return from_environment(param) rescue nil
    return from_git_config(param) rescue nil
    return default
  end

  private
  def from_environment(param)
    environment_variable = ENV["GIT_ROADMAP_#{param.upcase}"]
    unless environment_variable.nil?
      @memoized[param] = environment_variable
      return @memoized[param]
    end
    raise ConfigValueNotFoundError
  end

  def from_git_config(param)
    git_config = `git config --get roadmap.#{param}`
    if $?.exitstatus == 0
      @memoized = git_config
      return git_config
    end
    raise ConfigValueNotFoundError
  end
end
conf = Configuration.new

# Actions {{{1
class ShowAll
  def initialize(options)
    @options = options
  end

  def execute
    roadmap = YAML::load(`git show -p #{@options[:branch]}:#{@options[:file]}`)
    roadmap.each_key do |k|
      puts "#{k}:"
      roadmap[k].each do |t|
        puts " - #{t}"
      end
      puts
    end
  end
end

class ShowVersion
  def initialize(options, version)
    @options = options
    @version = version
  end

  def execute
    STDERR.puts "#{$0}:Not implemented yet."
  end
end

class AddTask
  def initialize(options, version, text)
    @options = options
    @version, @text = version, text
  end

  def execute
    roadmap = YAML::load(`git show -p #{@options[:branch]}:#{@options[:file]}`)
    roadmap ||= { }
    roadmap[@version] ||= [ ]
    roadmap[@version].push(@text)
    system("git stash -q")
    system("git checkout -q #{@options[:branch]}")
    File.open(@options[:file], "w") do |f|
      f.write(YAML::dump(roadmap))
    end
    system("git add #{@options[:file]}")
    system("git commit -q -m'updated roadmap'")
    system("git checkout -q -")
    system("git stash pop -q")
  end
end
# }}}

require 'optparse'

options = { }
optparse = OptionParser.new do |o|
  options[:file] = conf.of("file")
  options[:branch] = conf.of("branch")
  options[:action] = nil
  o.on("--get VERSION", "List a tasks for version") do |v|
    if not options[:action].nil?
      STDERR.puts "Please specify zero or one of --get, --add-task"
      exit 1
    end
    options[:action] = ShowVersion.new(options, v)
  end

  o.on("--add-task VERSION.TASK", "Add a task to a version") do |t|
    input = t.split(".")
    version, task = input[0..-2].join("."), input[-1]
    if not options[:action].nil?
      STDERR.puts "Please specify zero or one of --get, --add-task"
      exit 1
    end
    options[:action] = AddTask.new(options, version, task)
  end
end.parse!
options[:action] ||= ShowAll.new(options)

options[:action].execute

# vim: foldmethod=marker
