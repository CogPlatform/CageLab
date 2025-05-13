function startDragCategorisation(tr)
	pth = fileparts(which(mfilename));
	if ~exist('tr','var')
		tr.phase = 1;
		tr.density = 70;
		tr.distance = 30;
		tr.timeOut = 4;
		tr.bg = [0.5 0.5 0.5];
		tr.maxSize = 35;
		tr.minSize = 3;
		tr.folder = [pth filesep 'resources'];
		tr.fg = [1 1 0.75];
		tr.debug = true;
		tr.dummy = true;
		tr.audio = true;
		tr.audioVolume = 0.9;
		tr.stimulus = 'Picture';
		tr.task = 'Normal';
		tr.name = 'simulcra';
		tr.lab = 'cogp';
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
	tr.fg = [1 0.7 0.3];
	tr.trialTime = 4;
	tr.phase = 1;
	tr.nTrialsSample = 10;
	% =========================== debug mode?
	if max(Screen('Screens'))==0 && tr.debug; sf = kPsychGUIWindow; windowed = [0 0 1600 800]; end
	
	try
		% ============================screen
		s = screenManager('screen',tr.screen,'blend',true,'pixelsPerCm',pixelsPerCm, 'distance', distance,...
		'backgroundColour', tr.bg,'windowed', windowed,'specialFlags', sf);

		% s============================stimuli
		rtarget = imageStimulus('size', 5, 'colour', [0 1 0], 'filePath', 'star.png');
		startPoint = discStimulus('size', 6, 'colour', tr.fg,...
			'xPosition',-3,'yPosition',3);

		object = imageStimulus('name','object', 'size', 10, 'filePath', ...
			[tr.folder filesep 'flowers'],'crop', 'square', 'circularMask', false,...
			'xPosition',-3,'yPosition',3);
		target1 = clone(object);
		target1.name = 'target1';
		target2 = clone(object);
		target2.name = 'target2';

		set = metaStimulus('stimuli',{startPoint, object, target1, target2});
		
		if tr.debug; target.verbose = true; end
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
		beep(a,tr.incorrectBeep,0.2,tr.audioVolume);

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
		drawTextNow(s,'Initialising...');
		aspect = sv.width / sv.height;
		setup(rtarget, s);
		setup(set, s);
		if ~isempty(sbg); setup(sbg, s); end
		setup(t, s);
		createQueue(t);
		start(t);

		% ==============================save file name
		[path, sessionID, dateID, name] = s.getALF(tr.name, tr.lab, true);
		saveName = [ path filesep 'DragCat-' name '.mat'];
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
		phaseN = 0;
		phase = 1;
		stimulus = 1;
		randomRewardTimer = GetSecs;
		rRect = rtarget.mvRect;


		while keepRunning
			
			[~,idx] = Shuffle([1 2]);
			xy = [-7 7; -5 -5];
			
			target1.updateXY(xy(1,idx(1)),xy(2,idx(1)), true);
			target2.updateXY(xy(1,idx(2)),xy(2,idx(2)), true);

			hide(set);
			show(set,1);

			update(set);
			
			% touch window
			t.window.init = tr.trialTime;
			t.window.hold = 0.15;
			t.window.release = 5;
			t.window.X = startPoint.xFinalD;
			t.window.Y = startPoint.yFinalD;

			res = 0;
			keepRunning = true;
			touchInit = '';
			touchResponse = '';
			anyTouch = false;
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			
			fprintf('\n===> START TRIAL: %i - STIM\n', trialN);
			fprintf('===> Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
				t.window.radius,t.window.init,t.window.hold,t.window.release);

			if trialN == 1; dt.data.startTime = GetSecs; end
			
			WaitSecs(0.01);
			reset(t);
			flush(t);
			
			if ~isempty(sbg); draw(sbg); end
			vbl = flip(s); vblInit = vbl;
			while isempty(touchInit) && vbl < vblInit + tr.trialTime
				if ~isempty(sbg); draw(sbg); end
				draw(set)
				if tr.debug && ~isempty(t.x) && ~isempty(t.y)
					drawText(s, txt);
					[xy] = s.toPixels([t.x t.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchInit, hld, hldtime, rel, reli, se, fail, tch] = testHold(t,'yes','no');
				if tch
					anyTouch = true;
				end
				txt = sprintf('Phase=%i Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i %.1f Init: %.2f Hold: %.2f Release: %.2f',...
					1,touchInit,t.x,t.y,hld, hldtime, rel, reli, se,...
					t.window.radius,t.window.init,t.window.hold,t.window.release);
				[~,~,c] = KbCheck();
				if c(quitKey); keepRunning = false; break; end
			end

			if matches(touchInit,'yes')

				hide(set,1);
				show(set,[2 3 4]);

				if ~isempty(sbg); draw(sbg); end
				vbl = flip(s); vblInit = vbl;
				while isempty(touchResponse) && vbl < vblInit + tr.trialTime
					if ~isempty(sbg); draw(sbg); end
					draw(set)
					if tr.debug && ~isempty(t.x) && ~isempty(t.y)
						drawText(s, txt);
						[xy] = s.toPixels([t.x t.y]);
						Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
					end
					vbl = flip(s);
					[touchResponse, hld, hldtime, rel, reli, se, fail, tch] = testHold(t,'yes','no');
					if tch
						anyTouch = true;
					end
					txt = sprintf('Phase=%i Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i %.1f Init: %.2f Hold: %.2f Release: %.2f',...
						1,touchResponse,t.x,t.y,hld, hldtime, rel, reli, se,...
						t.window.radius,t.window.init,t.window.hold,t.window.release);
					[~,~,c] = KbCheck();
					if c(quitKey); keepRunning = false; break; end
				end

			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
			vblEnd = flip(s);
			WaitSecs(0.01);

			if strcmp(touchResponse,'yes')
				giveReward(rM);
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
				WaitSecs('YieldSecs',tr.timeOut);
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
			drawBackground(s,tr.bg)
			if ~isempty(sbg); draw(sbg); end
			flip(s);
		end % while keepRunning

		drawText(s, 'FINISHED!');
		flip(s);

		try ListenChar(0); Priority(0); ShowCursor; end
		try reset(target); end
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
		try reset(target); end
		try close(s); end
		try close(t); end
		try close(rM); end
		try close(a); end
		try Priority(0); end
		try ListenChar(0); end
		sca;
	end

end
