function shutDownTask(s, sbg, fix, set, target, rtarget, tM, rM, saveName, dt, in, r)
	arguments
		s (1,1) screenManager
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
	
	if ~isempty(sbg); draw(sbg); end
	drawTextNow(s, 'FINISHED!');

	%% final broadcast to cogmoteGO
	r.broadcast.send(struct('task',in.task,'name',in.name,'is_running',false,...
		'loop_id',r.loopN,'trial_id',r.trialN,...
		'correct_rate', r.correctRate,'rewards',dt.data.rewards,...
		'result', r.result, 'reaction_time', r.reactionTime, 'phase', r.phase,...
		'random_rewards',dt.data.random,...
		'start_time',r.startTime,'end_time',r.endTime,...
		'session_id',r.alyxPath,'hostname',r.hostname));

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

	try close(s); end
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
	save(r.saveName, 'dt', 'r', 'in', 'tM', 's', '-v7.3');
	save("~/lastTaskRun.mat", 'dt', '-v7.3');
	disp('Done (and a copy of touch data saved to ~/lastTaskRun.mat)!!!');
	if in.remote == false; try dt.plotData; end; end
	disp(' . '); disp(' . '); disp(' . ');
	WaitSecs('YieldSecs',0.1);

	%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%  Send data to Alyx if enabled
	if in.useAlyx
		in.session.dataBucket = 'Minio-CognitionPlatform';
		in.session.dataRepo = 'http://172.16.102.77:9000';
		[in.session, success] = clutil.initAlyxSession(r, in.session);
		if success
			in.session = clutil.endAlyxSession(r, in.session, "PASS");
		end
	end

end
