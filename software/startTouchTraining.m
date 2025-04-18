function startTouchTraining(tr)
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
		tr.soundvol = 0.7;
		tr.stimulus = 2;
		tr.task = 2;
		tr.name = 'simulcra';
		tr.rewardmode = 1;
		tr.volume = 250;
		tr.random = 1;
		tr.screen = 0;
		tr.smartBackground = true;
	end
	pixelsPerCm = tr.density;
	distance = tr.distance;
	timeOut = tr.timeOut;
	rewardPort = '/dev/ttyACM0';
	windowed = [];
	sf = [];

	% =========================== debug mode?
	if tr.debug
		if max(Screen('Screens'))==0 && tr.debug; sf = kPsychGUIWindow; windowed = [0 0 1600 800]; end
	end

	%if IsOctave; try pkg load instrument-control; end; end

	try
		% ============================screen
		s = screenManager('screen',tr.screen,'blend',true,'pixelsPerCm',pixelsPerCm, 'distance', distance,...
		'backgroundColour',tr.bg,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		rtarget = imageStimulus('size', 10, 'colour', [0 1 0], 'filePath', 'star.png');
		if tr.stimulus == 2
			target = imageStimulus('size', tr.maxSize, 'filePath', [tr.folder filesep 'objects'], 'crop', 'square','circularMask',true);
		else
			target = discStimulus('size', tr.maxSize, 'colour', tr.fg);
		end
		if tr.debug; target.verbose = true; end

		% ============================audio

		a = audioManager;
		if tr.debug; a.verbose = true; end
		if tr.soundvol == 0 || tr.audio == false; a.silentMode = true; end
		setup(a);
		beep(a,2000,0.1,tr.soundvol/2);
		WaitSecs(0.1);
		beep(a,300,0.5,tr.soundvol/2);

		% ============================touch
		t = touchManager('isDummy',tr.dummy);
		t.window.doNegation = true;
		t.window.negationBuffer = 1.5;
		t.drainEvents = true;
		if tr.debug; t.verbose = true; end


		% ============================reward
		rM = arduinoManager;
		rM.silentMode = true;
		rM.reward.type = 'TTL';
		rM.reward.pin = 2;
		rM.reward.time = tr.volume; % 250ms
		if tr.debug; rM.verbose = true; end
		try open(rM); end %#ok<*TRYNC>

		% ============================steps table
		sz = linspace(tr.maxSize, tr.minSize, 5);

		if tr.task == 1 % simple task
			if tr.phase > 9; tr.phase = 9; end
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
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
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
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 11; pn = pn + 1;
		end


		% ============================setup
		sv = open(s);
		drawText(s,'Initialising...');flip(s);
		if tr.smartBackground
			sbg = imageStimulus('alpha',0.5, 'filePath', [tr.folder filesep 'background' filesep 'abstract1.jpg']);
		else 
			sbg = [];
		end
		aspect = sv.width / sv.height;
		setup(rtarget, s);
		setup(target, s);
		if ~isempty(sbg); setup(sbg, s); end
		setup(t, s);
		createQueue(t);
		start(t);

		% ==============================save file name
		svn = initialiseSaveFile(s);
		mkdir([s.paths.savedData filesep tr.name]);
		saveName = [ s.paths.savedData filesep tr.name filesep 'TouchT-' tr.name '-' svn '.mat'];
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
		%try Priority(1); end
		if ~tr.debug || ~tr.dummy; HideCursor; end
		txt = 'Waiting for touch...';
		keepRunning = true;
		trialN = 0;
		phaseN = 0;
		timeOut = 2;
		phase = tr.phase;
		stimulus = 1;
		rTime = GetSecs;
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
				t.window.hold = randi(p(phase).hold .* 1e3) / 1e3;
			else
				t.window.hold = p(phase).hold(1);
			end
			if isa(target,'imageStimulus')
				t.window.radius = [p(phase).size/2 p(phase).size/2];
			else
				t.window.radius = p(phase).size / 2;
			end
			t.window.init = 3;
			t.window.release = p(phase).rel;
			t.window.X = x;
			t.window.Y = y;

			target.xPositionOut = x;
			target.yPositionOut = y;
			target.sizeOut = p(phase).size;
			if isa(target,'imageStimulus')
				target.selectionOut = randi(target.nImages);
				stimulus = target.selectionOut;
			end
			update(target);

			res = 0;
			touchStart = false; keepRunning = true;
			touchResponse = '';
			anyTouch = false;
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			
			fprintf('\n===> START TRIAL: %i - PHASE %i STIM %i\n', trialN, phase, stimulus);
			fprintf('===> Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', t.window.radius,t.window.init,t.window.hold,t.window.release);

			if trialN == 1; dt.data.startTime = GetSecs; end
			
			reset(t);
			flush(t);
			
			WaitSecs(0.01);
			vbl = flip(s); vblInit = vbl;
			while ~touchStart && vbl < vblInit + 4
				if ~isempty(sbg); draw(sbg); end
				if ~hldtime; draw(target); end
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
				txt = sprintf('Step=%i Touch=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i %.1f Init: %.2f Hold: %.2f Release: %.2f',...
					phase,touchResponse,t.x,t.y,hld, hldtime, rel, reli, se,...
					t.window.radius,t.window.init,t.window.hold,t.window.release);
				if ~isempty(touchResponse) 
					touchStart = true; 
					break; 
				end
				[~,~,c] = KbCheck();
				if c(quitKey); keepRunning = false; break; end
			end

			vblEnd = flip(s);
			WaitSecs(0.05);

			% lets check the result:
			if anyTouch == false
				tt = vblEnd - rTime;
				if tr.random > 0 && tt > tr.random && rand > 0.25
					drawBackground(s);
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
					rTime = GetSecs;
				else
					fprintf('===> TIMEOUT :-)\n');
					drawText(s,'TIMEOUT!');
					flip(s);
					WaitSecs(0.75+rand);
				end
			elseif strcmp(touchResponse,'yes')
				giveReward(rM);
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,2000,0.1,0.1);
				update(dt, true, phase, trialN, vblEnd-vblInit, stimulus);
				phaseN = phaseN + 1;
				drawText(s,['CORRECT! phase: ' num2str(phase)]);
				flip(s);
				WaitSecs(0.5+rand);
				rTime = GetSecs;
			elseif strcmp(touchResponse,'no')
				update(dt, false, phase, trialN, vblEnd-vblInit, stimulus);
				phaseN = phaseN + 1;
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,['FAIL! phase: ' num2str(phase)]);
				flip(s);
				beep(a,250,0.3,0.8);
				WaitSecs(timeOut);
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				flip(s);
				WaitSecs(0.5+rand);
			end

			if trialN >= 10
				if length(dt.data.result)>10
					res = sum(dt.data.result(end-9:end));
				end
				fprintf('===> Performance: %i Phase: %i\n',res,phase);
				if phaseN >= 10 && length(dt.data.result)>10
					if res >= 8
						phase = phase + 1;
					elseif res <= 2
						phase = phase - 1;
					end
					phaseN = 0;
					if phase < 1; phase = 1; end
					if phase > 20; phase = 20; end
					if tr.task == 1 && phase > 9; phase = 9; end
					fprintf('===> Phase update: %i\n',phase);
				end
			end

			if keepRunning == false; break; end
			drawBackground(s);
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
		try dt.plot(dt); end

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
