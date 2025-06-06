# Services

There are a number of services that are used to run the CageLab serverside applications:

* cogmoteGO@.serivce <<system>> - The main service that runs the middleware.
* theConductor.service <<user>> - The service that runs the CageLab Opticka Tasks.
* toggleInput.service <<user>> - The service that runs the toggleInput application.
* obs.service <<system>> - The service that runs the OBS application.
* sunshine.service <<system>> - The service that runs the Sunshine application.
* mediamtx.service <<system>> - The service that runs the MediaMTX application.


To install:

* System services are copied to `/etc/systemd/system`
* User services are copied to `/etc/system/user`
* Reload services with `sudo systemctl daemon-reload` and `systemctl --user daemon-reload`.
* User services are enabled with `systemctl --user enable <service>` and started with `systemctl --user start <service>`.
* System services are enabled with `sudo systemctl enable <service>` and started with `systemctl start <service>`.

To check the status of a service:
* `systemctl status <service>` for system services.
* `systemctl --user status <service>` for user services.
* `journalctl -f -u <service>` for logs of the system service.
* `journalctl --user -f -u <service>` for logs of the user service.
