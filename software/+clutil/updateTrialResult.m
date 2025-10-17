function [dt, r] = updateTrialResult(in, dt, r, rtarget, sbg, sM, tM, rM, a)
	
	%% ================================ blank display
	if ~isempty(sbg); draw(sbg); else; drawBackground(sM,in.bg); end
	vblEnd = flip(sM);
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
			if ~isempty(sbg); draw(sbg); else; drawBackground(sM,in.bg); end
			flip(sM);
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
			drawText(sM,'TIMEOUT!');
			flip(sM);
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
		[r.correctRateRecent, r.correctRate] = getCorrectRate();
		r.txt = getResultsText();

		animateRewardTarget(1);

		fprintf('===> CORRECT :-) %s\n',r.txt);
		
		r.phaseN = r.phaseN + 1;
		r.trialW = 0;
		
		if ~isempty(sbg); draw(sbg); else; drawBackground(sM,in.bg); end
		flip(sM);
		WaitSecs(0.1);
		r.randomRewardTimer = GetSecs;

	%% ================================ incorrect
	elseif r.result == 0
		r.summary = 'incorrect';
		update(dt, false, r.phase, r.trialN, r.reactionTime, r.stimulus,...
			r.summary, tM.xAll, tM.yAll, tM.tAll-tM.queueTime, r.value);
		r.correctRate = getCorrectRate();
		r.txt = getResultsText();

		drawBackground(sM,[1 0 0]);
		if in.debug; drawText(sM,r.txt); end
		flip(sM);
		beep(a, in.incorrectBeep, 0.5, in.audioVolume);
		
		r.phaseN = r.phaseN + 1;
		r.trialW = r.trialW + 1;

		fprintf('===> FAIL :-( %s\n',r.txt);
		
		WaitSecs('YieldSecs',in.timeOut);
		if ~isempty(sbg); draw(sbg); else; drawBackground(sM,in.bg); end; flip(sM);
		r.randomRewardTimer = GetSecs;

	%% ================================ otherwise
	else
		r.summary = 'unknown';
		update(dt, false, r.phase, r.trialN, r.reactionTime, r.stimulus,...
			r.summary, tM.xAll, tM.yAll, tM.tAll-tM.queueTime, r.value);
		r.correctRate = getCorrectRate();
		r.txt = getResultsText();

		if in.debug; drawText(sM,r.txt); end
		if ~isempty(sbg); draw(sbg); end
		flip(sM);
		
		r.phaseN = r.phaseN + 1;
		r.trialW = r.trialW + 1; 

		fprintf('===> UNKNOWN :-| %s\n',r.txt);

		WaitSecs('YieldSecs',in.timeOut);
		if ~isempty(sbg); draw(sbg); else; drawBackground(sM,in.bg); end; flip(sM);
		r.randomRewardTimer = GetSecs;
	end

	%% ================================ logic for training starcase
	r.phaseMax = max(r.phaseMax, r.phase);
	if matches(in.task, 'train') && r.trialN >= in.stepForward
		fprintf('===> Performance: %.1f @ Phase: %i\n', r.correctRate, r.phase);
		if r.phaseN >= in.stepForward && length(dt.data.result) > in.stepForward
			if r.correctRate >= in.stepPercent
				r.phase = r.phase + 1;
			elseif r.correctRate <= in.stepBackPercent
				r.phase = r.phase - 1;
			end
			if r.phase < (r.phaseMax - in.phaseMaxBack)
				r.phase = r.phaseMax - in.phaseMaxBack; 
			end
			r.phaseN = 0;
			r.trialW = 0;
			if r.phase < 1; r.phase = 1; end
			if r.phase > 36; r.phase = 36; end
			if matches(in.task, 'Simple') && r.phase > 19; r.phase = 19; end
			fprintf('===> Step Phase update: %i\n',r.phase);
		end
	end

	%% ================================ finalise this trial
	if dt.data.rewards > in.totalRewards; r.keepRunning = false; end
	if r.keepRunning == false; return; end
	drawBackground(sM,in.bg)
	if ~isempty(sbg); draw(sbg); end
	flip(sM);
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

	%% broadcast the trial to cogmoteGO
	clutil.broadcastTrial(in, r, dt, true);

	%% save copy of data every 5 trials just in case of crash
	if mod(r.trialN, 5)
		disp('=========================================');
		fprintf('===> Saving data to %s\n', r.saveName)
		disp('=========================================');
		save(r.saveName, 'dt', 'r', 'in', 'tM', '-v7.3');
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function txt = getResultsText()
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		txt = sprintf('Loop=%i Trial=%i CorrectRate=%.1f Rewards=%i Random=%i Result=%i',r.loopN,r.trialN,r.correctRate,dt.data.rewards,dt.data.random,r.result);
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function [recent,overall] = getCorrectRate()
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		overall = length(find(dt.data.result == 1)) / length(dt.data.result);
		if length(dt.data.result) >= in.stepForward
			recent = dt.data.result(end - (in.stepForward-1):end);
			recent = length(find(recent == 1)) / length(recent);
		else 
			recent = NaN;
		end
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	function animateRewardTarget(time)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		frames = round(time * sM.screenVals.fps);
		rtarget.mvRect = r.rRect;
		rtarget.angleOut = 0;
		rtarget.alphaOut = 0;
		for i = 0:frames
			inc = sin(i*0.25)/2;
			rtarget.angleOut = rtarget.angleOut + (inc * 5);
			%rect = ScaleRect(rtarget.mvRect, inc, inc);
			%rtarget.mvRect = CenterRect(rect,s.screenVals.winRect);
			if ~isempty(sbg); draw(sbg); else; drawBackground(sM,in.bg); end
			if in.debug && ~isempty(r.txt); drawText(sM,r.txt); end
			draw(rtarget);
			flip(sM);
			rtarget.alphaOut = rtarget.alphaOut + 0.02;
			if rtarget.alphaOut > 0.5; rtarget.alphaOut = 0.5; end
		end
		if ~isempty(sbg); draw(sbg); else; drawBackground(sM,in.bg); end
		flip(sM);
	end

end
