## Brief Documentation for Starting DRAWS Manager

* **NOTE** DRAWS manager uses port **8080** which is a well used port.
  * For example Winlink client PAT uses the same port
  * To stop DRAWS manager and free up the port for other programs do the following:
```
mgr-ctrl.sh stop
```
* If DRAWS manager does not start up, determine if some other running process is using port 8080

```
sudo lsof -i -P -n | grep LISTEN | grep 8080
```

### To run DRAWS manager in a browser

##### First, make sure the DRAWS manager process is running:
```
 mgr-ctrl.sh status
```
##### then open a browser and put the following into the URL:
```
localhost:8080
```

##### Example output from 'mgr-ctrl.sh status' for a running DRAWS manager:
```
$ mgr-ctrl.sh status
 draws-manager.service - DRAWS13 Manager - A web application to manage the DRAWS HAT configuration.
   Loaded: loaded (/etc/systemd/system/draws-manager.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2021-11-09 11:07:27 PST; 2s ago
     Docs: https://github.com/nwdigitalradio/draws-manager
 Main PID: 20736 (npm)
    Tasks: 7 (limit: 4915)
   CGroup: /system.slice/draws-manager.service
           20736 npm

Nov 09 11:07:27 test120-11042020 systemd[1]: Started DRAWS Manager - A web application to manage the DRAWS HAT configuration..
-- Logs begin at Mon 2021-11-08 11:30:03 PST, end at Tue 2021-11-09 11:07:27 PST. --
Nov 09 11:07:27 test120-11042020 systemd[1]: Started DRAWS Manager - A web application to manage the DRAWS HAT configuration..

 Status for draws-manager: RUNNING and ENABLED
```

##### **NOTE:** IF you do NOT see the above then:
* Verify that port 8080 is **NOT** already in use (see lsof command above)
* start DRAWS manager like this:
```
mgr-ctrl.sh start
```