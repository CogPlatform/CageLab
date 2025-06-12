function shutDownTask(s, sbg, fix, set, target, rtarget, tM, rM, saveName, dt, in, r)
	%V1.04
	if ~isempty(sbg); draw(sbg); end
	drawTextNow(s, 'FINISHED!');
	try ListenChar(0); Priority(0); ShowCursor; end %#ok<*TRYNC>
	try touchManager.xinput(tM.deviceName, false); end
	if exist('sbg','var') && ~isempty(sbg); try reset(sbg); end; end
	if exist('fix','var'); try reset(fix); end; end
	if exist('set','var'); try reset(set); end; end
	if exist('target','var'); try reset(target); end; end
	if exist('rtarget','var'); try reset(rtarget); end; end
	try close(s); end
	try close(tM); end
	try close(rM); end
	% save trial data
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
	% save trial data
	disp('=========================================');
	fprintf('===> Saving data to %s\n', saveName)
	disp('=========================================');
	dt.info.runInfo = r;
	save('-v7', saveName, 'dt');
	save('-v7', "~/lastTaskRun.mat", 'dt');
	disp('Done (and a copy saved to ~/lastTaskRun.mat)!!!');
	disp(''); disp(''); disp('');
	if in.remote == false; dt.plotData; end
	WaitSecs(0.5);
end
