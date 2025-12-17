#!/usr/bin/env python3
import argparse
import os
import sys
import time
import subprocess
from contextlib import contextmanager

try:
	from obswebsocket import obsws, requests
except ImportError:
	print("error: please install obs-websocket-py: pip install obs-websocket-py", file=sys.stderr)
	sys.exit(1)


@contextmanager
def ssh_tunnel(enabled, ssh_host, ssh_user, ssh_port, local_port, remote_port):
	"""
	Optionally create an SSH local port-forward (local_port -> ssh_host:remote_port).

	If `enabled` is False, this does nothing.
	"""
	proc = None
	try:
		if enabled:
			if not ssh_host:
				raise SystemExit("ssh_tunnel requested but no --ssh-host was provided")

			dest = f"{ssh_user + '@' if ssh_user else ''}{ssh_host}"

			cmd = [
				"ssh",
				"-p",
				str(ssh_port),
				"-o",
				"ExitOnForwardFailure=yes",
				"-L",
				f"{local_port}:127.0.0.1:{remote_port}",
				dest,
				"-N",
			]
			proc = subprocess.Popen(
				cmd,
				stdout=subprocess.PIPE,
				stderr=subprocess.PIPE,
			)

			# Give ssh a moment to establish the tunnel
			time.sleep(0.5)

			# If ssh exited, surface the error
			rc = proc.poll()
			if rc is not None:
				out, err = proc.communicate()
				raise SystemExit(
					f"ssh tunnel failed with exit code {rc}.\n"
					f"Command: {' '.join(cmd)}\n"
					f"stderr:\n{err.decode(errors='ignore')}"
				)

		yield

	finally:
		if proc is not None and proc.poll() is None:
			proc.terminate()
			try:
				proc.wait(timeout=3)
			except subprocess.TimeoutExpired:
				proc.kill()


def do_action(ws, action: str):
	"""
	Run the requested action against OBS via obs-websocket.
	"""
	if action == "start":
		resp = ws.call(requests.StartRecord())
		if not resp.status:
			raise RuntimeError(f"StartRecord failed: {resp}")
		print("Recording started.")

	elif action == "stop":
		resp = ws.call(requests.StopRecord())
		if not resp.status:
			raise RuntimeError(f"StopRecord failed: {resp}")
		print("Recording stopped.")

	elif action == "toggle":
		status = ws.call(requests.GetRecordStatus())
		if not status.status:
			raise RuntimeError(f"GetRecordStatus failed: {status}")

		is_active = status.getOutputActive()
		if is_active:
			resp = ws.call(requests.StopRecord())
			if not resp.status:
				raise RuntimeError(f"StopRecord failed: {resp}")
			print("Recording was active -> stopped.")
		else:
			resp = ws.call(requests.StartRecord())
			if not resp.status:
				raise RuntimeError(f"StartRecord failed: {resp}")
			print("Recording was idle -> started.")

	elif action == "status":
		status = ws.call(requests.GetRecordStatus())
		if not status.status:
			raise RuntimeError(f"GetRecordStatus failed: {status}")

		is_active = status.getOutputActive()
		output_timecode = getattr(status, "getOutputTimecode", lambda: None)()
		print(f"Recording status: {'ACTIVE' if is_active else 'INACTIVE'}")
		if output_timecode is not None:
			print(f"Output timecode: {output_timecode}")

	else:
		raise ValueError(f"Unknown action: {action}")


def main(argv=None):
	parser = argparse.ArgumentParser(
		description="Simple CLI to start/stop OBS recording via obs-websocket, "
					"optionally through an SSH tunnel."
	)
	parser.add_argument(
		"action",
		choices=["start", "stop", "toggle", "status"],
		help="What to do with OBS recording.",
	)
	parser.add_argument(
		"--host",
		default="127.0.0.1",
		help="OBS websocket host (used directly if no SSH tunnel). Default: 127.0.0.1",
	)
	parser.add_argument(
		"--port",
		type=int,
		default=4455,
		help="OBS websocket port. OBS 28+ default for v5 websocket is 4455.",
	)
	parser.add_argument(
		"--password",
		help="OBS websocket password. If omitted, will use OBS_WS_PASSWORD env var.",
	)

	# SSH options
	parser.add_argument(
		"--ssh-host",
		help="If set, create an SSH tunnel to this host and connect to OBS through it.",
	)
	parser.add_argument(
		"--ssh-user",
		help="SSH username. Defaults to current user if omitted.",
	)
	parser.add_argument(
		"--ssh-port",
		type=int,
		default=22,
		help="SSH port on remote host. Default: 22",
	)

	args = parser.parse_args(argv)

	password = args.password or os.environ.get("OBS_WS_PASSWORD", "")

	use_ssh = args.ssh_host is not None
	ws_host = "127.0.0.1" if use_ssh else args.host

	with ssh_tunnel(
		enabled=use_ssh,
		ssh_host=args.ssh_host,
		ssh_user=args.ssh_user,
		ssh_port=args.ssh_port,
		local_port=args.port,
		remote_port=args.port,
	):
		ws = obsws(ws_host, args.port, password)

		try:
			ws.connect()
		except Exception as e:
			raise SystemExit(f"Failed to connect to OBS websocket at {ws_host}:{args.port}: {e}")

		try:
			do_action(ws, args.action)
		finally:
			ws.disconnect()


if __name__ == "__main__":
	main()

