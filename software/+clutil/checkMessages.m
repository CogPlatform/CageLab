function [in, keepRunning] = checkMessages(in)
% check if a command was sent from control system
	if isstruct(in) && isfield(in,'zmq') && isa(in.zmq,'jzmqConnection') && poll(in.zmq, 'in')
		[cmd, dat] = receiveCommand(in.zmq, false);
		if ischar(cmd); cmd = string(cmd); end
		fprintf('\n---> checkMessages: received command:\n');
		disp(cmd);
		if ~isempty(dat) && isstruct(dat) && isfield(dat,'timeStamp')
			fprintf('---> Command sent %.1f secs ago\n',GetSecs-dat.timeStamp);
		end
		replyCommand = 'unknown';
		replyData = {''};
		if ~isempty(cmd) 
			if (isstring(cmd) && matches(cmd,'exittask')) || (isfield(cmd,'command') && matches(cmd.command,'exittask'))
				fprintf('---> Exit task Triggered...\n\n');
				keepRunning = false; 
				in.keepRunning = keepRunning;
				replyCommand = 'exittask_reply';
				replyData = {'ok'};
			end
			if (isstring(cmd) && matches(cmd,'getlastrun')) || (isfield(cmd,'command') && matches(cmd.command,'getlastrun'))
				if exist("~/ongoingTaskRun.mat","file")
					try
						tmp = load("~/ongoingTaskRun.mat");
						if isfield(tmp,'dt')
							tmp = tmp.dt;
						end
						fprintf('\n===> Received getlastrun command: ok\n');
						replyCommand = 'taskdata';
						replyData = tmp;
					catch ME
						fprintf('\n===> Received getlatrun command: no data\n');
						replyCommand = 'notaskdata';
						replyData = struct('Comment','Problem loading lastTaskRun.mat');
					end
				else
					replyCommand = 'notaskdata';
					replyData = struct('Comment','No file: lastTaskRun.mat');
				end
			end
		end
		if poll(in.zmq, 'out', 0.1)
			status = sendCommand(in.zmq, replyCommand, replyData, false);
			if status ~= 0
				warning('\n===> Reply failed for command "%s"', cmd);
			end
		end
	end
end