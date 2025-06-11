function [dt, r] = updateTrialResult(in, dt, r, rtarget, sbg, s, tM, rM, a)		
	
	if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
	vblEnd = flip(s);
	tM.flush;
	WaitSecs(0.05);

	%% lets check the result:
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
	elseif r.anyTouch == false
		WaitSecs(0.5+rand);
	elseif r.result == 1

		if in.reward; giveReward(rM, in.rewardTime); end
		beep(a, in.correctBeep, 0.1, in.audioVolume);
		animateRewardTarget(1);

		update(dt, true, r.phase, r.trialN, vblEnd - r.vblInit, r.stimulus,'correct',[],[],r.value);
		
		dt.data.rewards = dt.data.rewards + 1;
		
		r.phaseN = r.phaseN + 1;
		r.trialW = 0;
		
		if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end; flip(s);
		WaitSecs(0.1);
		r.randomRewardTimer = GetSecs;

	elseif r.result == 0

		drawBackground(s,[1 0 0]);
		if in.debug; drawText(s,['FAIL! phase: ' num2str(r.phase)]); end
		flip(s);
		beep(a, in.incorrectBeep, 0.5, in.audioVolume);

		update(dt, false, r.phase, r.trialN, vblEnd - r.vblInit, r.stimulus,'incorrect',[],[],r.value);
		
		r.phaseN = r.phaseN + 1;
		r.trialW = r.trialW + 1;

		fprintf('===> FAIL :-(\n');
		
		WaitSecs('YieldSecs',in.timeOut);
		if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end; flip(s);
		r.randomRewardTimer = GetSecs;

	else

		if in.debug; drawText(s,'UNKNOWN!'); end
		if ~isempty(sbg); draw(sbg); end
		flip(s);

		update(dt, false, r.phase, r.trialN, vblEnd - r.vblInit, r.stimulus,'unknown',[],[],r.value);
		
		r.phaseN = r.phaseN + 1;
		r.trialW = r.trialW + 1;

		fprintf('===> UNKNOWN :-|\n');

		WaitSecs('YieldSecs',in.timeOut);
		if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end; flip(s);
		r.randomRewardTimer = GetSecs;
	end

	if matches(in.task, 'train') && r.trialW > 4
		r.phase = r.phase - 1;
		r.trialW = 0;
		if r.phase < 1; r.phase = 1; end
		if r.phase > 20; r.phase = 20; end
		if matches(in.taskType, 'Simple') && r.phase > 9; r.phase = 9; end
		fprintf('===> Step Back Phase update: %i\n',r.phase);
	elseif matches(in.task, 'train') && r.trialN >= in.stepForward
		if length(dt.data.result) >= in.stepForward
			r.res = sum(dt.data.result(end - (in.stepForward-1):end)) / in.stepForward;
		else 
			r.res = [];
		end
		fprintf('===> Performance: %i @ Phase: %i\n', r.res, r.phase);
		if r.phaseN >= in.stepForward && length(dt.data.result) > in.stepForward
			if ~isempty(r.res) && r.res >= 0.8
				r.phase = r.phase + 1;
			elseif ~isempty(r.res) && r.res <= 0.2
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

	%% finalise this trial
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

	r.broadcast.send(struct('task',in.task,'name',in.name,'trial',r.trialN,'loop',r.loopN,...
		'rewards', dt.data.rewards, 'random',dt.data.random, 'result',r.result));

	function animateRewardTarget(time)
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
			draw(rtarget);
			flip(s);
			rtarget.alphaOut = rtarget.alphaOut + 0.1;
			if rtarget.alphaOut > 1; rtarget.alphaOut = 1; end
		end
		if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
		flip(s);
	end

end