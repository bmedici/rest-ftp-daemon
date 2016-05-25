# Terrific constants
APP_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../")
APP_SPEC = Gem::Specification::load("#{APP_ROOT}/rest-ftp-daemon.gemspec")
APP_LIB = File.expand_path(File.dirname(__FILE__))

# Config constants
APP_NICK = "rftpd"
APP_STARTED = Time.now

# Launcher constants
BIND_PORT_TIMEOUT       = 3
BIND_PORT_LOCALHOST     = "127.0.0.1"


DEFAULT_CONFIG_PATH = File.expand_path "/etc/#{APP_SPEC.name}.yml"
SAMPLE_CONFIG_FILE = File.expand_path(File.join File.dirname(__FILE__), "/../../#{APP_SPEC.name}.yml.sample")
TAIL_MESSAGE = <<EOD

A default configuration is available here: #{SAMPLE_CONFIG_FILE}.
You should copy it to the expected location #{DEFAULT_CONFIG_PATH}:

sudo cp #{SAMPLE_CONFIG_FILE} #{DEFAULT_CONFIG_PATH}
EOD


