rest-ftp-daemon
====================================================================================

This is a pretty simple FTP client daemon, controlled through a RESTfull API.

As of today, its main features are :

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

Check that the daemon is running and giving status info

```
http://localhost:3000/
```

For now, daemon logs to ```APP_LOGTO``` defined in ```lib/config.rb```


Usage examples
------------------------------------------------------------------------------------

Start a job to transfer a file named "file.iso" to a local FTP server

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.iso","target":"ftp://anonymous@localhost/incoming/dest2.iso"}' "http://localhost:3000/jobs"
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

The server exposes jobs list on ``` GET /jobs ```

```
http://localhost:3000/jobs
```

This query will return a job list :

```
[
  {
    "source": "~/file.dmg",
    "target": "ftp://anonymous@localhost/incoming/dest2.dmg",
    "worker_name": "bob-92439-1",
    "created": "2014-08-01 16:53:08 +0200",
    "id": 16,
    "runtime": 17.4,
    "status": "graceful_ending",
    "source_size": 37109074,
    "error": 0,
    "errmsg": "finished",
    "progress": 100.0,
    "transferred": 37100000
  },
  {
    "source": "~/file.ova",
    "target": "ftp://anonymous@localhost/incoming/dest2.ova",
    "worker_name": "bob-92439-2",
    "created": "2014-08-01 16:53:12 +0200",
    "id": 17,
    "runtime": 13.8,
    "status": "uploading",
    "source_size": 1849036800,
    "error": -1,
    "errmsg": "uploading",
    "progress": 36.1,
    "transferred": 668300000
  }
]
```


About
------------------------------------------------------------------------------------

Bruno MEDICI Consultant

http://bmconseil.com/
