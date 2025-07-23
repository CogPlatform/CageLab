# Services

There are a number of services that are used to run the CageLab serverside applications. We use automatic login and thus these are user services.

* `cogmoteGO.serivce` - The main service that runs our middleware. See cogmoteGO for install with `cogmoteGO service`.
* `theConductor.service` - The service that runs the CageLab Opticka Tasks, a MATLAB script.
* `toggleInput.service` - The service that runs the toggleInput application. This disables the touchscreen on start.
* `obs.service` - The service that runs the OBS application. This streams the desktop and camera out.
* `mediamtx.service` - The service that runs the MediaMTX application. This provides the RTSP server functionality for the CageLab.
* optional: `sunshine.service` - The service that runs the Sunshine application.



To install:

* System services are copied to `/etc/systemd/system`
* User services are copied to `~/.config/systemd/user`
* Reload edited services with `sudo systemctl daemon-reload` and `systemctl --user daemon-reload`.
* User services are enabled with `systemctl --user enable <service>` and started with `systemctl --user start <service>`.
* System services are enabled with `sudo systemctl enable <service>` and started with `systemctl start <service>`.

To check the status of a service:
* `systemctl status <service>` for system services.
* `systemctl --user status <service>` for user services.
* `journalctl -f --all -u <service>` for logs of the system service.
* `journalctl --user -f --all -u <service>` for logs of the user service.
