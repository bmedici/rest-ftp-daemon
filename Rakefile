# encoding: utf-8
require "bundler/gem_tasks"
require "rubygems"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

# Run specs by default
desc "Run all tests"

require "rubocop/rake_task"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = false
end

task default: [:spec, :rubocop]
