function [dt, r] = updateTrialResult(in, dt, r, rtarget, sbg, s, tM, rM, a)		
	
	if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
	vblEnd = flip(s);
	tM.flush;
	WaitSecs(0.05);

	%% lets check the result:
	if r.anyTouch == false && matches(in.task, 'train') && r.phase <= 5
		tt = vblEnd - r.randomRewardTimer;
		if in.randomReward > 0 && (tt >= in.randomReward) && (rand > (1-in.randomProbability))
			WaitSecs(rand/2);
			for i = 0:round(s.screenVals.fps/3)
				if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
				draw(rtarget);
				flip(s);
				inc = sin(i*0.2)/2 + 1;
				if inc <=0; inc =0.01; end
				rtarget.angleOut = rtarget.angleOut+0.5;
				rtarget.mvRect = ScaleRect(rRect, inc, inc);
				rtarget.mvRect = CenterRect(rtarget.mvRect,s.screenVals.winRect);
			end
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
		disp(r);
		update(dt, true, r.phase, r.trialN, vblEnd - r.vblInit, r.stimulus,'correct',[],[],r.value);
		if in.reward; giveReward(rM, 500); end
		dt.data.rewards = dt.data.rewards + 1;
		fprintf('===> CORRECT :-)\n');
		beep(a, in.correctBeep, 0.1, in.audioVolume);
		r.phaseN = r.phaseN + 1;
		r.trialW = 0;
		if ~isempty(sbg); draw(sbg); end
		drawText(s,['CORRECT! phase: ' num2str(r.phase)]);
		flip(s);
		r.broadcast.send(struct('task',in.task,'name',in.name,'trial',r.trialN,'result',r.result));
		WaitSecs(0.5+rand);
		r.randomRewardTimer = GetSecs;
	elseif r.result == 0
		update(dt, false, r.phase, r.trialN, vblEnd - r.vblInit, r.stimulus,'incorrect',[],[],r.value);
		r.phaseN = r.phaseN + 1;
		r.trialW = r.trialW + 1;
		fprintf('===> FAIL :-(\n');
		drawBackground(s,[1 0 0]);
		drawText(s,['FAIL! phase: ' num2str(r.phase)]);
		flip(s);
		beep(a, in.incorrectBeep, 0.5, in.audioVolume);
		r.broadcast.send(struct('task',in.task,'name',in.name,'trial',r.trialN,'result',r.result));
		WaitSecs('YieldSecs',in.timeOut);
		r.randomRewardTimer = GetSecs;
	else
		update(dt, false, r.phase, r.trialN, vblEnd - r.vblInit, r.stimulus,'unknown',[],[],r.value);
		r.phaseN = r.phaseN + 1;
		r.trialW = r.trialW + 1;
		fprintf('===> UNKNOWN :-|\n');
		drawText(s,'UNKNOWN!');
		if ~isempty(sbg); draw(sbg); end
		flip(s);
		r.broadcast.send(struct('task',in.task,'name',in.name,'trial',r.trialN,'result',r.result));
		WaitSecs('YieldSecs',in.timeOut);
		r.randomRewardTimer = GetSecs;
	end

	if matches(in.task, 'train') && r.trialW > 4
		r.phase = r.phase - 1;
		r.trialW = 0;
		if r.phase < 1; r.phase = 1; end
		if r.phase > 20; r.phase = 20; end
		if matches(in.task, 'Simple') && r.phase > 9; r.phase = 9; end
		fprintf('===> Phase update: %i\n',r.phase);
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
			fprintf('===> Phase update: %i\n',r.phase);
		end
	end

	%% finalise this trial
	if r.keepRunning == false; return; end
	drawBackground(s,in.bg)
	if ~isempty(sbg); draw(sbg); end
	flip(s);
	if ~isempty(r.zmq) && r.zmq.poll('in')
		[cmd, ~] = r.zmq.receiveCommand();
		if ~isempty(cmd) && isstruct(cmd)
			fprintf('\n---> update trial result: received command:\n');
			disp(cmd);
			if isfield(msg,'command') && matches(msg.command,'exittask')
				r.keepRunning = false; return;
			end
		end
	end

end