## rest-ftp-daemon ##

This is a fairly basic FTP client daemon, driven by REST-based webservice calls.
As of today, its main features are :

* Start a job through a basic structure posted with PUT /jobs
* Spawn a dedicated thread to handle this job in its own contexte
* Report transfer progress, error and activity for each job
* Gather jobs status into the main process to get a global view
* Report JSON status of workers on GET /jobs/ for automated monitoring


## Quick setup ##

This project requires ruby >= 1.9 and rubygems installed.

Quickly install the gem from rubygems.org:

 ``` gem install rest-ftp-daemon ```

Start the daemon:

``` rest-ftp-daemon start ```

For now, daemon logs to APP_LOGTO defined in lib/config.rb


## Basic usage ##

Starting a job transferring file named "file.ova"

  curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
  '{"source":"~/file.ova","target":"ftp://anonymous@localhost/incoming/dest2.ova"}' "http://localhost:3000/jobs"


Starting a job transferring file named "dmg"

  curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
  '{"source":"~/file.dmg","target":"ftp://anonymous@localhost/incoming/dest4.dmg"}' "http://localhost:3000/jobs"


Delete a specific job

  curl -H "Content-Type: application/json" -X DELETE -D /dev/stdout "http://localhost:3000/jobs/bob-45320-1"



## Getting status ##

  GET /jobs

Would return:

  [
    {
      "id": "bob-49126-8",
      "process": "sleep",
      "status": "transferring",
      "context": {
        "source": "~\/file.ova",
        "target": "ftp:\/\/anonymous@localhost\/incoming\/dest2.ova",
        "code": -1,
        "errmsg": "running",
        "source_size": 1849036800,
        "progress": 1.9,
        "transferred": 34800000
      }
    },
    {
      "id": "bob-49126-9",
      "process": "sleep",
      "status": "transferring",
      "context": {
        "source": "~\/file.dmg",
        "target": "ftp:\/\/anonymous@localhost\/incoming\/dest4.dmg",
        "code": -1,
        "errmsg": "running",
        "source_size": 37109074,
        "progress": 32.9,
        "transferred": 12200000
      }
    }
  ]


### About ###

Bruno MEDICI

http://bmconseil.com/
