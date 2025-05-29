function startTouchTraining(in)
	pth = fileparts(which(mfilename));
	checkInput()
	windowed = [];
	sf = [];
	zmq = in.zmq;
	broadcast = matmoteGO.broadcast();
	
	% =========================== debug mode?
	if max(Screen('Screens'))==0 && in.debug; sf = kPsychGUIWindow; windowed = [0 0 1600 800]; end
	
	try
		% ============================screen
		s = screenManager('screen',in.screen,'blend',true,'pixelsPerCm',...
			in.density, 'distance', in.distance,...
			'backgroundColour',in.bg,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		rtarget = imageStimulus('size', 5, 'colour', [0 1 0], 'filePath', 'star.png');
		if matches(in.stimulus, 'Picture')
			target = imageStimulus('size', in.maxSize, 'filePath', [in.folder filesep 'flowers'], 'crop', 'square', 'circularMask', true);
		else
			target = discStimulus('size', in.maxSize, 'colour', in.fg);
		end
		if in.debug; target.verbose = true; end
		if in.smartBackground
			sbg = imageStimulus('alpha', 1, 'filePath', [in.folder filesep 'background' filesep 'abstract2.jpg']);
		else 
			sbg = [];
		end

		% ============================audio
		a = audioManager;
		if in.debug; a.verbose = true; end
		if in.audioVolume == 0 || in.audio == false; a.silentMode = true; end
		setup(a);
		beep(a,in.correctBeep,0.1,in.audioVolume);
		WaitSecs(0.1);
		beep(a,in.incorrectBeep,0.2,in.audioVolume);

		% ============================touch
		tM = touchManager('isDummy',in.dummy,'device',in.touchDevice,...
			'deviceName',in.touchDeviceName,'exclusionZone',in.exclusionZone,...
			'drainEvents',in.drainEvents);
		tM.window.doNegation = in.doNegation;
		tM.window.negationBuffer = in.negationBuffer;
		if in.debug; tM.verbose = true; end

		% ============================reward
		if in.reward; rM = PTBSimia.pumpManager(); end

		% ============================steps table
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

		% ============================setup
		sv = open(s);
		drawTextNow(s,'Initialising...');
		if in.smartBackground
			sbg.size = max([sv.widthInDegrees sv.heightInDegrees]);
			setup(sbg, s);
		end
		aspect = sv.width / sv.height;
		setup(rtarget, s);
		setup(target, s);
		setup(tM, s);
		createQueue(tM);
		start(tM);

		% ==============================save file name
		[path, sessionID, dateID, name] = s.getALF(in.name, in.lab, true);
		saveName = [ path filesep 'TouchT-' name '.mat'];
		dt = touchData;
		dt.name = saveName;
		dt.subject = in.name;
		dt.data.random = 0;
		dt.data.rewards = 0;
		dt.data.in = in;

		% ============================settings
		quitKey = KbName('escape');
		RestrictKeysForKbCheck([quitKey]);
		Screen('Preference','Verbosity',4);
		
		if ~in.debug && ~in.dummy; Priority(1); HideCursor; end
		keepRunning = true;
		trialN = 0;
		phaseN = 0;
		phase = in.phase;
		stimulus = 1;
		randomRewardTimer = GetSecs;
		rRect = rtarget.mvRect;

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

			% lets check the result:
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
					beep(a,2000,0.1,0.1);
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
				beep(a,2000,0.1,0.1);
				update(dt, true, phase, trialN, vblEnd-vblInit, stimulus);
				phaseN = phaseN + 1;
				if ~isempty(sbg); draw(sbg); end
				drawText(s,['CORRECT! phase: ' num2str(phase)]);
				flip(s);
				WaitSecs(0.5+rand);
				randomRewardTimer = GetSecs;
			elseif strcmp(touchResponse,'no')
				update(dt, false, phase, trialN, vblEnd-vblInit, stimulus);
				phaseN = phaseN + 1;
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,['FAIL! phase: ' num2str(phase)]);
				flip(s);
				beep(a,250,0.3,0.8);
				WaitSecs('YieldSecs',in.timeOut);
				randomRewardTimer = GetSecs;
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
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

			if keepRunning == false; break; end
			drawBackground(s,in.bg)
			if ~isempty(sbg); draw(sbg); end
			flip(s);
			if zmq.poll('in')
				[cmd, ~] = zmq.receiveCommand();
				if ~isempty(cmd) && isstruct(cmd)
					if isfield(msg,'command') && matches(msg.command,'exittask')
						break;
					end
				end
			end
		end % while keepRunning

		shutDownTask();

	catch ME
		getReport(ME)
		try reset(target); end
		try close(s); end
		try close(tM); end
		try close(rM); end
		try close(a); end
		try Priority(0); end
		try ListenChar(0); end
		sca;
	end

	function checkInput()
		%V1.0
		if ~exist('in','var')
			in.phase = 1;
			in.density = 70;
			in.distance = 30;
			in.timeOut = 4;
			in.bg = [0.5 0.5 0.5];
			in.maxSize = 30;
			in.minSize = 1;
			in.folder = [pth filesep 'resources'];
			in.fg = [1 1 0.75];
			in.debug = true;
			in.dummy = true;
			in.audio = true;
			in.audioVolume = 0.2;
			in.stimulus = 'Picture';
			in.task = 'generic';
			in.name = 'simulcra';
			in.rewardmode = 1;
			in.volume = 250;
			in.random = 1;
			in.screen = 0;
			in.smartBackground = true;
			in.correctBeep = 3000;
			in.incorrectBeep = 400;
			in.rewardPort = '/dev/ttyACM0';
			in.rewardTime = 200;
			in.trialTime = 5;
			in.randomReward = 30;
			in.randomProbability = 0.25;
			in.randomReward = 0;
			in.volume = 250;
			in.nTrialsSample = 10;
			in.negationBuffer = 2;
			in.exclusionZone = [];
			in.drainEvents = true;
			in.strictMode = true;
			in.negateTouch = true;
			in.touchDevice = 1;
			in.touchDeviceName = 'ILITEK-TP';
			in.initPosition = [0 4];
			in.initSize = 4;
			in.target1Pos = [-5 -5];
			in.target2Pos = [5 -5];
			in.targetSize = 10;
		end
	end

	function shutDownTask()
		%V1.04
		drawText(s, 'FINISHED!');
		flip(s);
		try ListenChar(0); Priority(0); ShowCursor; end
		if exist('sbg','var') && ~isempty(sbg); try reset(sbg); end;end %#ok<*TRYNC>
		if exist('fix','var'); try reset(fix); end; end
		if exist('set','var'); try reset(set); end; end
		if exist('target','var'); try reset(target); end; end
		if exist('rtarget','var'); try reset(rtarget); end; end
		if exist('set','var'); try reset(set); end; end
		try close(s); end
		try close(tM); end
		try close(rM); end
		try touchManager.xinput(tM.deviceName, false); end
		% save trial data
		disp('');
		disp('=========================================');
		fprintf('===> Data for %s\n',saveName)
		disp('=========================================');
		tVol = (9.38e-4 * in.rewardTime) * dt.data.rewards;
		fVol = (9.38e-4 * in.rewardTime) * dt.data.random;
		cor = sum(dt.data.result==true);
		incor = sum(dt.data.result==false);
		fprintf('  Total Trials: %i\n',trialN);
		fprintf('  Correct Trials: %i\n',cor);
		fprintf('  Incorrect Trials: %i\n',incor);
		fprintf('  Free Rewards: %i\n',dt.data.random);
		fprintf('  Correct Volume: %.2f ml\n',tVol);
		fprintf('  Free Volume: %i ml\n\n\n',fVol);
		% save trial data
		disp('=========================================');
		fprintf('===> Saving data to %s\n',saveName)
		disp('=========================================');
		save('-v7', saveName, 'dt');
		save('-v7', "~/lastTaskRun.mat", 'dt');
		disp('Done!!!');
		disp('');disp('');disp('');
		WaitSecs(0.5);
	end

end
