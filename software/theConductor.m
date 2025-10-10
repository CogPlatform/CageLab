% ========================================================================
classdef theConductor < optickaCore
%> @class theConductor
%> @brief theConductor — ØMQ REP server to run behavioural tasks
%>
%> This class opens a REP ØMQ and uses a HTTP API to open a REC ØMQ with cogmoteGO
%> It can run PTB or other tasks, designed to provide a local server for CageLab.
%> Requires opticka https://github.com/iandol/opticka
%>
%> Copyright ©2025 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================	
	properties
		%> run the zmq server immediately?
		runNow = false
		%> IP address
		address = '0.0.0.0'
		%> port to bind to
		port = 6666
		%> time in seconds to wait before polling for new messages?
		loopTime = 0.1
		%> hide the OS screen when conductor runs?
		hideScreen = false
		%> more log output to command window?
		verbose = true
	end

	properties (GetAccess = public, SetAccess = protected)
		%> ØMQ jzmqConnection object
		zmq
		%> command
		command
		%> data
		data
		%> is running
		isRunning = false
		%> version
		version
		%> commandList
		commandList = ["exit" "quit" "exitmatlab" "rundemo" ...
			"run" "echo" "gettime" "syncbuffer" "commandlist" ...
			"getlastrun" "exittask" "status"]
	end

	properties (Access = private)
		screenChangeTime = 300
		timeStamp = NaN
		enableHidden = false;
		allowedProperties = {'runNow', 'address', 'port', 'verbose', 'loopTime', 'hideScreen'}
		sendState = false
		recState = false
	end

	properties (Constant)
		baseURI = matlab.net.URI('http://localhost:9012');
		basePath = ["api", "cmds", "proxies"];
		headers = [matlab.net.http.field.ContentTypeField("application/json")];
	end

	methods
		% ===================================================================
		function me = theConductor(varargin)
		%> @brief theConductor constructor
		%> @param varargin PropertyName/PropertyValue pairs to set properties on
		%>   object creation. Allowed properties are:
		%>   - `runNow` (default: false) — run the server immediately
		%>   - `address` (default: '0.0.0.0') — IP address to bind to
		%>   - `port` (default: 6666) — port to bind to
		%>   - `loopTime` (default: 0.1) — time in seconds to wait before polling for new messages
		%>   - `hideScreen` (default: false) — hide the OS screen when conductor runs
		%>   - `verbose` (default: true) — more log output to command window
		%> @details This constructor initializes the `theConductor` object,
		%>   setting default values for properties and parsing any provided
		%>   property name/value pairs. It also sets up Psychtoolbox (PTB) if
		%>   available, and creates a ØMQ REP socket connection using
		%>   `jzmqConnection`. If `runNow` is true, it immediately calls the
		%>   `run` method to start processing commands.
		%> @note Requires the `opticka` package for core functionality.
		%>   Ensure that Psychtoolbox is installed and configured properly if
		%>   using PTB features.
		% ===================================================================	
			args = optickaCore.addDefaults(varargin,struct('name','theConductor'));
			me=me@optickaCore(args); %superclass constructor
			me.parseArgs(args,me.allowedProperties); %check remaining properties from varargin

			me.version = clutil.version;
			try setupPTB(me); end

			me.zmq = jzmqConnection('type', 'REP', 'address', me.address,'port', me.port, 'verbose', me.verbose);

			if me.runNow; run(me); end

		end

		% ===================================================================
		function run(me)
		%> @brief Enters a loop to continuously receive and process commands.
		%> @details This method runs a `while` loop that repeatedly calls
		%>   `receiveCommand(me, false)` to wait for incoming commands without
		%>   sending an automatic 'ok'. Based on the received `command`, it
		%>   performs specific actions (e.g., echo, gettime) and sends an
		%>   appropriate reply using `sendObject`. The loop terminates upon
		%>   receiving an 'exit' or 'quit' command.
		%> @note This is typically used for server-like roles (e.g., REP sockets)
		%>   that need to handle various client requests. Includes short pauses
		%>   using `WaitSecs` to prevent busy-waiting.
		% ===================================================================
			cd(me.paths.parent);
			fprintf('\n\n===> The Conductor V%s is Initiating... ===\n', me.version);
			if exist('conductorData.json','file')
				j = readstruct('conductorData.json');
				me.address = j.address;
				me.port = j.port;
			end
			if me.isRunning; close(me); end
			if ~me.zmq.isOpen; open(me.zmq); end
			createProxy(me);
			handShake(me);
			me.isRunning = true;
			fprintf('\n===> theConductor: Running on %s:%d\n', me.address, me.port);
			% Start the main command processing loop
			process(me);
			fprintf('\n\n===> theConductor: Run finished...\n');
		end

		% ===================================================================
		function createProxy(me)
		%> @brief Create a command proxy with cogmoteGO via HTTP API.
		%> @details This method constructs a HTTP POST request to create a
		%>   command proxy with the cogmoteGO service. It sends the request
		%>   to the specified base URI and path, including the necessary
		%>   headers and body containing the nickname, hostname, and port.
		%>   The method implements a retry mechanism to handle potential
		%>   failures, attempting to resend the request up to a maximum
		%>   number of retries. If the request is successful, it processes
		%>   the response accordingly.
		%> @note Ensure that the cogmoteGO service is running and accessible
		%>   at the specified base URI and path.
		% ===================================================================
			% create the URL for the request
			cmdProxyUrl = me.baseURI;
			cmdProxyUrl.Path = me.basePath;
			
			msg = struct('nickname', 'matlab', 'hostname', 'localhost', "port", me.port);
			msgBody = matlab.net.http.MessageBody(msg);
			request = matlab.net.http.RequestMessage(matlab.net.http.RequestMethod.POST, me.headers, msgBody);
			
			% send request
			maxRetries = 15;
			for retry = 1:maxRetries
				response = me.sendRequest(request, cmdProxyUrl);
				if ~isempty(response)
					me.handleResponse(response);
					break;
				else
					if retry == maxRetries
						error('request failed, reached maximum retry count (%d times)', maxRetries);
					elseif retry > 5
						try 
							if IsLinux
								!systemctl --user restart cogmoteGO
							else
								!cogmoteGO service start
							end
						catch ME
							warning('Failed to restart cogmoteGO service: %s...', ME.message);
						end
					else
						warning('request failed, retrying (%d/%d)', retry, maxRetries);
					end
					WaitSecs(2);
				end
			end
		end

		% ===================================================================
		function closeProxy(me)
		%> @brief Close the command proxy with cogmoteGO via HTTP API.
		%> @details This method constructs a HTTP DELETE request to close
		%>   the command proxy with the cogmoteGO service. It sends the
		%>   request to the specified base URI and path, including the
		%>   necessary headers. The method processes the response to
		%>   determine if the request was successful.
		%> @note Ensure that the cogmoteGO service is running and accessible
		%>   at the specified base URI and path.
		% ===================================================================
			% create the URL for the request
			cmdProxyUrl = me.baseURI;
			cmdProxyUrl.Path = [me.basePath, "matlab"];

			request = matlab.net.http.RequestMessage(matlab.net.http.RequestMethod.DELETE);
			
			% send request
			response = me.sendRequest(request, cmdProxyUrl);
			me.handleResponse(response);
		end
		
		% ===================================================================
		function response = sendRequest(~, request, uri)
		%> @brief Send a HTTP request and return the response.
		%> @param request A `matlab.net.http.RequestMessage` object representing
		%>   the HTTP request to be sent.
		%> @param uri A `matlab.net.URI` object representing the target URI
		%>   for the request.
		%> @return response A `matlab.net.http.ResponseMessage` object containing
		%>   the response from the server, or empty if the request failed.
		%> @details This method sends the provided HTTP request to the specified
		%>   URI using a `matlab.net.http.HTTPOptions` object to configure
		%>   connection and response timeouts. It handles any exceptions that
		%>   may occur during the request and returns the response if successful.
		%> @note Ensure that the target server is accessible and that the
		%>   request is properly formatted.
		% ===================================================================
			opts = matlab.net.http.HTTPOptions;
			opts.ConnectTimeout = 5;
			opts.ResponseTimeout = 10;
			opts.UseProxy = false;
			try
				response = request.send(uri, opts);
			catch exception
				disp("Error: Failed to send request - " + exception.message);
				response = [];
			end
		end
		
		% ===================================================================
		function response = handleResponse(~, response)
		%> @brief Handle the HTTP response based on its status code.
		%> @param response A `matlab.net.http.ResponseMessage` object containing
		%>   the response from the server.
		%> @details This method processes the provided HTTP response by
		%>   checking its status code and displaying appropriate messages or
		%>   warnings based on the code. It handles various status codes such
		%>   as OK, Created, Conflict, BadRequest, and NotFound.
		%> @note Ensure that the response object is valid and contains a
		%>   status code.
		% ===================================================================
			% handle HTTP response based on status code
			if isempty(response)
				return;
			end
			
			switch response.StatusCode
				case matlab.net.http.StatusCode.OK
					disp('===> theConductor: OK')
				case matlab.net.http.StatusCode.Created
					disp('===> theConductor: Command Proxy Created')
				case matlab.net.http.StatusCode.Conflict
					warning("theConductor:endpointExists", "Endpoint already exists");
				case matlab.net.http.StatusCode.BadRequest
					warning("thieConductor:invalidRequest", "Message from cogmoteGO: %s", response.Body.show());
				case matlab.net.http.StatusCode.NotFound
					warning("theConductor:invalidEndpoint", "Endpoint not found");
			end
		end

		% ===================================================================
		function success = handShake(me)
		%> @brief Perform a handshake with the connected client.
		%> @details This method waits for a handshake message from the connected
		%>   client. It expects a JSON-encoded message with a 'request' field
		%>   set to 'Hello'. Upon receiving the correct handshake message, it
		%>   responds with a JSON-encoded message containing a 'response' field
		%>   set to 'World'. The method implements a retry mechanism to handle
		%>   potential failures, continuously attempting to receive and process
		%>   the handshake message until successful.
		%> @note Ensure that the client is properly configured to send the
		%>   expected handshake message.
		% ===================================================================
			fprintf('===> theConductor: Waiting for handshake...\n');
			success = false;
			while ~success
				try
					msgBytes = me.zmq.receive();
					if isempty(msgBytes)
						warning("theConductor:noHandshake", 'No handshake message received');
					end
					msgStr = native2unicode(msgBytes, 'UTF-8');
					try 
						receivedMsg = jsondecode(msgStr);
						fprintf('===> theConductor Received: %s\n', receivedMsg.request); 
					end %#ok<*TRYNC>
					if isstruct(receivedMsg) && strcmpi(receivedMsg.request, 'Hello')
						response = struct('response', 'World');
						responseStr = jsonencode(response);
						responseBytes = unicode2native(responseStr, 'UTF-8');
						me.zmq.send(responseBytes);
						fprintf('===> theConductor Replying: %s\n', 'World'); 
						success = true;
					else
						error("theConductor:invalidHandshake",'Invalid handshake request: %s', msgStr);
					end
				catch exception
					warning(exception.identifier, 'Handshake failed: %s', exception.message);
					rethrow(exception);
				end
			end
		end

		% ===================================================================
		function close(me)
		%> @brief Close the theConductor server and associated resources.
		%> @details This method stops the server by setting the `isRunning`
		%>   property to false. It attempts to close the command proxy with
		%>   `closeProxy(me)` and the ØMQ connection with `close(me.zmq)`.
		%>   Any errors during these operations are caught and ignored to
		%>   ensure that the method completes without interruption.
		%> @note This method should be called to gracefully shut down the
		%>   server and release associated resources.
		% ===================================================================
			me.isRunning = false;
			try closeProxy(me); end
			try close(me.zmq); end
		end
		
		% ===================================================================
		function delete(me)
		%> @brief Destructor for the theConductor class.
		%> @details This method is called when the theConductor object is
		%>   being deleted. It ensures that the server is properly closed
		%>   by calling the `close` method to release resources and
		%>   terminate any ongoing operations.
		%> @note This method is automatically invoked by MATLAB when the
		%>   object is deleted or goes out of scope.
		% ===================================================================
			close(me);
		end
		

	end

	methods (Access = protected)

		% ===================================================================
		function process(me)
		%> @brief Enters a loop to continuously receive and process commands.
		%> @details This method runs a `while` loop that repeatedly calls
		%>   `receiveCommand(me, false)` to wait for incoming commands without
		%>   sending an automatic 'ok'. Based on the received `command`, it
		%>   performs specific actions (e.g., echo, gettime) and sends an
		%>   appropriate reply using `sendObject`. The loop terminates upon
		%>   receiving an 'exit' or 'quit' command.
		%> @note This is typically used for server-like roles (e.g., REP sockets)
		%>   that need to handle various client requests. Includes short pauses
		%>   using `WaitSecs` to prevent busy-waiting.
		% ===================================================================
			stop = false; stopMATLAB = false;
			me.timeStamp = GetSecs;
			sM = screenManager('backgroundColour',[0.12 0.12 0.12], ...
				'disableSyncTests', true, 'hideFlash', true);
			quitKey = KbName('escape');
			RestrictKeysForKbCheck(quitKey);
			Priority(1);
			
			fprintf('\n\n===> theConductor V%s: Starting command receive loop... ===\n\n', me.version);
			while ~stop
				% configure screen hiding
				if me.hideScreen && GetSecs > me.timeStamp + me.screenChangeTime
					open(sM); 
					flip(sM); 
					HideCursor;
				end
				% Call receiveCommand, but tell it NOT to send the default 'ok' reply
				if poll(me.zmq, 'in')
					[cmd, data] = receiveCommand(me.zmq, false);
				else
					WaitSecs('YieldSecs',me.loopTime);
					if KbCheck && sM.isOpen; close(sM); end
					continue
				end

				me.command = cmd;
				me.data = data; %#ok<*PROP>

				if ~isempty(cmd) % Check if receive failed or timed out
					me.recState = true; me.sendState = false;
				else
					me.recState = false;
					WaitSecs('YieldSecs', me.loopTime); % Short pause before trying again
					continue;
				end

				% Command was received successfully (recState is true).
				% Now determine the reply and send it.
				replyCommand = ''; replyData = []; runCommand = false;
				switch lower(cmd)
					case {'exit', 'quit'}
						fprintf('\n===> theConductor:Received exit command. Shutting down loop.\n');
						replyCommand = 'bye';
						replyData = {'Shutting down'};
						stop = true;

					case 'exitmatlab'
						fprintf('\n===> theConductor: Received exit MATLAB command. Shutting down loop.\n');
						replyCommand = 'bye';
						replyData = {'Shutting down MATLAB'};
						stop = true;
						stopMATLAB = true;

					case 'rundemo'
						fprintf('\n===> theConductor: Run PTB demo...\n');
						me.setupPTB();
						data = struct('command','VBLSyncTest','args','none');
						replyCommand = 'demo_run';
						replyData = {"Running VBLSyncTest"}; % Send back the data we received
						runCommand = true;

					case 'status'
						fprintf('\n===> theConductor: Received status command.\n');
						replyCommand = 'Processing';
						replyData = {sprintf('theConductor V%s is processing commands...',me.version)};

					case 'run'
						if isfield(data,'command')
							fprintf('\n===> theConductor: Received run command: %s.\n', data.command);
							replyCommand = 'running_command';
							replyData = {sprintf('Running command %s',data.command)}; % Send back the data we received
							runCommand = true;
						else
							replyCommand = 'cannot_run';
							replyData = "You must send me a struct with a command field";
						end

					case 'getlastrun'
						if exist("~/lastTaskRun.mat","file")
							try
								tmp = load("~/lastTaskRun.mat");
								if isfield(tmp,'dt')
									tmp = tmp.dt;
								end
								fprintf('\n===> theConductor: Received getlastrun command: ok\n');
								replyCommand = 'taskdata';
								replyData = tmp;
							catch ME
								fprintf('\n===> theConductor: Received getlatrun command: no data\n');
								replyCommand = 'notaskdata';
								replyData = struct('Comment','Problem loading lastTaskRun.mat');
							end
						else
							replyCommand = 'notaskdata';
							replyData = struct('Comment','No file: lastTaskRun.mat');
						end

					case 'exittask'
						fprintf('\n===> theConductor: no task is running, cannot exit task loop.\n');
						replyCommand = 'invalid';
						replyData = {'exittask only works when running a behavioural task'};

					case 'echo'
						fprintf('\n===> theConductor: Echoing received data.\n');
						replyCommand = 'echo_reply';
						if isempty(data)
							replyData = {'no data received'};
						else
							replyData = data; % Send back the data we received
						end
						replyData = data; % Send back the data we received

					case 'gettime'
						replyData(1).comment = "theConductor Timing Test";
						replyData.remoteVersion = string(clutil.version);
						replyData.remoteGetSecs = GetSecs;
						if isfield(data,'GetSecs')
							replyData.clientGetSecs = data.GetSecs;
						else
							replyData.clientGetSecs = NaN;
						end
						replyData.GetSecsDiff = replyData.remoteGetSecs - replyData.clientGetSecs;
						replyData.remoteTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
						if isfield(data,'currentTime')
							replyData.clientTime = data.currentTime;
						else
							replyData.clientTime = NaN;
						end
						replyData.timeDiff = replyData.remoteTime - replyData.clientTime;
						fprintf('\n===> theConductor: Replying with current time: %s\n', replyData.remoteTime);
						disp(replyData);
						replyCommand = 'timesync_reply';

					case 'syncbuffer'
						fprintf('\n===> theConductor: Processing syncBuffer command.\n');
						if isfield(data,'frameSize')
							me.zmq.frameSize = data.frameSize;
							replyData = {'buffer synced'};
						else
							replyData = {'you did not pass a frameSize value...'};
						end
						replyCommand = 'syncbuffer_ack';

					case 'hidedesktop'
						me.hideScreen = true;
						try open(sM); flip(sM); end
						fprintf('\n===> theConductor: Hiding desktop screen.\n');
						replyCommand = 'hide-desktop';
						replyData = {'Desktop Hidden'};

					case 'showdesktop'
						me.hideScreen = false;
						me.enableHidden = false;
						try close(sM); ShowCursor; end
						fprintf('\n===> theConductor: Showing desktop screen.\n');
						replyCommand = 'show-desktop';
						replyData = {'Desktop Shown'};

					case 'commandlist'
						% Placeholder for syncBuffer logic
						fprintf('===> theConductor: Processing commandlist command.\n');
						% me.flush(); % Example: maybe flush the input buffer?
						replyCommand = sprintf('theConductor V%s: List of accepted commands',me.version);
						replyData = me.commandList;

					otherwise
						t = sprintf('===> theConductor: Received unknown command: «%s»', cmd);
						disp(t);
						replyCommand = 'unknown-command';
						replyData = {t};
				end

				if poll(me.zmq, 'out', 0.1)
					status = sendCommand(me.zmq, replyCommand, replyData, false);
					if status ~= 0
						warning('\n===> theConductor: Reply failed for command "%s"', cmd);
						me.sendState = false; % Update state on send failure
					else
						%me.sendState = true; me.recState = false; % Update state on send success
					end
				end

				if runCommand && isstruct(data) && isfield(data,'command')
					command = data.command;

					if me.hideScreen && contains(command,{'startTouch','startMatch','startDrag'})
						me.enableHidden = true;
						close(sM);
					end

					try
						tt=tic;
						if isfield(data,'args') && matches(data.args,'none')
							fprintf('\n===> theConductor run: %s\n', command);
							eval(command);
						else
							data.zmq = me.zmq;
							fprintf('\n===> theConductor run: %s\n', [command '(data)']);
							eval([command '(data)']);
						end
						fprintf('===> theConductor run finished in %.3f secs for: %s\n\n', toc(tt), command);
						drawnow;
					catch ME
						warning('===> theConductor: run command failed: %s %s', ME.identifier, ME.message);
					end

					if me.hideScreen && me.enableHidden
						open(sM); flip(sM); HideCursor;
					end
				end
				
			end

			fprintf('\n===> theConductor: Command receive loop finished.\n');
			try close(me); end
			try close(sM); end
			Priority(0); RestrictKeysForKbCheck([]); ShowCursor;
			if stopMATLAB
				fprintf('\n===> theConductor: MATLAB shutdown requested...\n');
				me.zmq = [];
				WaitSecs(0.1);
				quit(0,"force");
			end
		end

		% ===================================================================
		function setupPTB(~)
		%> @brief Setup Psychtoolbox (PTB) preferences.
		%> @details This method configures Psychtoolbox (PTB) preferences
		%>   for optimal performance. It sets the visual debug level to 3,
		%>   skips synchronization tests on macOS and Windows, and performs
		%>   additional configurations for Linux systems, such as setting
		%>   the power profile to 'performance' and disabling display power
		%>   management.
		%> @note Ensure that Psychtoolbox is installed and properly configured
		%>   on the system before calling this method.
		% ===================================================================
			Screen('Preference', 'VisualDebugLevel', 3);
			if ismac || IsWin
				Screen('Preference', 'SkipSyncTests', 2);
			end
			PsychDefaultSetup(2);
			if IsLinux
				try
					[~,b]=system('powerprofilesctl list');
					c = regexpi(b,'performance','match');
					if ~isempty(c); system('powerprofilesctl set performance');end
				end
				try
					system('xset -dpms s off');
				end
			end
		end

	end

end