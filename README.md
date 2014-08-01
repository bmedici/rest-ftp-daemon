rest-ftp-daemon
====================================================================================

This is a pretty simple FTP client daemon, controlled through a RESTfull API.

Main features :

* Delegate a transfer job, ```PUT```'ing posting simple JSON structure
* Spawn a dedicated thread to handle this job in its own context
* Report transfer status, progress and errors for each delegated job
* Expose JSON status of workers on ```GET /jobs/``` for automated monitoring


Installation
------------------------------------------------------------------------------------

This project is available as a rubygem, requires on ruby >= 1.9 and rubygems installed.

Get and install the gem from rubygems.org:

```
gem install rest-ftp-daemon
```

Start the daemon:

```
rest-ftp-daemon start
```

For now, daemon logs to APP_LOGTO defined in lib/config.rb


Usage examples
------------------------------------------------------------------------------------

Start a job to transfer a file named "file.ova" to a local FTP server

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.ova","target":"ftp://anonymous@localhost/incoming/dest2.ova"}' "http://localhost:3000/jobs"
```

Start a job to transfer a file named "file.dmg" to a local FTP server

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.dmg","target":"ftp://anonymous@localhost/incoming/dest4.dmg"}' "http://localhost:3000/jobs"
```

Get status of a specific job based on its name

```
curl -H "Content-Type: application/json" -X DELETE -D /dev/stdout "http://localhost:3000/jobs/bob-45320-1"
```

Delete a specific job based on its name

```
curl -H "Content-Type: application/json" -X DELETE -D /dev/stdout "http://localhost:3000/jobs/bob-45320-1"
```


Getting status
------------------------------------------------------------------------------------

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


Configuration options
------------------------------------------------------------------------------------

Bruno MEDICI

http://bmconseil.com/

About
------------------------------------------------------------------------------------

Bruno MEDICI

http://bmconseil.com/
