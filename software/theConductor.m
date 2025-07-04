% ========================================================================
%> @class theConductor
%> @brief theConductor — ØMQ REP server to run behavioural tasks
%>
%> This class opens a REP ØMQ and uses a HTTP API to open a REC ØMQ with cogmoteGO
%> It can run PTB or other tasks, designed to provide a local server for CageLab.
%> Requires opticka https://github.com/iandol/opticka
%>
%> Copyright ©2025 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef theConductor < optickaCore
	
	properties
		%> run the zmq server immediately?
		runNow = false
		%> IP address
		address = '0.0.0.0'
		%> port to bind to
		port = 6666
		%> time in seconds to wait before polling for new messages?
		loopTime = 0.1
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
		%>
		%> version
		version
		%> commandList
		commandList = ["exit" "quit" "exitmatlab" "rundemo" ...
			"run" "echo" "gettime" "syncbuffer" "commandlist" ...
			"getlastrun" "exittask" "status"]
	end

	properties (Access = private)
		allowedProperties = {'runNow', 'address', 'port', 'verbose'}
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
		%> @brief 
		%> @details 
		%> @note 
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
			% create the URL for the request
			cmdProxyUrl = me.baseURI;
			cmdProxyUrl.Path = me.basePath;
			
			msg = struct('nickname', 'matlab', 'hostname', 'localhost', "port", me.port);
			msgBody = matlab.net.http.MessageBody(msg);
			request = matlab.net.http.RequestMessage(matlab.net.http.RequestMethod.POST, me.headers, msgBody);
			
			% send request
			maxRetries = 5;
			for retry = 1:maxRetries
				response = me.sendRequest(request, cmdProxyUrl);
				if ~isempty(response)
					me.handleResponse(response);
					break;
				else
					if retry == maxRetries
						error('request failed, reached maximum retry count (%d times)', maxRetries);
					else
						warning('request failed, retrying (%d/%d)', retry, maxRetries);
					end

				end
			end
		end

		% ===================================================================
		function closeProxy(me)
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
						fprintf('===> theConductor Received:\n%s\n', receivedMsg.request); 
					end %#ok<*TRYNC>
					if isstruct(receivedMsg) && strcmpi(receivedMsg.request, 'Hello')
						response = struct('response', 'World');
						responseStr = jsonencode(response);
						responseBytes = unicode2native(responseStr, 'UTF-8');
						fprintf('===> theConductor Replying:\n%s\n', 'World'); 
						me.zmq.send(responseBytes);
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
			me.isRunning = false;
			try closeProxy(me); end
			try close(me.zmq); end
		end
		
		% ===================================================================
		function delete(me)
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
			fprintf('\n\n===> theConductor V%s: Starting command receive loop... ===\n\n', me.version);
			while ~stop
				% Call receiveCommand, but tell it NOT to send the default 'ok' reply
				if poll(me.zmq, 'in')
					[cmd, data] = receiveCommand(me.zmq, false);
				else
					WaitSecs('YieldSecs',me.loopTime);
					KbCheck;
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
						replyData(1).comment = "PTB GetSecs and datetime";
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
						if me.verbose > 0; fprintf('\n===> theConductor: Replying with current time: %s\n', replyData.remoteTime); end
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
				end
				
			end

			fprintf('\n===> theConductor: Command receive loop finished.\n');
			close(me);
			if stopMATLAB
				fprintf('\n===> theConductor: MATLAB shutdown requested...\n');
				me.zmq = [];
				WaitSecs(0.1);
				quit(0,"force");
			end
		end

		% ===================================================================
		function setupPTB(~)
			Screen('Preference', 'VisualDebugLevel', 3);
			if ismac || IsWin
				Screen('Preference', 'SkipSyncTests', 2);
			end
			PsychDefaultSetup(2);
			if IsLinux
				!powerprofilesctl set performance
			end
		end

	end

end