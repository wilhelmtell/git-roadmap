#!/usr/bin/env ruby

# Configuration wrapper {{{1
class Configuration
  def initialize
    @memoized = { }
  end

  def of(param)
    param = param.downcase
    @memoized[param] ||= ENV["GIT_ROADMAP_#{param.upcase}"] ||
                         `git config --get roadmap.#{param}`
  end
end
conf = Configuration.new

# Actions {{{1
class ShowAll
  def execute
  end
end

class ShowVersion
  def initialize(version)
    @version = version
  end

  def execute
  end
end

class AddTask
  def initialize(version, text)
    @version, @text = version, text
  end

  def execute
  end
end
# }}}

require 'optparse'

options = { }
optparse = OptionParser.new do |o|
  options[:file] = conf.of("file")
  options[:branch] = conf.of("branch")
  options[:actions] = [ShowAll.new]
  o.on("--get VERSION", "List a tasks for version") do |v|
    options[:actions].push(ShowVersion.new(v))
  end

  o.on("--add-task VERSION.TASK", "Add a task to a version") do |t|
    version, task = t.split(".")
    options[:actions].push(AddTask.new(version, task))
  end
end.parse!

# vim: foldmethod=marker
