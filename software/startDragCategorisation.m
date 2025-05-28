function startDragCategorisation(tr)
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
		tr.initPosition = [0 3];
		tr.target1Pos = [-5 -5];
		tr.target2Pos = [5 -5];
		tr.initSize = 4;
		tr.targetSize = 10;
	end
	windowed = [];
	sf = [];
	broadcast = matmoteGO.broadcast();
	
	% =========================== debug mode?
	if (tr.screen == 0 || max(Screen('Screens'))==0) && tr.debug; sf = kPsychGUIWindow; windowed = [0 0 1300 800]; end
		
	try
		% ============================screen
		s = screenManager('screen',tr.screen,'blend',true,'pixelsPerCm',...
			tr.density, 'distance', tr.distance,...
			'backgroundColour',tr.bg,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		rtarget = imageStimulus('size', 5, 'colour', [0 1 0], 'filePath', 'star.png');
		
		fix = discStimulus('size', tr.initSize, 'colour', [1 1 0.5], 'alpha', 0.8,...
			'xPosition', tr.initPosition(1),'yPosition', tr.initPosition(2));
		object = imageStimulus('name','object', 'size', tr.targetSize, 'filePath', ...
			[tr.folder filesep 'flowers'],'crop', 'square', 'circularMask', false,...
			'xPosition',tr.initPosition(1),'yPosition',tr.initPosition(2));
		target1 = clone(object);
		target1.name = 'target1';
		target1.xPosition = tr.target1Pos(1);
		target1.yPosition = tr.target1Pos(2);
		target2 = clone(object);
		target2.name = 'target2';
		target2.xPosition = tr.target2Pos(1);
		target2.yPosition = tr.target2Pos(2);
		set = metaStimulus('stimuli',{fix, object, target1, target2});
		
		if tr.smartBackground
			sbg = imageStimulus('alpha', 1, 'filePath', [tr.folder filesep 'background' filesep 'abstract1.jpg']);
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
		tM = touchManager('isDummy',tr.dummy,'device',tr.touchDevice,...
			'deviceName',tr.touchDeviceName,'exclusionZone',tr.exclusionZone,...
			'drainEvents',tr.drainEvents);
		tM.window.doNegation = tr.doNegation;
		tM.window.negationBuffer = tr.negationBuffer;
		if tr.debug; tM.verbose = true; end

		% ============================reward
		rM = PTBSimia.pumpManager();
		
		% ============================setup
		sv = open(s);
		if ~isempty(sbg); setup(sbg, s); draw(sbg); end
		drawTextNow(s,'Initialising...');
		setup(fix, s);
		setup(set, s);
		setup(rtarget, s); rRect = rtarget.mvRect;
		setup(tM, s);
		createQueue(tM);
		start(tM);

		% ==============================save file name
		[path, sessionID, dateID, name] = s.getALF(tr.name, tr.lab, true);
		saveName = [ path filesep 'DCAT-' name '.mat'];
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
			xy = [tr.target1Pos; tr.target2Pos];
			
			object.updateXY(0,0,true);
			target1.updateXY(xy(idx(1),1),xy(idx(1),2), true);
			target2.updateXY(xy(idx(2),1),xy(idx(2),2), true);

			r = randi(object.nImages); stimulus = r;
			object.selectionOut = r;
			target1.selectionOut = r;
			rr = r;
			for jj = 4
				r = randi(set{jj}.nImages);
				while any(r == rr)
					r = randi(set{jj}.nImages);
				end
				set{jj}.selectionOut = r;
				rr = [rr r];
			end

			hide(set);
			show(set,1);

			update(set);
			
			% touch window
			tM.window.radius = fix.size/2;
			tM.window.init = 5;
			tM.window.hold = 0.05;
			tM.window.release = 1.0;
			tM.window.X = tr.initPosition(1);
			tM.window.Y = tr.initPosition(2);

			res = 0; phase = 1;
			keepRunning = true;
			touchInit = '';
			touchResponse = '';
			anyTouch = false;
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			
			fprintf('\n===> START TRIAL: %i - STIM\n', trialN);
			fprintf('===> Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
				tM.window.radius,tM.window.init,tM.window.hold,tM.window.release);

			if trialN == 1; dt.data.startTime = GetSecs; end
			
			WaitSecs(0.01);
			reset(tM);
			flush(tM);
			
			if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
			
			vbl = flip(s); vblInit = vbl;
			while isempty(touchInit) && vbl < vblInit + 5
				if ~isempty(sbg); draw(sbg); end
				if ~hldtime; draw(fix); end
				if tr.debug && ~isempty(tM.x) && ~isempty(tM.y)
					[xy] = s.toPixels([tM.x tM.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchInit, hld, hldtime, rel, reli, se, fail, tch] = testHold(tM,'yes','no');
				if tch; anyTouch = true; end
				[~,~,c] = KbCheck();
				if c(quitKey); keepRunning = false; break; end
			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
			flip(s); 
			while isTouch(tM)
				if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
				vbl = flip(s);
			end

			if matches(touchInit,'yes')

				tM.verbose = true;
				tM.window.radius = [tr.targetSize/2 tr.targetSize/2];
				tM.window.init = tr.trialTime;
				tM.window.hold = tr.trialTime;
				tM.window.release = 1.0;
				tM.window.X = object.xFinalD;
				tM.window.Y = object.yFinalD;
				hide(set,1);
				show(set,[2 3 4]);
				nowX = []; nowY = []; inTouch = false; reachTarget = false;
				flush(tM);
				if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
				vbl = flip(s); vblInit = vbl;
				while ~reachTarget && vbl < vblInit + tr.trialTime+1
					if ~isempty(sbg); draw(sbg); end
					draw(set)
					if tr.debug
						drawText(s, txt);
						if ~isempty(tM.x) && ~isempty(tM.y)
							[xy] = s.toPixels([tM.x tM.y]);
							Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
						end
					end
					vbl = flip(s);
					processTouch();
					if tM.eventPressed
						anyTouch = true;
					end
					txt = sprintf('Response=%i x=%.2f y=%.2f',...
						touchResponse,tM.x,tM.y);
					[~,~,c] = KbCheck();
					if c(quitKey); keepRunning = false; break; end
				end

			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,tr.bg); end
			vblEnd = flip(s);
			WaitSecs(0.01);

			if strcmp(touchResponse,'yes')
				giveReward(rM, tr.rewardTime);
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,2000,0.1,0.1);
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
				beep(a,250,0.3,0.8);
				WaitSecs('YieldSecs',tr.timeOut);
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
				WaitSecs(0.5+rand);
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
		try close(tM); end
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
		try reset(target); end
		try close(s); end
		try close(tM); end
		try close(rM); end
		try close(a); end
		try Priority(0); end
		try ListenChar(0); end
		sca;
	end

	function processTouch()
		if tM.eventAvail % check we have touch event[s]
			if inTouch
				tM.window.X = target1.xFinalD;
				tM.window.Y = target1.yFinalD;
				evt = getEvent(tM);
			else
				tM.window.X = object.xFinalD;
				tM.window.Y = object.yFinalD;
				result = checkTouchWindows(tM,[],false); % check we are touching
				evt = tM.event;
				if result; inTouch = true; end
			end
			if isempty(evt); return; end
			nowX = tM.x; nowY = tM.y;
			if inTouch && tM.eventRelease && evt.Type == 4 % this is a RELEASE event
				if tr.debug; fprintf('≣≣≣≣⊱ processTouch@%s:RELEASE X: %.1f Y: %.1f \n',tM.name, tM.x,tM.y); end
				xy = []; tx = []; ty = []; inTouch = false;
			elseif inTouch && tM.eventPressed
				tx = [tx nowX];
				ty = [ty nowY];
				object.updateXY(nowX, nowY, true);
				object.alphaOut = 0.75;
				if tr.debug; fprintf('≣≣≣≣⊱ processTouch@%s:TOUCH X: %.1f Y: %.1f \n',...
						tM.name, nowX, nowY); 
				end
			end
		end
	end

end
