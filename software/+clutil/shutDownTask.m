function shutDownTask(sM, sbg, fix, set, target, rtarget, tM, rM, saveName, dt, in, r)
	arguments
		sM (1,1) screenManager
		sbg % can be [] or imageStimulus; leave untyped to allow empty
		fix (1,1) discStimulus
		set % typically metaStimulus; may be []
		target % [] or imageStimulus
		rtarget (1,1) imageStimulus
		tM (1,1) touchManager
		rM (1,1) PTBSimia.pumpManager
		saveName (1,:) char
		dt (1,1) touchData
		in struct
		r struct
	end
	
	%% final drawing
	if ~isempty(sbg); draw(sbg); end
	drawTextNow(sM, 'FINISHED!');

	%% change status for cogmoteGO
	currentStatus = r.status.updateStatusToStopped();

	%% reset and close stims and devices
	try ListenChar(0); Priority(0); ShowCursor; end %#ok<*TRYNC>
	try touchManager.enableTouchDevice(tM.deviceName, "disable"); end
	if exist('sbg','var') && ~isempty(sbg); try reset(sbg); end; end
	if exist('fix','var') && ~isempty(fix); try reset(fix); end; end
	if exist('set','var') && ~isempty(set); try reset(set); end; end
	if exist('target','var') && ~isempty(target); try reset(target); end; end
	if exist('rtarget','var') && ~isempty(rtarget); try reset(rtarget); end; end
	
	in.zmq = [];
	r.zmq = [];
	r.broadcast = [];

	try close(sM); end
	try close(tM); end
	try close(rM); end

	%% show some basic results
	try
		disp('');
		disp('==================================================');
		fprintf('===> Data for %s\n', saveName)
		disp('==================================================');
		tVol = (9.38e-4 * in.rewardTime) * dt.data.rewards;
		fVol = (9.38e-4 * in.rewardTime) * dt.data.random;
		cor = sum(dt.data.result==1);
		incor = sum(dt.data.result~=1);
		fprintf('  Total Loops: %i\n', r.loopN);
		fprintf('  Total Trials: %i\n', r.trialN);
		fprintf('  Correct Trials: %i\n', cor);
		fprintf('  Incorrect Trials: %i\n', incor);
		fprintf('  Free Rewards: %i\n', dt.data.random);
		fprintf('  Correct Volume: %.2f ml\n', tVol);
		fprintf('  Free Volume: %i ml\n\n\n', fVol);
	end
	
	%% save trial data
	disp('=========================================');
	fprintf('===> Saving data to %s\n', r.saveName)
	disp('=========================================');
	dt.info.runInfo = r;
	dt.info.settings = in;
	save(r.saveName, 'dt', 'r', 'in', 'tM', 'sM', '-v7.3');
	save("~/lastTaskRun.mat", 'dt', '-v7.3');
	disp('Done (and a copy of touch data saved to ~/lastTaskRun.mat)!!!');
	if in.remote == false; try dt.plotData; end; end
	disp(' . '); disp(' . '); disp(' . ');
	WaitSecs('YieldSecs',0.1);
	writelines("Session ended: " + string(datetime('now')), "~/cagelab-start.txt", WriteMode="append");

	%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%  Send data to Alyx if enabled
	err = "";
	if in.useAlyx
		if in.initAlyxAtStart
			success = isfield(in.session,'initialised') && in.session.initialised;
		else
			[in.session, success] = clutil.initAlyxSession(r, in.session);
		end
		if success
			[in.session, err] = clutil.endAlyxSession(r, in.session, "PASS");
		else
			err = "Could not initialize Alyx session.";
		end
	end


	%% final broadcast to cogmoteGO
	clutil.broadcastTrial(in, r, dt, false);

	%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% wrap up
	diary off
	r.comments(end+1) = "Shut down task.";
	if err ~= ""
		r.comments(end+1) = "Alyx Error: " + err;
		writelines(["Alyx Error: " + err, " "], "~/cagelab-start.txt", WriteMode="append");
		error(err);
	end

	try system('xset s 300 dpms 600 0 0'); end
end
