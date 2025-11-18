function [in, keepRunning] = checkMessages(in)
% check if a command was sent from control system
	if isstruct(in) && isfield(in,'zmq') && isa(in.zmq,'jzmqConnection') && in.zmq.poll('in')
		[cmd, dat] = in.zmq.receiveCommand();
		if ischar(cmd); cmd = string(cmd); end
		fprintf('\n---> Update trial result: received command:\n');
		disp(cmd);
		if ~isempty(dat) && isstruct(dat) && isfield(dat,'timeStamp')
			fprintf('---> Command sent %.1f secs ago\n',GetSecs-dat.timeStamp);
		end
		if ~isempty(cmd) 
			if (isstring(cmd) && matches(cmd,'exittask')) || (isfield(cmd,'command') && matches(cmd.command,'exittask'))
				fprintf('---> Exit task Triggered...\n\n');
				keepRunning = false; 
				in.keepRunning = keepRunning;
			end
		end
	end
end