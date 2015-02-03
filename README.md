rest-ftp-daemon
====================================================================================


This is a pretty simple FTP client daemon, controlled through a RESTful API.

API documentation is [maintained on Apiary](http://docs.restftpdaemon.apiary.io/)



Features
------------------------------------------------------------------------------------

As of today, its main features are :

* Offer a basic dashboard directly within the daemon HTTP interface
* Periodically send an update-notification with transfer status and progress
* Allow environment-specific configuration in a YAML file
* Delegate a transfer job by ``POST```'ing a simple JSON structure
* Spawn a dedicated thread to handle this job in its own context
* Report transfer status, progress and errors for each job in realtime
* Expose JSON status of workers on ```GET /jobs/``` for automated monitoring
* Parralelize jobs as soon as they arrive
* Handle job queues and priority as an attribute of the job
* Allow dynamic evaluation of priorities, and change of any attribute until the job is picked
* Provide RESTful notifications to the requesting client
* Allow authentication in FTP target in a standard URI-format
* Allow configuration-based path templates to abstract local mounts or remote FTPs (endpoint tokens)
* Allow to specify random remote/local source/target
* Remote supported protocols: FTP and FTPs
* Allow main file transfer protocols: sFTP, FTPs / FTPes
* Automatically clean-up jobs after a configurable amount of time (failed, finished)
* Current bitrate on the last blocks chunk updated in the job attributes
* Global bitrate on the whole file transfer is re-computed after the transfer finishes
* Daemon process is tagged with its name and environement in process lists
* Allow basic patterns in source filename to match multiple files (/dir/file*.jpg)

Expected features in a short-time range :

* Allow fallback file source when first file path is unavailable (failover)
* Provide swagger-style API documentation
* Authenticate API clients
* Allow more transfer protocols (sFTP, HTTP POST etc)

Known bugs :

* As this project is based on SettingsLogic, which in turns uses Syck YAML parser, configuration merge from "defaults" section and environment-specific section is broken. A sub-tree defined for a specific environment, will overwrite the corresponding subtree from "defaults".


Installation
------------------------------------------------------------------------------------

This project is available as a rubygem, requires Ruby 2.1 and rubygems installed.

You may use ```rbenv``` and ```ruby-build``` to get the right Ruby version. If this is your case, ensure that ruby-build definitions are up-to-date and include ruby-2.1.0

```
# apt-get install ruby-build rbenv
# ruby-build --definitions | grep '2.1'
```

Otherwise, you way have to update ruby-build to include Ruby 2.1.0 definitions.
On Debian, 2.1.0 is not included in Wheezy and appears in Jessie's version of the package.

Use a dedicated user for the daemon, switch to this user and enable rbenv

```
# adduser --disabled-password --gecos "" rftpd
# su rftpd -l
# echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
# echo 'eval "$(rbenv init -)"' >> ~/.bashrc
```


Install the right ruby version and activate it

```
# rbenv install 2.1.0
# rbenv local 2.1.0
# rbenv rehash
```

Update RubyGems and install the gem from rubygems.org

```
# gem update --system
# gem install rest-ftp-daemon --no-ri --no-rdoc
# rbenv rehash
# rest-ftp-daemon start
```


Configuration
------------------------------------------------------------------------------------

Most of the configuration options live in a YAML configuration file, containing two main sections:

* the ``defaults`` section should be left as-is and will be used is no other environment-specific value is provided.
* the ``production`` section can receive personnalized settings according to your environment-specific setup and paths.

Configuration priority is defined as follows (from most important to last resort):

* command-line parameters
* config file defaults section
* config file environment section
* application internal defaults

As a starting point, ``rest-ftp-daemon.yml.sample`` is an exemple config file that can be  copied into the expected location ``/etc/rest-ftp-daemon.yml``.

Default administrator credentials are admin/admin. Please change the password in this configuration file before starting any kind of production.


Execution
------------------------------------------------------------------------------------

You can simply start the daemon on the standart port, or on a specific port using ```-p```

```
# rest-ftp-daemon -p 4000 start
```

Check that the daemon is running and exposes a JSON status structure on ```http://localhost:3200/status```.

The dashbaord will provide a gobal view on ```http://localhost:3200/```

If the daemon appears to exit quickly when launched, it may be caused by logfiles that can't be written (check files permissions or owner).

Launcher options :

| Param   | Short         | Default       | Description                                                 |
|-------  |-------------- |-------------  |-----------------------------------------------------------  |
| -p      | --port        | (automatic)   | Port to listen for API requests                             |
| -e      |               | production    | Environment name                                            |
|         | --dev         |               | Equivalent to -e development                                |
| -w      | --workers     | 1             | Number of workers spawned at launch                         |
| -d      | --daemonize   | false         | Wether to send the daemon to background                     |
| -f      | --foreground  | false         | Wether to keep the daemon running in the shell              |
| -P      | --pid         | (automatic)   | Path of the file containing the PID                         |
| -u      | --user        | (none)        | User to run the daemon as                                   |
| -g      | --group       | (none)        | Group of the user to run the daemon as                      |
| -h      | --help        |               | Show info about the current version and available options   |
| -v      | --version     |               | Show the current version                                    |


Logging
------------------------------------------------------------------------------------

The application will not log to any file by default, if not specified in its configuration.
Otherwise separate logging paths can be provided for the Thin webserver, API related messages, and workers related messages. Providing and empty value will simply activate logging to ``STDOUT``.


Job cleanup
------------------------------------------------------------------------------------

Job can be cleanup up after a certain delay, when they are on one of these status:

- "failed", cleaned up after conchita.clean_failed seconds
- "finished", cleaned up after conchita.clean_finished seconds

Cleanup is done on a regular basis, every X seconds (X = conchita.timer)


Usage examples
------------------------------------------------------------------------------------

* Start a job to transfer a file named "file.iso" to a local FTP server

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.iso","target":"ftp://anonymous@localhost/incoming/dest2.iso"}' "http://localhost:3000/jobs"
```

* Start a job using endpoint tokens

First define ``nas`` ans ``ftp1`` in the configuration file :

```
defaults: &defaults

development:
  <<: *defaults

  endpoints:
    nas: "~/"
    ftp1: "ftp://anonymous@localhost/incoming/"
```

Thos tokens will be expanded when the job is ran :

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.dmg","priority":"3", target":"ftp://anonymous@localhost/incoming/dest4.dmg","notify":"http://requestb.in/1321axg1"}' "http://localhost:3000/jobs"
```


* Get info about a job with ID="q89j.1"

Both parameters ```q89j.1``` and ```1``` will be accepted as ID in the API. Requests below are equivalent:

```
GET http://localhost:3100/jobs/q89j.1
GET http://localhost:3100/jobs/1
```


TODO for this document
------------------------------------------------------------------------------------

* Update Apiary documentation
* Update Apiary documentation
* Update Apiary documentation
* Update Apiary documentation !
* Document /status
* Document /routes
* Document multiple-files upload
* Document mkdir and overwrite options
* Document counters


About
------------------------------------------------------------------------------------

Bruno MEDICI Consultant

http://bmconseil.com/
