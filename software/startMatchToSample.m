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
		tr.folder = [pth filesep 'resources'];
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
		tr.randomReward = 0;
		tr.volume = 250;
		tr.nTrialsSample = 10;
		tr.negationBuffer = 2;
		tr.exclusionZone = [];
		tr.drainEvents = true;
		tr.strictMode = true;
		tr.negateTouch = true;
		tr.touchDevice = 1;
		tr.touchDeviceName = 'ILITEK-TP';
	end
	windowed = [];
	sf = [];
	

	broadcast = matmoteGO.broadcast();
	

	% =========================== debug mode?
	if max(Screen('Screens'))==0 && tr.debug; sf = kPsychGUIWindow; windowed = [0 0 1300 800]; end
	
	try
		% ============================screen
		s = screenManager('screen',tr.screen,'blend',true,'pixelsPerCm',...
			tr.density, 'distance', tr.distance,...
			'backgroundColour',tr.bg,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		fix = discStimulus('size', 5, 'colour', [1 1 0.5], 'alpha', 0.8);
		rtarget = imageStimulus('size', 5, 'colour', [0 1 0], 'filePath', 'star.png');
		pedestal = discStimulus('size', tr.objectSize + 1,'colour',[1 1 0],'alpha',0.3);
		target1 = imageStimulus('size', tr.objectSize, 'randomiseSelection', false, 'filePath', [tr.folder filesep tr.object filesep 'B']);
		target2 = clone(target1);
		distractor1 = clone(target1);
		distractor1.filePath = [tr.folder filesep tr.object filesep 'C'];
		distractor2 = clone(target1);
		distractor2.filePath = [tr.folder filesep tr.object filesep 'D'];
		distractor3 = clone(target1);
		distractor3.filePath = [tr.folder filesep tr.object filesep 'E'];
		distractor4 = clone(target1);
		distractor4.filePath = [tr.folder filesep tr.object filesep 'H'];
		set = metaStimulus('stimuli',{pedestal, target1, target2, distractor1, distractor2, distractor3, distractor4});
		set.fixationChoice = 3;

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
		t = touchManager('isDummy',tr.dummy,'device',tr.touchDevice,...
			'deviceName',tr.touchDeviceName,'exclusionZone',tr.exclusionZone,...
			'drainEvents',tr.drainEvents);
		t.window.doNegation = tr.doNegation;
		t.window.negationBuffer = tr.negationBuffer;
		if tr.debug; t.verbose = true; end

		% ============================reward
		rM = PTBSimia.pumpManager();
		
		% ============================setup
		sv = open(s);
		if ~isempty(sbg); setup(sbg, s); draw(sbg); end
		drawTextNow(s,'Initialising...');
		setup(fix, s);
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

		while keepRunning

			set.fixationChoice = 3;
			pedestal.xPositionOut = 0;
			pedestal.yPositionOut = sv.topInDegrees + 5/2;
			target1.xPositionOut = 0;
			target1.yPositionOut = sv.topInDegrees + 5/2;
			switch tr.distractorN
				case 1
					[~,idx] = Shuffle([1 2]);
					xy = [-4.5 4.5; 5 5];
					xy = xy(:,idx);
					target2.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2));
					hide(set);
					show(set,[1 2 3 4]);
				case 2
					[~,idx] = Shuffle([1 2 3]);
					xy = [-4.5 0 4.5; 5 6 5];
					xy = xy(:,idx);
					target2.xPositionOut = xy(1,1);
					target2.yPositionOut = xy(2,1);
					distractor1.xPositionOut = xy(1,2);
					distractor1.yPositionOut = xy(2,2);
					distractor2.xPositionOut = xy(1,3);
					distractor2.yPositionOut = xy(2,3);
					hide(set);
					show(set,[1 2 3 4 5]);
				case 3
					[~,idx] = Shuffle([1 2 3 4]);
					xy = [-9 -4.5 0 4.5; 6 5 6 5];
					xy = xy(:,idx);
					target2.xPositionOut = xy(1,1);
					target2.yPositionOut = xy(2,1);
					distractor1.xPositionOut = xy(1,2);
					distractor1.yPositionOut = xy(2,2);
					distractor2.xPositionOut = xy(1,3);
					distractor2.yPositionOut = xy(2,3);
					distractor3.xPositionOut = xy(1,4);
					distractor3.yPositionOut = xy(2,4);
					hide(set);
					show(set,[1 2 3 4 5 6]);
				otherwise
					[~,idx] = Shuffle([1 2 3 4 5]);
					x = (0:tr.objectSep:tr.objectSep*4) - (tr.objectSep*4/2);
					xy = [x; 6 5 6 5 6];
					xy = xy(:,idx);
					target2.xPositionOut = xy(1,1);
					target2.yPositionOut = xy(2,1);
					distractor1.xPositionOut = xy(1,2);
					distractor1.yPositionOut = xy(2,2);
					distractor2.xPositionOut = xy(1,3);
					distractor2.yPositionOut = xy(2,3);
					distractor3.xPositionOut = xy(1,4);
					distractor3.yPositionOut = xy(2,4);
					distractor4.xPositionOut = xy(1,5);
					distractor4.yPositionOut = xy(2,5);
					hide(set);
					show(set,[1 2 3 4 5 6 7]);
			end
			
			r = randi(target1.nImages); stimulus = r;
			target1.selectionOut = r;
			target2.selectionOut = r;
			rr = r;
			for jj = 4:7
				r = randi(set{jj}.nImages);
				while any(r == rr)
					r = randi(set{jj}.nImages);
				end
				set{jj}.selectionOut = r;
				rr = [rr r];
			end

			update(set);

			t.window.radius = fix.size/2;
			t.window.init = 5;
			t.window.hold = 0.01;
			t.window.release = 1.0;
			t.window.X = 0;
			t.window.Y = 0;

			res = 0; phase = 1;
			keepRunning = true;
			touchInit = '';
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
			while isempty(touchInit) && vbl < vblInit + 5
				if ~isempty(sbg); draw(sbg); end
				if ~hldtime; draw(fix); end
				if tr.debug && ~isempty(t.x) && ~isempty(t.y)
					[xy] = s.toPixels([t.x t.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchInit, hld, hldtime, rel, reli, se, fail, tch] = testHold(t,'yes','no');
				if tch; anyTouch = true; end
				[~,~,c] = KbCheck();
				if c(quitKey); keepRunning = false; break; end
			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
			flip(s); 
			reset(t);
			flush(t);

			if matches(touchInit,'yes')
				touchResponse = '';
				[x,y] = set.getFixationPositions;
				t.window.radius = target2.size/2;
				t.window.init = tr.trialTime;
				t.window.hold = 0.05;
				t.window.release = 1;
				t.window.X = x;
				t.window.Y = y;
				while isTouch(t)
					if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
					vbl = flip(s);
				end
				reset(t);
				flush(t);
				vblInit = vbl;
				while isempty(touchResponse) && vbl < (vblInit + tr.trialTime)
					if ~isempty(sbg); draw(sbg); end
					draw(set);
					if tr.debug && ~isempty(t.x) && ~isempty(t.y)
						drawText(s, txt);
						[xy] = s.toPixels([t.x t.y]);
						Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
					end
					vbl = flip(s);
					[touchResponse, hld, hldtime, rel, reli, se, fail, tch] = testHold(t,'yes','no');
					if tch; anyTouch = true; end
					txt = sprintf('Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i tch:%i WR: %.1f WInit: %.2f WHold: %.2f WRel: %.2f WX: %.2f WY: %.2f',...
						touchResponse, t.x, t.y, hld, hldtime, rel, reli, se, tch, ...
						t.window.radius,t.window.init,t.window.hold,t.window.release,t.window.X,t.window.Y);
					[~,~,c] = KbCheck();
					if c(quitKey); keepRunning = false; break; end
				end
			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
			vblEnd = flip(s);
			WaitSecs(0.05);

			% lets check the result:
			if anyTouch == false
				
			elseif strcmp(touchResponse,'yes')
				giveReward(rM, tr.rewardTime);
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,tr.correctBeep,0.1,tr.audioVolume);
				update(dt, true, phase, trialN, vblEnd-vblInit, stimulus);
				phaseN = phaseN + 1;
				if ~isempty(sbg); draw(sbg); end
				drawText(s,['CORRECT! phase: ' num2str(phase)]);
				flip(s);
				WaitSecs(0.5+rand);
			elseif strcmp(touchResponse,'no')
				update(dt, false, phase, trialN, vblEnd-vblInit, stimulus);
				phaseN = phaseN + 1;
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,['FAIL! phase: ' num2str(phase)]);
				flip(s);
				beep(a,tr.incorrectBeep,0.5,tr.audioVolume);
				WaitSecs(tr.timeOut);
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
				WaitSecs(0.5+rand);
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
		tVol = (9.38e-4 * tr.rewardTime) * dt.data.rewards;
		fVol = (9.38e-4 * tr.rewardTime) * dt.data.random;
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
