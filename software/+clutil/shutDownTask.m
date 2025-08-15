function shutDownTask(s, sbg, fix, set, target, rtarget, tM, rM, saveName, dt, in, r)
	
	if ~isempty(sbg); draw(sbg); end
	drawTextNow(s, 'FINISHED!');

	%% final broadcast
	r.broadcast.send(struct('task',in.task,'name',in.name,'isRunning',false,'loop',r.loopN,'trial',r.trialN,...
		'phase', r.phase, 'result', r.result, 'reactionTime', r.reactionTime,...
		'correctRate', r.correctRate,'rewards', dt.data.rewards,'randomRewards',dt.data.random,...
		'hostname',r.hostname));

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
		disp('=========================================');
		fprintf('===> Data for %s\n', saveName)
		disp('=========================================');
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
	fprintf('===> Saving data to %s\n', saveName)
	disp('=========================================');
	dt.info.runInfo = r;
	dt.info.settings = in;
	save('-v7', saveName, 'dt', 'r', 'in', 'tM', 's');
	save('-v7', "~/lastTaskRun.mat", 'dt');
	disp('Done (and a copy of touch data saved to ~/lastTaskRun.mat)!!!');
	if in.remote == false; try dt.plotData; end; end
	disp(' . '); disp(' . '); disp(' . ');
	WaitSecs('YieldSecs',0.1);
end
