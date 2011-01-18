#!/usr/bin/env ruby

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
    system("git show -p #{@options[:branch]}:#{@options[:file]}")
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
    STDERR.puts "#{$0}:Not implemented yet."
  end
end
# }}}

require 'optparse'

options = { }
optparse = OptionParser.new do |o|
  options[:file] = conf.of("file")
  options[:branch] = conf.of("branch")
  options[:actions] = [ShowAll.new(options)]
  o.on("--get VERSION", "List a tasks for version") do |v|
    options[:actions].push(ShowVersion.new(options, v))
  end

  o.on("--add-task VERSION.TASK", "Add a task to a version") do |t|
    version, task = t.split(".")
    options[:actions].push(AddTask.new(options, version, task))
  end
end.parse!

options[:actions].each { |a| a.execute }

# vim: foldmethod=marker
