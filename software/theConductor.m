% ========================================================================
%> @class theConductor
%> @brief theConductor — ØMQ REP server to run behavioural tasks
%>
%> This class opens a REP ØMQ
%>
%> Copyright ©2014-2025 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef theConductor < optickaCore
	
	properties
		%> run the zmq server immediately?
		runNow = false
		%> IP address
		address = '0.0.0.0'
		%> port to bind to
		port = 6666
		%>
		verbose = true
	end

	properties (GetAccess = public, SetAccess = protected)
		%> ØMQ jzmqConnection object
		zmq
		%> command
		command
		%> data
		data
		%> task object
		runner
		%>
		commandList = ["exit" "quit" "exitmatlab" "rundemo" ...
			"run" "echo" "gettime" "syncbuffer" "commandlist"]
	end

	properties (Access = private)
		allowedProperties = {'runNow', 'address', 'port', 'verbose'}
		sendState = false
		recState = false
	end

	properties (Constant)
		baseURI = matlab.net.URI('http://localhost:9012');
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

			try setupPTB(me); end

			me.zmq = jzmqConnection('type', 'REP', 'address', me.address,'port', me.port, 'verbose', me.verbose);

			if me.runNow; run(me); end

		end

		function delete(me)
			close(me);
		end
		function close(me)
			try closeProxy(me); end
			try close(me.zmq); end
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
			fprintf('=== The Conductor is Running... ===\n');
			if exist('conductorData.json','file')
				j = readstruct('conductorData.json');
				me.address = j.address;
				me.port = j.port;
			end
			if ~me.zmq.isOpen; open(me.zmq); end
			createProxy(me);
			handShake(me);
			process(me);
			fprintf('Run finished...\n');
			
		end

		function createProxy(me)
			% create the URL for the request
			cmdProxyUrl = me.baseURI;
			cmdProxyUrl.Path = {"cmds", "proxies"};
			
			msg = struct('nickname', 'matlab', 'hostname', 'localhost', "port", me.port);
			msgBody = matlab.net.http.MessageBody(msg);
			request = matlab.net.http.RequestMessage(matlab.net.http.RequestMethod.POST, me.headers, msgBody);
			
			% send request
			response = me.sendRequest(request, cmdProxyUrl);
			me.handleResponse(response);
		end

		function closeProxy(me)
			% create the URL for the request
			cmdProxyUrl = me.baseURI;
			cmdProxyUrl.Path = {"cmds", "proxies", "matlab"};

			request = matlab.net.http.RequestMessage(matlab.net.http.RequestMethod.DELETE);
			
			% send request
			response = me.sendRequest(request, cmdProxyUrl);
			me.handleResponse(response);
		end
		
		function response = sendRequest(~, request, uri)
			try
				response = request.send(uri);
			catch exception
				disp("Error: Failed to send request - " + exception.message);
				response = [];
			end
		end
		
		function response = handleResponse(~, response)
			% handle HTTP response based on status code
			if isempty(response)
				return;
			end
			
			switch response.StatusCode
				case matlab.net.http.StatusCode.Conflict
					warning("MatmoteGo:endpointExists", "Endpoint already exists");
				case matlab.net.http.StatusCode.BadRequest
					warning("MatmoteGo:invalidRequest", "Message from cogmoteGO: %s", response.Body.show());
				case matlab.net.http.StatusCode.NotFound
					warning("MatmoteGo:invalidEndpoint", "Endpoint not found");
			end
		end

		function handShake(me)
			try
				msgBytes = me.zmq.socket.recv();
				
				if isempty(msgBytes)
					warning('No handshake message received');
				end
				
				msgStr = native2unicode(msgBytes, 'UTF-8');
				receivedMsg = jsondecode(msgStr);
				try fprintf('Received: %s\n', receivedMsg.request); end
				
				if strcmp(receivedMsg.request, 'Hello')
					response = struct('response', 'World');
					responseStr = jsonencode(response);
					responseBytes = unicode2native(responseStr, 'UTF-8');
					me.socket.send(responseBytes);
				else
					warning('Invalid handshake request: %s', msgStr);
				end

			catch exception
				warning(exception.identifier, 'Handshake failed: %s', exception.message);
				rethrow(exception);
			end
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
			fprintf('\n\n=== Starting command receive loop... ===\n\n');
			while ~stop
				% Call receiveCommand, but tell it NOT to send the default 'ok' reply
				if poll(me.zmq, 'in')
					[cmd, data] = receiveCommand(me.zmq, false);
				else
					WaitSecs('YieldSecs',0.005);
					continue
				end

				me.command = cmd;
				me.data = data; %#ok<*PROP>

				if ~isempty(cmd) % Check if receive failed or timed out
					me.recState = true; me.sendState = false;
				else
					me.recState = false;
					WaitSecs('YieldSecs', 0.005); % Short pause before trying again
					continue;
				end

				% Command was received successfully (recState is true).
				% Now determine the reply and send it.
				replyCommand = ''; replyData = []; runCommand = false;
				switch lower(cmd)
					case {'exit', 'quit'}
						fprintf('Received exit command. Shutting down loop.\n');
						replyCommand = 'bye';
						replyData = {'Shutting down'};
						stop = true;

					case 'exitmatlab'
						fprintf('Received exit MATLAB command. Shutting down loop.\n');
						replyCommand = 'bye';
						replyData = {'Shutting down MATLAB'};
						stop = true;
						stopMATLAB = true;

					case 'rundemo'
						if me.verbose > 0; fprintf('Run PTB demo...\n'); end
						setupPTB();
						data = struct('command','VBLSyncTest','args','none');
						replyCommand = 'demo_run';
						replyData = "Running VBLSyncTest"; % Send back the data we received
						runCommand = true;

					case 'run'
						if isfield(data,'command')
							replyCommand = 'running';
							replyData = {''}; % Send back the data we received
							runCommand = true;
						else
							replyCommand = 'cannot run';
							replyData = "You must pass a struct with a command field";
						end

					case 'echo'
						if me.verbose > 0; fprintf('Echoing received data.\n'); end
						replyCommand = 'echo_reply';
						replyData = data; % Send back the data we received

					case 'gettime'
						replyData(1).GetSecs = GetSecs;
						replyData(1).currentTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
						if isfield(data,'currentTime')
							replyData.clientTime = data.currentTime;
						else
							replyData.clientTime = NaN;
						end
						replyDate.timeDiff = replyData.currentTime - replyData.clientTime;
						if isfield(data,'GetSecs')
							replyData.clientGetSecs = data.GetSecs;
						else
							replyData.clientGetSecs = NaN;
						end
						replyData.GetSecsDiff = replyData.GetSecs - replyData.clientGetSecs;
						if me.verbose > 0; fprintf('Replying with current time: %s\n', replyData.currentTime); end
						replyCommand = 'time_reply';

					case 'syncbuffer'
						% Placeholder for syncBuffer logic
						if me.verbose > 0; fprintf('Processing syncBuffer command.\n'); end
						% me.flush(); % Example: maybe flush the input buffer?
						if isfield(data,'frameSize')
							me.zmq.frameSize = data.frameSize;
							replyData = {'buffer synced'};
						else
							replyData = {'you did not pass a frameSize value...'};
						end
						replyCommand = 'syncbuffer_ack';

					case 'commandlist'
						% Placeholder for syncBuffer logic
						if me.verbose > 0; fprintf('Processing syncBuffer command (placeholder).\n'); end
						% me.flush(); % Example: maybe flush the input buffer?
						replyCommand = 'list of accepted commands';
						replyData = me.commandList;

					otherwise
						t = sprintf('Received unknown command: «%s»', cmd);
						disp(t);
						replyCommand = 'unknown-command';
						replyData = {t};
				end

				if matches(me.zmq.poll,'out')
					status = sendCommand(me.zmq, replyCommand, replyData, false);
					if status ~= 0
						warning('Reply failed for command "%s"', cmd);
						me.sendState = false; % Update state on send failure
					else
						me.sendState = true; me.recState = false; % Update state on send success
					end
				end

				if runCommand
					if isstruct(data) && isfield(data,'command')
						data.zmq = me.zmq;
						command = data.command;
						try
							if isfield(data,'args') && matches(data.args,'none')
								eval(command);
							else
								eval([command '(data)']);
							end
						catch ME
							warning('run command failed');
						end
					end
				end

				% Small pause to prevent busy-waiting if no commands arrive quickly
				if ~stop
					WaitSecs('YieldSecs', 0.005);
				end
			end
			fprintf('Command receive loop finished.\n');
			me.zmq.close;
			closeProxy(me);
			if stopMATLAB
				me.zmq = [];
				WaitSecs(0.01);
				quit(0,"force");
			end
		end

		% ===================================================================
		function setupPTB(me)
			Screen('Preference', 'VisualDebugLevel', 3);
			if ismac || IsWin
				Screen('Preference', 'SkipSyncTests', 2);
			end
			if IsLinux
				!powerprofilesctl set performance
			end
			PsychDefaultSetup(2);
		end

	end

end