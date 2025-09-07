function [dt, r] = updateTrialResult(in, dt, r, rtarget, sbg, s, tM, rM, a)
	
	%% ================================ blank display
	if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
	vblEnd = flip(s);
	WaitSecs('YieldSecs',0.02);

	%% ================================ register some times if subject touched
	if r.anyTouch && r.trialN > 0
		dt.data.times.taskStart(r.trialN) = r.vblInit;
		dt.data.times.taskEnd(r.trialN) = r.vblFinal;
		dt.data.times.taskRT(r.trialN) = r.reactionTime;
		dt.data.times.firstTouch(r.trialN) = r.firstTouchTime;
	end

	% lets check the results:

	%% ================================ no touch and first training phases, give some random rewards
	if r.anyTouch == false && matches(in.task, 'train') && r.phase <= 4
		tt = vblEnd - r.randomRewardTimer;
		if in.randomReward > 0 && (tt >= in.randomReward) && (rand > (1-in.randomProbability))
			WaitSecs(rand/2);
			animateRewardTarget(0.33);
			if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
			flip(s);
			giveReward(rM, in.rewardTime);
			dt.data.rewards = dt.data.rewards + 1;
			dt.data.random = dt.data.random + 1;
			fprintf('===> RANDOM REWARD :-)\n');
			beep(a,in.correctBeep,0.1,in.audioVolume);
			WaitSecs(0.75+rand);
			r.randomRewardTimer = GetSecs;
		else
			fprintf('===> TIMEOUT :-)\n');
			if ~isempty(sbg); draw(sbg); end
			drawText(s,'TIMEOUT!');
			flip(s);
			WaitSecs(0.75+rand);
		end

	%% ================================ no touch, just wait a bit
	elseif r.anyTouch == false
		WaitSecs(0.5+rand);

	%% ================================ correct
	elseif r.result == 1
		r.summary = 'correct';
		if in.reward
			giveReward(rM, in.rewardTime);
			dt.data.rewards = dt.data.rewards + 1;
		end
		beep(a, in.correctBeep, 0.1, in.audioVolume);
		update(dt, true, r.phase, r.trialN, r.reactionTime, r.stimulus,...
			r.summary, tM.xAll, tM.yAll, tM.tAll-tM.queueTime, r.value);
		r.correctRate = getCorrectRate();
		r.txt = getResultsText();

		animateRewardTarget(1);

		fprintf('===> CORRECT :-) %s\n',r.txt);
		
		r.phaseN = r.phaseN + 1;
		r.trialW = 0;
		
		if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
		flip(s);
		WaitSecs(0.1);
		r.randomRewardTimer = GetSecs;

	%% ================================ incorrect
	elseif r.result == 0
		r.summary = 'incorrect';
		update(dt, false, r.phase, r.trialN, r.reactionTime, r.stimulus,...
			r.summary, tM.xAll, tM.yAll, tM.tAll-tM.queueTime, r.value);
		r.correctRate = getCorrectRate();
		r.txt = getResultsText();

		drawBackground(s,[1 0 0]);
		if in.debug; drawText(s,r.txt); end
		flip(s);
		beep(a, in.incorrectBeep, 0.5, in.audioVolume);
		
		r.phaseN = r.phaseN + 1;
		r.trialW = r.trialW + 1;

		fprintf('===> FAIL :-( %s\n',r.txt);
		
		WaitSecs('YieldSecs',in.timeOut);
		if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end; flip(s);
		r.randomRewardTimer = GetSecs;

	%% ================================ otherwise
	else
		r.summary = 'unknown';
		update(dt, false, r.phase, r.trialN, r.reactionTime, r.stimulus,...
			r.summary, tM.xAll, tM.yAll, tM.tAll-tM.queueTime, r.value);
		r.correctRate = getCorrectRate();
		r.txt = getResultsText();

		if in.debug; drawText(s,r.txt); end
		if ~isempty(sbg); draw(sbg); end
		flip(s);
		
		r.phaseN = r.phaseN + 1;
		r.trialW = r.trialW + 1;

		fprintf('===> UNKNOWN :-| %s\n',r.txt);

		WaitSecs('YieldSecs',in.timeOut);
		if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end; flip(s);
		r.randomRewardTimer = GetSecs;
	end

	%% ================================ logic for training starcase
	if matches(in.task, 'train') && r.trialW >= in.stepBack
		r.phase = r.phase - 1;
		r.trialW = 0;
		r.phaseN = 0;
		if r.phase < 1; r.phase = 1; end
		if r.phase > 20; r.phase = 20; end
		if matches(in.taskType, 'Simple') && r.phase > 9; r.phase = 9; end
		fprintf('===> Step Back Phase update: %i\n',r.phase);
	elseif matches(in.task, 'train') && r.trialN >= in.stepForward
		fprintf('===> Performance: %.1f @ Phase: %i\n', r.correctRate, r.phase);
		if r.phaseN >= in.stepForward && length(dt.data.result) > in.stepForward
			if r.correctRate >= in.stepPercent
				r.phase = r.phase + 1;
			elseif r.correctRate <= 0.2
				r.phase = r.phase - 1;
			end
			r.phaseN = 0;
			r.trialW = 0;
			if r.phase < 1; r.phase = 1; end
			if r.phase > 20; r.phase = 20; end
			if matches(in.task, 'Simple') && r.phase > 9; r.phase = 9; end
			fprintf('===> Step Forward Phase update: %i\n',r.phase);
		end
	end

	%% ================================ finalise this trial
	if r.keepRunning == false; return; end
	drawBackground(s,in.bg)
	if ~isempty(sbg); draw(sbg); end
	flip(s);
	if ~isempty(r.zmq) && r.zmq.poll('in')
		[cmd, dat] = r.zmq.receiveCommand();
		if ischar(cmd); cmd = string(cmd); end
		fprintf('\n---> Update trial result: received command:\n');
		disp(cmd);
		if ~isempty(dat) && isstruct(dat) && isfield(dat,'timeStamp')
			fprintf('---> Command sent %.1f secs ago\n',GetSecs-dat.timeStamp);
		end
		if ~isempty(cmd) 
			if (isstring(cmd) && matches(cmd,'exittask')) || (isfield(cmd,'command') && matches(cmd.command,'exittask'))
				fprintf('---> Exit task Triggered...\n\n');
				r.keepRunning = false; return;
			end
		end
	end

	%% =============================== broadcast the data to cogmoteGO
	r.broadcast.send(struct('task',in.task,'name',in.name,'isRunning',true,'loop',r.loopN,'trial',r.trialN,...
		'phase', r.phase, 'result', r.result, 'reactionTime', r.reactionTime,...
		'correctRate', r.correctRate,'rewards', dt.data.rewards,'randomRewards',dt.data.random,...
		'sessionID',r.alyxPath,'hostname',r.hostname));

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function txt = getResultsText()
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		txt = sprintf('Loop=%i Trial=%i CorrectRate=%.1f Rewards=%i Random=%i Result=%i',r.loopN,r.trialN,r.correctRate,dt.data.rewards,dt.data.random,r.result);
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function cr = getCorrectRate()
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		if length(dt.data.result) >= in.stepForward
			cr = dt.data.result(end - (in.stepForward-1):end);
			cr = length(find(cr == 1)) / length(cr);
		else 
			cr = NaN;
		end
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function animateRewardTarget(time)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		frames = round(time * s.screenVals.fps);
		rtarget.mvRect = r.rRect;
		rtarget.angleOut = 0;
		rtarget.alphaOut = 0;
		for i = 0:frames
			inc = sin(i*0.25)/2;
			rtarget.angleOut = rtarget.angleOut + (inc * 5);
			%rect = ScaleRect(rtarget.mvRect, inc, inc);
			%rtarget.mvRect = CenterRect(rect,s.screenVals.winRect);
			if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
			if in.debug && ~isempty(r.txt); drawText(s,r.txt); end
			draw(rtarget);
			flip(s);
			rtarget.alphaOut = rtarget.alphaOut + 0.1;
			if rtarget.alphaOut > 1; rtarget.alphaOut = 1; end
		end
		if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
		flip(s);
	end

end