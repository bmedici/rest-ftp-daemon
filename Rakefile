# encoding: utf-8
require "bundler/gem_tasks"
require "rubygems"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = false
end

# Load my own tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

# Run specs by default
desc "Run all tests"
task default: [:spec, :rubocop]
