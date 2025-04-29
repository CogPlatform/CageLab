function startMatchToSample(tr)
	pth = fileparts(which(mfilename));
	if ~exist('tr','var')
		tr.phase = 1;
		tr.density = 70;
		tr.distance = 30;
		tr.timeOut = 4;
		tr.bg = [0.5 0.5 0.5];
		tr.maxSize = 30;
		tr.minSize = 1;
		tr.folder = [pth filesep 'images'];
		tr.fg = [1 1 0.75];
		tr.debug = true;
		tr.dummy = true;
		tr.audio = true;
		tr.audioVolume = 0.2;
		tr.stimulus = 'Picture';
		tr.task = 'Normal';
		tr.name = 'simulcra';
		tr.rewardmode = 1;
		tr.volume = 250;
		tr.random = 1;
		tr.screen = 0;
		tr.smartBackground = true;
		tr.correctBeep = 3000;
		tr.incorrectBeep = 400;
		tr.rewardPort = '/dev/ttyACM0';
		tr.rewardTime = 200;
		tr.trialTime = 5;
		tr.randomReward = 30;
		tr.randomProbability = 0.25;
		tr.nTrialsSample = 10;
	end
	pixelsPerCm = tr.density;
	distance = tr.distance;
	windowed = [];
	sf = [];

	% =========================== debug mode?
	if max(Screen('Screens'))==0 && tr.debug; sf = kPsychGUIWindow; windowed = [0 0 1300 800]; end
	
	try
		% ============================screen
		s = screenManager('screen',tr.screen,'blend',true,'pixelsPerCm',pixelsPerCm, 'distance', distance,...
		'backgroundColour',tr.bg,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		pedestal = discStimulus('size', 6,'colour',[1 1 0],'alpha',0.3);
		rtarget = imageStimulus('size', 5, 'colour', [0 1 0], 'filePath', 'star.png');
		target1 = imageStimulus('size', 5, 'randomiseSelection', true, 'filePath', [tr.folder filesep 'fractals' filesep 'B']);
		target2 = clone(target1);
		distractor1 = clone(target1);
		distractor1.filePath = [tr.folder filesep 'fractals' filesep 'C'];
		distractor2 = clone(target1);
		distractor2.filePath = [tr.folder filesep 'fractals' filesep 'D'];
		distractor3 = clone(target1);
		distractor3.filePath = [tr.folder filesep 'fractals' filesep 'E'];
		distractor4 = clone(target1);
		distractor4.filePath = [tr.folder filesep 'fractals' filesep 'H'];
		set = metaStimulus('stimuli',{pedestal, target1, target2, distractor1, distractor2, distractor3, distractor4});
		
		if tr.smartBackground
			sbg = imageStimulus('alpha', 1, 'filePath', [tr.folder filesep 'background' filesep 'abstract3.jpg']);
		else 
			sbg = [];
		end

		% ============================audio
		a = audioManager;
		if tr.debug; a.verbose = true; end
		if tr.audioVolume == 0 || tr.audio == false; a.silentMode = true; end
		setup(a);
		beep(a,tr.correctBeep,0.1,tr.audioVolume);
		WaitSecs(0.1);
		beep(a,tr.incorrectBeep,0.5,tr.audioVolume);

		% ============================touch
		t = touchManager('isDummy',tr.dummy);
		t.window.doNegation = true;
		t.window.negationBuffer = 1.5;
		t.drainEvents = true;
		if tr.debug; t.verbose = true; end

		% ============================reward
		rM = arduinoManager;
		rM.port = tr.rewardPort;
		rM.silentMode = true;
		rM.reward.type = 'TTL';
		rM.reward.pin = 2;
		rM.reward.time = tr.rewardTime; % 250ms
		if tr.debug; rM.verbose = true; end
		try open(rM); end %#ok<*TRYNC>
		
		% ============================setup
		sv = open(s);
		if ~isempty(sbg); setup(sbg, s); draw(sbg); end
		drawTextNow(s,'Initialising...');
		setup(set, s);
		setup(rtarget, s); rRect = rtarget.mvRect;
		setup(t, s);
		createQueue(t);
		start(t);

		% ==============================save file name
		svn = initialiseSaveFile(s);
		mkdir([s.paths.savedData filesep tr.name]);
		saveName = [ s.paths.savedData filesep tr.name filesep 'MTS-' tr.name '-' svn '.mat'];
		dt = touchData;
		dt.name = saveName;
		dt.subject = tr.name;
		dt.data.random = 0;
		dt.data.rewards = 0;
		dt.data.tr = tr;

		% ============================settings
		quitKey = KbName('escape');
		RestrictKeysForKbCheck([quitKey]);
		Screen('Preference','Verbosity',4);
		
		if ~tr.debug && ~tr.dummy; Priority(1); HideCursor; end
		keepRunning = true;
		trialN = 0;
		phaseN = 1;
		randomRewardTimer = GetSecs;

		while keepRunning

			set.fixationChoice = 3;
			[~,idx] = Shuffle([1 2 3 4 5]);
			xy = [-9 -4.5 0 4.5 9; 6 5 6 5 6];
			xy = xy(:,idx);
			set{1}.xPositionOut = 0;
			set{1}.yPositionOut = sv.topInDegrees + 5/3;
			set{2}.xPositionOut = 0;
			set{2}.yPositionOut = sv.topInDegrees + 5/3;
			set{3}.xPositionOut = xy(1,1);
			set{3}.yPositionOut = xy(2,1);
			set{4}.xPositionOut = xy(1,2);
			set{4}.yPositionOut = xy(2,2);
			set{5}.xPositionOut = xy(1,3);
			set{5}.yPositionOut = xy(2,3);
			set{6}.xPositionOut = xy(1,4);
			set{6}.yPositionOut = xy(2,4);
			set{7}.xPositionOut = xy(1,5);
			set{7}.yPositionOut = xy(2,5);
			hide(set);
			show(set,[1 2 3 4 5 6 7]);
			update(set);

			N = target1.nImages;
			r = randi(N); stimulus = r;
			target1.selectionOut = r;
			target2.selectionOut = r;
			rr = [r];
			for jj = 4:7
				r = randi(N);
				while any(r == rr)
					r = randi(N);
				end
				set{jj}.selectionOut = r;
				rr = [rr r];
			end

			[x,y] = set.getFixationPositions;
			t.window.radius = target2.size/2;
			t.window.init = tr.trialTime;
			t.window.release = 1;
			t.window.X = x;
			t.window.Y = y;

			res = 0; phase = 1;
			keepRunning = true;
			touchResponse = '';
			anyTouch = false;
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			
			fprintf('\n===> START TRIAL: %i \n', trialN);
			fprintf('===> Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', t.window.radius,t.window.init,t.window.hold,t.window.release);

			if trialN == 1; dt.data.startTime = GetSecs; end
			
			WaitSecs(0.01);
			reset(t);
			flush(t);
			
			if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
			vbl = flip(s); vblInit = vbl;
			while isempty(touchResponse) && vbl < vblInit + tr.trialTime
				if ~isempty(sbg); draw(sbg); end
				if ~hldtime; draw(set); end
				if tr.debug && ~isempty(t.x) && ~isempty(t.y)
					drawText(s, txt);
					[xy] = s.toPixels([t.x t.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchResponse, hld, hldtime, rel, reli, se, fail, tch] = testHoldRelease(t,'yes','no');
				if tch
					anyTouch = true;
				end
				txt = sprintf('Phase=%i Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i %.1f Init: %.2f Hold: %.2f Release: %.2f',...
					phase,touchResponse,t.x,t.y,hld, hldtime, rel, reli, se,...
					t.window.radius,t.window.init,t.window.hold,t.window.release);
				[~,~,c] = KbCheck();
				if c(quitKey); keepRunning = false; break; end
			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
			vblEnd = flip(s);
			WaitSecs(0.05);

			% lets check the result:
			if anyTouch == false
				tt = vblEnd - randomRewardTimer;
				if (phase <= 6) && (tr.randomReward > 0) && (tt >= tr.randomReward) && (rand > (1-tr.randomProbability))
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
					giveReward(rM);
					dt.data.rewards = dt.data.rewards + 1;
					dt.data.random = dt.data.random + 1;
					fprintf('===> RANDOM REWARD :-)\n');
					beep(a,2000,0.1,0.1);
					WaitSecs(0.75+rand);
					randomRewardTimer = GetSecs;
				else
					fprintf('===> TIMEOUT :-)\n');
					if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
					drawText(s,'TIMEOUT!');
					flip(s);
					WaitSecs(0.75+rand);
				end
			elseif strcmp(touchResponse,'yes')
				giveReward(rM);
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,tr.correctBeep,0.1,tr.audioVolume);
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
				beep(a,tr.incorrectBeep,0.5,tr.audioVolume);
				WaitSecs(tr.timeOut);
				randomRewardTimer = GetSecs;
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
				WaitSecs(0.5+rand);
				randomRewardTimer = GetSecs;
			end

			if trialN >= tr.nTrialsSample
				if length(dt.data.result) > tr.nTrialsSample
					res = sum(dt.data.result(end - (tr.nTrialsSample-1):end));
				end
				fprintf('===> Performance: %i Phase: %i\n',res,phase);
				if phaseN >= tr.nTrialsSample && length(dt.data.result) > tr.nTrialsSample
					if res >= 8
						phase = phase + 1;
					elseif res <= 2
						phase = phase - 1;
					end
					phaseN = 0;
					if phase < 1; phase = 1; end
					if phase > 20; phase = 20; end
					if matches(tr.task, 'Simple') && phase > 9; phase = 9; end
					fprintf('===> Phase update: %i\n',phase);
				end
			end

			if keepRunning == false; break; end
			if ~isempty(sbg); draw(sbg); end
			flip(s);
		end % while keepRunning

		drawText(s, 'FINISHED!');
		flip(s);

		try ListenChar(0); Priority(0); ShowCursor; end
		try reset(set); end
		try reset(rtarget); end
		try close(s); end
		try close(t); end
		try close(rM); end

		% save trial data
		disp('');
		disp('=========================================');
		fprintf('===> Data for %s\n',saveName)
		disp('=========================================');
		tVol = (9.38e-4 * tr.volume) * dt.data.rewards;
		fVol = (9.38e-4 * tr.volume) * dt.data.random;
		cor = sum(dt.data.result==true);
		incor = sum(dt.data.result==false);
		fprintf('  Total Trials: %i\n',trialN);
		fprintf('  Correct Trials: %i\n',cor);
		fprintf('  Incorrect Trials: %i\n',cor);
		fprintf('  Free Rewards: %i\n',dt.data.random);
		fprintf('  Correct Volume: %.2f ml\n',tVol);
		fprintf('  Free Volume: %i ml\n\n\n',fVol);
		%try dt.plot(dt); end

		% save trial data
		disp('=========================================');
		fprintf('===> Saving data to %s\n',saveName)
		disp('=========================================');
		save('-v7', saveName, 'dt');
		disp('Done!!!');
		disp('');disp('');disp('');
		WaitSecs(0.5);
		sca;

	catch ME
		getReport(ME)
		try reset(set); end
		try close(s); end
		try close(t); end
		try close(rM); end
		try close(a); end
		try Priority(0); end
		try ListenChar(0); end
		try ShowCursor; end
		sca;
	end

end
