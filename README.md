rest-ftp-daemon
====================================================================================

[![Gem Version](https://badge.fury.io/rb/rest-ftp-daemon.svg)](http://badge.fury.io/rb/rest-ftp-daemon)
[![Code Climate](https://codeclimate.com/github/bmedici/rest-ftp-daemon/badges/gpa.svg)](https://codeclimate.com/github/bmedici/rest-ftp-daemon)
[![Test Coverage](https://codeclimate.com/github/bmedici/rest-ftp-daemon/badges/coverage.svg)](https://codeclimate.com/github/bmedici/rest-ftp-daemon/coverage)


A pretty simple but configurable and efficient FTP-client daemon, driven
through a RESTful API. Create transfer jobs by POSTing a simple JSON structure,
be notified of their completion, watch their status on a dedicated dashboard.


![Dashboard](dashboard.png)


Features
------------------------------------------------------------------------------------

* System and process features
  * environment-aware configuration in a YAML file
  * daemon process is tagged with its name and environment in process lists
  * global dashboard directly served within the daemon HTTP interface
  * support pooling of worker to dedicate workers to groups of jobs

* File management ans transferts
  * allow authentication in FTP target in a standard URI-format
  * static path pointers in configuration to abstract local mounts or remote FTPs (endpoint tokens)
  * local source path and local/remote target path can use patterns to match multiple files (`/dir/file*.jpg`)
  * several file transfer protocols supported: FTPs, FTPes, sFTP

* Job management
  * highly parrallel job processing using dedicated worker threads with their own context
  * jobs are taken into account as soon as they are submitted
  * each job carry its own attributes: build subdirectories (mkdir), overwrite target file, priority weight
  * dynamic evaluation of priorities, honoring any change on context until the job is picked
  * automatically clean-up jobs after a configurable amount of time (failed, finished)

* Realtime status reporting
  * realtime transfer status reporting, with progress and errors
  * periodic update notifications sent along with transfer status and progress to an arbitrary URL (JSON resource POSTed)



Status
------------------------------------------------------------------------------------

Though it may need more robust tests, this gem has been used successfully in production for
a while without any glitches at France Télévisions.

Expected features in a short-time range :

* Provide swagger-style API documentation
* Authenticate API clients
* Allow more transfer protocols (HTTP POST etc)
* Expose JSON status of workers on `GET /jobs/` for automated monitoring



Installation
------------------------------------------------------------------------------------

With Ruby (version 2.3 or higher) and rubygems properly installed, you only need :

```
gem install rest-ftp-daemon
```

If that is not the case yet, see section [Debian install preparation](#debian-install-preparation).


Usage
------------------------------------------------------------------------------------

You must provide a configuration file for the daemon to start, either explicitly using
option `--config` or implicitly at `/etc/rest-ftp-daemon.yml`. A sample file is provided, issue
`--help` to get more info.

You then simply start the daemon on its standard port, or on a specific port using `-p`

```
$ rest-ftp-daemon -p 3000 start
```

Check that the daemon is running and exposes a JSON status structure at `http://localhost:3000/status`.

The dashboard will provide an overview at `http://localhost:3000/`

If the daemon appears to exit quickly when launched, it may be caused by logfiles that can't be written (check files permissions or owner).

Launcher options :

| Param   | Short         | Default       | Description                                                 |
|-------  |-------------- |-------------  |-----------------------------------------------------------  |
| -p      | --port        | (automatic)   | Port to listen for API requests                             |
| -e      |               | production    | Environment name                                            |
|         | --dev         |               | Equivalent to -e development                                |
| -d      | --daemonize   | false         | Wether to send the daemon to background                     |
| -f      | --foreground  | false         | Wether to keep the daemon running in the shell              |
| -P      | --pid         | (automatic)   | Path of the file containing the PID                         |
| -u      | --user        | (none)        | User to run the daemon as                                   |
| -g      | --group       | (none)        | Group of the user to run the daemon as                      |
| -h      | --help        |               | Show info about the current version and available options   |
| -v      | --version     |               | Show the current version                                    |


Usage and examples
------------------------------------------------------------------------------------

#### Start a job to transfer a file named "file.iso" to a local FTP server

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.iso","target":"ftp://anonymous@localhost/incoming/dest2.iso"}' "http://localhost:3000/jobs"
```

#### Start a job using endpoint tokens

First define ``nas`` ans ``ftp1`` in the configuration file :

```
defaults: &defaults

development:
  <<: *defaults

  endpoints:
    nas: "~/"
    ftp1: "ftp://anonymous@localhost/incoming/"
```

Those tokens will be expanded when the job is run:

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.dmg","priority":"3","target":"ftp://anonymous@localhost/incoming/dest4.dmg","notify":"http://requestb.in/1321axg1"}' "http://localhost:3000/jobs"
```


#### Start a job with a specific pool name

The daemon spawns groups of workers (worker pools) to work on groups of jobs (job pools). Any ```pool``` attribute not declared in configuration will land into the ```"default"``` pool.

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"pool": "maxxxxx",source":"~/file.iso",target":"ftp://anonymous@localhost/incoming/dest2.iso"}' "http://localhost:3000/jobs"
```
This job will be handled by the "maxxxxx" workers only, or by the ```"default"``` worker is this pool is not declared.


#### Get info about a job with ID="q89j.1"

Both parameters `q89j.1` and `1` will be accepted as ID in the API. Requests below are equivalent:

```
GET http://localhost:3000/jobs/q89j.1
GET http://localhost:3000/jobs/1
```


API Documentation
------------------------------------------------------------------------------------

API documentation is [maintained on Apiary](http://docs.restftpdaemon.apiary.io/)


Configuration
------------------------------------------------------------------------------------

Most of the configuration options live in a YAML configuration file, containing two main sections:

* `defaults` section should be left as-is and will be used is no other environment-specific value is provided.
* `production` section can receive personalized settings according to your environment-specific setup and paths.

Configuration priority is defined as follows (from most important to last resort):

* command-line parameters
* config file defaults section
* config file environment section
* application internal defaults

As a starting point, `rest-ftp-daemon.yml.sample` is an example config file that can be  copied into the expected location ``/etc/rest-ftp-daemon.yml``.

Default administrator credentials are `admin/admin`. Please change the password in this configuration file before starting any kind of production.


Logging
------------------------------------------------------------------------------------

The application will log to paths specified in the configuration file, if any.
Separate logging paths can be provided for the Thin webserver, API related messages, and workers related messages.
Providing empty values as paths, will simply activate logging to `STDOUT`.


Job cleanup
------------------------------------------------------------------------------------

Job queue can be set to automatically cleanup after a certain delay. Entries are removed from the queue when they have been idle (updated_at) for more than X seconds, and in any of the following statuses:

- failed (conchita.clean_failed)
- finished (conchita.clean_finished)
- queued, (conchita.clean_queued)

Cleanup is done on a regular basis, every (conchita.timer) seconds.


TODO for this document
------------------------------------------------------------------------------------

* Update Apiary documentation
* Update Apiary documentation
* Update Apiary documentation
* Update Apiary documentation !
* Document /status
* Document /routes
* Document mkdir and overwrite options
* Document counters



Debian install preparation
------------------------------------------------------------------------------------

This project is available as a rubygem, requires Ruby 2.3 and rubygems installed.

#### Using rbenv and ruby-build

You may use `rbenv` and `ruby-build` to get the right Ruby version. If this is your case, ensure that ruby-build definitions are up-to-date and include the right Ruby version.

```
# git clone https://github.com/rbenv/rbenv.git ~/.rbenv
# git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
# echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
# echo 'eval "$(rbenv init -)"' >> ~/.bashrc
# ruby-build --definitions | grep '2.3'
```

Otherwise, you way have to update ruby-build to include Ruby 2.3.0 definitions.
On Debian, 2.3.0 is not included in Wheezy and appears in Jessie's version of the package.

#### Dedicated user

Use a dedicated user for the daemon, switch to this user and enable rbenv

```
# adduser --disabled-password --gecos "" rftpd
# su rftpd -l
```

#### Ruby version

Install the right ruby version and activate it

```
# rbenv install 2.1.0
# rbenv local 2.1.0
# rbenv rehash
```

#### Daemon installation

Update RubyGems and install the gem from rubygems.org

```
# gem update --system
# gem install rest-ftp-daemon --no-ri --no-rdoc
# rbenv rehash
# rest-ftp-daemon start
```

Known bugs
------------------------------------------------------------------------------------

* As this project is based on SettingsLogic, which in turns uses Syck YAML parser, configuration merge from "defaults" section and environment-specific section is broken. A sub-tree defined for a specific environment, will overwrite the corresponding subtree from "defaults".

* If you get ```fatal error: 'openssl/ssl.h' file not found when installing ```eventmachine``` on OSX El Capitan, you can try with:
```
gem install eventmachine -v '1.0.8' -- --with-cppflags=-I/usr/local/opt/openssl/include
bundle install
```


Contributing
------------------------------------------------------------------------------------

Contributions are more than welcome, be it for documentation, features, tests,
refactoring, you name it. If you are unsure of where to start, the [Code
Climate](https://codeclimate.com/github/bmedici/rest-ftp-daemon) report will
provide you with improvement directions. And of course, if in doubt, do not
hesitate to open an issue. (Please note that this project has adopted a [code
of conduct](CODE_OF_CONDUCT.md).)

If you want your contribution to adopted in the smoothest and fastest way, don't
forget to:

* provide sufficient documentation in you commit and pull request
* add proper testing (we know full grown solid test coverage is still lacking and
  need to up the game)
* use the [RuboCop](https://github.com/bbatsov/rubocop) guidelines provided
  (there are all sorts of editor integration plugins available)

So,

1. Fork the project
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Code
  * add proper tests if adding a feature
  * run the tests using `rake`
  * check for RuboCop style guide violations

4. Commit your changes
5. Push to the branch (`git push origin my-new-feature`)

6. Create new Pull Request


About
------------------------------------------------------------------------------------

Thanks to https://github.com/berkshelf/berkshelf-api for parts and ideas used in this project

This project has been initiated and originally written by
Bruno MEDICI Consultant (http://bmconseil.com/)



