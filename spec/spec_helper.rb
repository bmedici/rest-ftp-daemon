require "pathname"
require "http"
require "pry"

require_relative "../lib/rest-ftp-daemon/constants"
require_relative "support/request_helpers"

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  config.order = :random
  Kernel.srand config.seed

  include RequestHelpers

  def call_server command, port = RequestHelpers::PORT
    system(Pathname(__dir__).join("../bin/rest-ftp-daemon -e test -p #{port} #{command}").to_s, chdir: __dir__) || fail("Could not #{command} server")
  end

  config.before :suite do
    puts
    puts ">> starting up server..."
    puts
    call_server(:start)
    sleep 5
    puts ">> server should be running now"
  end

  config.after :suite do
    puts
    puts ">> shutting down server..."
    puts
    call_server(:stop)
  end
end
