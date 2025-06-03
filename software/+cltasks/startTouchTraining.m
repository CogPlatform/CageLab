function startTouchTraining(in)
	if ~exist('in','var') || isempty(in); in = clutil.checkInput(pth); end
	bgName = 'abstract1.jpg';
	prefix = 'TT';
	zmq = in.zmq;
	broadcast = matmoteGO.broadcast();
	
	try
		%% ============================subfunction for shared initialisation
		[s, sv, sbg, rtarget, fix, a, rM, tM, dt, quitKey] = clutil.initialise(in, bgName, prefix);

		%% ============================task specific figures
		if matches(in.stimulus, 'Picture')
			target = imageStimulus('size', in.maxSize, 'filePath', [in.folder filesep 'flowers'], 'crop', 'square', 'circularMask', true);
		else
			target = discStimulus('size', in.maxSize, 'colour', in.fg);
		end
		if in.debug; target.verbose = true; end

		%% ============================ custom stimuli setup
		setup(target, s);

		%% ============================ run variables
		keepRunning = true;
		trialN = 0;
		phaseN = 0;
		phase = in.phase;
		stimulus = 1;
		randomRewardTimer = GetSecs;
		rRect = rtarget.mvRect;

		%% ============================steps table
		sz = linspace(in.maxSize, in.minSize, 5);
		if matches(in.task, 'Simple') % simple task
			if in.phase > 9; in.phase = 9; end
			pn = 1; p = [];
			%size
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			% position
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 3; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 5; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 7; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 11;
		else
			pn = 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			% 6
			p(pn).size = sz(end); p(pn).hold = 0.1;   p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.2;   p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.4;   p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.8;   p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 1;     p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			% 12
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 2; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.75; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.5; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.25; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = [0 0]; pn = pn + 1;
			% 17
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 3; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 5; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 7; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 11;
		end

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while keepRunning
			if phase > length(p); phase = length(p); end
			if length(p(phase).pos) == 2
				x = p(phase).pos(1);
				y = p(phase).pos(2);
			else
				x = randi(p(phase).pos(1));
				if rand > 0.5; x = -x; end
				y = randi(p(phase).pos(1));
				y = y / aspect;
				if rand > 0.5; y = -y; end
			end
			if length(p(phase).hold) == 2
				tM.window.hold = randi(p(phase).hold .* 1e3) / 1e3;
			else
				tM.window.hold = p(phase).hold(1);
			end
			if isa(target,'imageStimulus') && target.circularMask == false
				tM.window.radius = [p(phase).size/2 p(phase).size/2];
			else
				tM.window.radius = p(phase).size / 2;
			end
			tM.window.init = in.trialTime;
			tM.window.release = p(phase).rel;
			tM.window.X = x;
			tM.window.Y = y;

			target.xPositionOut = x;
			target.yPositionOut = y;
			target.sizeOut = p(phase).size;
			if isa(target,'imageStimulus')
				target.selectionOut = randi(target.nImages);
				stimulus = target.selectionOut;
			end
			update(target);

			res = 0;
			keepRunning = true;
			touchResponse = '';
			anyTouch = false;
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			
			fprintf('\n===> START TRIAL: %i - PHASE %i STIM %i\n', trialN, phase, stimulus);
			fprintf('===> Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', tM.window.radius,tM.window.init,tM.window.hold,tM.window.release);

			if trialN == 1; dt.data.startTime = GetSecs; end
			
			WaitSecs(0.01);
			reset(tM);
			flush(tM);
			
			if ~isempty(sbg); draw(sbg); end
			vbl = flip(s); vblInit = vbl;
			while isempty(touchResponse) && vbl < vblInit + in.trialTime
				if ~isempty(sbg); draw(sbg); end
				if ~hldtime; draw(target); end
				if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
					drawText(s, txt);
					[xy] = s.toPixels([tM.x tM.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchResponse, hld, hldtime, rel, reli, se, fail, tch] = testHoldRelease(tM,'yes','no');
				if tch
					anyTouch = true;
				end
				txt = sprintf('Phase=%i Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i %.1f Init: %.2f Hold: %.2f Release: %.2f',...
					phase,touchResponse,tM.x,tM.y,hld, hldtime, rel, reli, se,...
					tM.window.radius,tM.window.init,tM.window.hold,tM.window.release);
				[~,~,c] = KbCheck();
				if c(quitKey); keepRunning = false; break; end
			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
			vblEnd = flip(s);
			WaitSecs(0.05);

			%% lets check the result:
			if anyTouch == false
				tt = vblEnd - randomRewardTimer;
				if (phase <= 6) && (in.randomReward > 0) && (tt >= in.randomReward) && (rand > (1-in.randomProbability))
					if ~isempty(sbg); draw(sbg); end
					WaitSecs(rand/2);
					for i = 0:round(s.screenVals.fps/3)
						draw(rtarget);
						flip(s);
						inc = sin(i*0.2)/2 + 1;
						if inc <=0; inc =0.01; end
						rtarget.angleOut = rtarget.angleOut+0.5;
						rtarget.mvRect = ScaleRect(rRect, inc, inc);
						rtarget.mvRect = CenterRect(rtarget.mvRect,s.screenVals.winRect);
					end
					flip(s);
					giveReward(rM, in.rewardTime);
					dt.data.rewards = dt.data.rewards + 1;
					dt.data.random = dt.data.random + 1;
					fprintf('===> RANDOM REWARD :-)\n');
					beep(a,in.correctBeep,0.1,in.audioVolume);
					WaitSecs(0.75+rand);
					randomRewardTimer = GetSecs;
				else
					fprintf('===> TIMEOUT :-)\n');
					if ~isempty(sbg); draw(sbg); end
					drawText(s,'TIMEOUT!');
					flip(s);
					WaitSecs(0.75+rand);
				end
			elseif strcmp(touchResponse,'yes')
				if in.reward; giveReward(rM); end
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,in.correctBeep,0.1,in.audioVolume);
				update(dt, true, phase, trialN, vblEnd-vblInit, stimulus);
				phaseN = phaseN + 1;
				if ~isempty(sbg); draw(sbg); end
				drawText(s,['CORRECT! phase: ' num2str(phase)]);
				flip(s);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs(0.5+rand);
				randomRewardTimer = GetSecs;
			elseif strcmp(touchResponse,'no')
				update(dt, false, phase, trialN, vblEnd-vblInit, stimulus);
				phaseN = phaseN + 1;
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,['FAIL! phase: ' num2str(phase)]);
				flip(s);
				beep(a,in.incorrectBeep,0.5,in.audioVolume);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs('YieldSecs',in.timeOut);
				randomRewardTimer = GetSecs;
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs(0.5+rand);
				randomRewardTimer = GetSecs;
			end

			broadcast.send(struct('name',in.name,'trial',trialN,'result',dt.data.result));

			if trialN >= in.nTrialsSample
				if length(dt.data.result) > in.nTrialsSample
					res = sum(dt.data.result(end - (in.nTrialsSample-1):end));
				end
				fprintf('===> Performance: %i Phase: %i\n',res,phase);
				if phaseN >= in.nTrialsSample && length(dt.data.result) > in.nTrialsSample
					if res >= 8
						phase = phase + 1;
					elseif res <= 2
						phase = phase - 1;
					end
					phaseN = 0;
					if phase < 1; phase = 1; end
					if phase > 20; phase = 20; end
					if matches(in.task, 'Simple') && phase > 9; phase = 9; end
					fprintf('===> Phase update: %i\n',phase);
				end
			end

			%% finalise this trial
			if keepRunning == false; break; end
			drawBackground(s,in.bg)
			if ~isempty(sbg); draw(sbg); end
			flip(s);
			if ~isempty(zmq) && zmq.poll('in')
				[cmd, ~] = zmq.receiveCommand();
				if ~isempty(cmd) && isstruct(cmd)
					if isfield(msg,'command') && matches(msg.command,'exittask')
						break;
					end
				end
			end
		end % while keepRunning

		clutil.shutDownTask(s, sbg, fix, set, target1, target2, tM, rM, saveName, dt, in, trialN);

	catch ME
		getReport(ME)
		try reset(target); end
		try close(s); end
		try close(tM); end
		try close(rM); end
		try close(a); end
		try Priority(0); end
		try ListenChar(0); end
		try ShowCursor; end
		sca;
	end
end
