function startDragCategorisation(in)
	pth = fileparts(which(mfilename));
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
		in.task = 'Normal';
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
		in.initPosition = [0 3];
		in.target1Pos = [-5 -5];
		in.target2Pos = [5 -5];
		in.initSize = 4;
		in.targetSize = 10;
	end
	windowed = [];
	sf = [];
	zmq = in.zmq;
	broadcast = matmoteGO.broadcast();
	
	% =========================== debug mode?
	if (in.screen == 0 || max(Screen('Screens'))==0) && in.debug; sf = kPsychGUIWindow; windowed = [0 0 1300 800]; end
		
	try
		% ============================screen
		s = screenManager('screen',in.screen,'blend',true,'pixelsPerCm',...
			in.density, 'distance', in.distance,...
			'backgroundColour',in.bg,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		rtarget = imageStimulus('size', 5, 'colour', [0 1 0], 'filePath', 'star.png');
		
		fix = discStimulus('size', in.initSize, 'colour', [1 1 0.5], 'alpha', 0.8,...
			'xPosition', in.initPosition(1),'yPosition', in.initPosition(2));
		object = imageStimulus('name','object', 'size', in.targetSize, 'filePath', ...
			[in.folder filesep 'flowers'],'crop', 'square', 'circularMask', false,...
			'xPosition',in.initPosition(1),'yPosition',in.initPosition(2));
		target1 = clone(object);
		target1.name = 'target1';
		target1.xPosition = in.target1Pos(1);
		target1.yPosition = in.target1Pos(2);
		target2 = clone(object);
		target2.name = 'target2';
		target2.xPosition = in.target2Pos(1);
		target2.yPosition = in.target2Pos(2);
		set = metaStimulus('stimuli',{target1, target2, object, fix});
		
		if in.smartBackground
			sbg = imageStimulus('alpha', 1, 'filePath', [in.folder filesep 'background' filesep 'abstract1.jpg']);
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
		[path, sessionID, dateID, name] = s.getALF(in.name, in.lab, true);
		saveName = [ path filesep 'DCAT-' name '.mat'];
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
		phase = 1;
		stimulus = 1;
		randomRewardTimer = GetSecs;
		rRect = rtarget.mvRect;

		while keepRunning
			
			[~,idx] = Shuffle([1 2]);
			xy = [in.target1Pos; in.target2Pos];
			
			object.updateXY(0,0,true);
			target1.updateXY(xy(idx(1),1),xy(idx(1),2), true);
			target2.updateXY(xy(idx(2),1),xy(idx(2),2), true);

			r = randi(object.nImages); stimulus = r;
			object.selectionOut = r;
			target1.selectionOut = r;
			rr = r;
			for jj = 2
				r = randi(set{jj}.nImages);
				while any(r == rr)
					r = randi(set{jj}.nImages);
				end
				set{jj}.selectionOut = r;
				rr = [rr r];
			end

			hide(set);
			show(set,4);

			update(set);
			
			% touch window
			tM.window.radius = fix.size/2;
			tM.window.init = 5;
			tM.window.hold = 0.05;
			tM.window.release = 1.0;
			tM.window.X = in.initPosition(1);
			tM.window.Y = in.initPosition(2);
			tM.window.doNegation = true;
			tM.verbose = false;
			tM.exclusionZone = [];


			res = 0; phase = 1;
			keepRunning = true;
			touchInit = '';
			reachTarget = false;
			anyTouch = false; 
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			
			fprintf('\n===> START TRIAL: %i - STIM\n', trialN);
			fprintf('===> Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
				tM.window.radius,tM.window.init,tM.window.hold,tM.window.release);

			if trialN == 1; dt.data.startTime = GetSecs; end
			
			WaitSecs(0.01);
			flush(tM);

			
			if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
			
			vbl = flip(s); vblInit = vbl;
			while isempty(touchInit) && vbl < vblInit + 5
				if ~isempty(sbg); draw(sbg); end
				if ~hldtime; draw(fix); end
				if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
					[xy] = s.toPixels([tM.x tM.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchInit, ~, hldtime, ~, ~, ~, ~, tch] = testHold(tM,'yes','no');
				if tch; anyTouchInint = true; end
				[~,~,c] = KbCheck();
				if c(quitKey); keepRunning = false; break; end
			end

			%%% Wait for release
			while isTouch(tM)
				if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
				vbl = flip(s);
			end
			flush(tM);

			if matches(touchInit,'yes')
				tM.verbose = in.debug;
				tM.window.radius = [in.targetSize/2 in.targetSize/2];
				tM.window.init = in.trialTime;
				tM.window.hold = in.trialTime;
				tM.window.release = 1.0;
				tM.window.X = target1.xFinalD;
				tM.window.Y = target1.yFinalD;
				tM.window.doNegation = false;
				rect = CenterRectOnPointd([0 0 200 200],target2.xFinal,target2.yFinal);
				tM.exclusionZone = rect;
				hide(set,4);
				show(set,[1 2 3]);
				tx = [];
				ty = [];
				nowX = []; nowY = []; 
				inTouch = false; anyTouch = false; 
				reachTarget = false; exclusion = false;
				flush(tM);
				if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
				vbl = flip(s); vblInit = vbl;
				while ~reachTarget && ~exclusion && vbl < vblInit + in.trialTime+1
					if ~isempty(sbg); draw(sbg); end
					draw(set)
					if in.debug
						drawText(s, txt);
						if ~isempty(tM.x) && ~isempty(tM.y)
							[xy] = s.toPixels([tM.x tM.y]);
							Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
						end
					end
					vbl = flip(s);
					success = processTouch();
					if tM.eventPressed; anyTouch = true; end
					if success==true; reachTarget = true; end
					if success == -100; exclusion = true; reachTarget = false; end
					txt = sprintf('Response=%i x=%.2f y=%.2f',...
						reachTarget,tM.x,tM.y);
					[~,~,c] = KbCheck();
					if c(quitKey); keepRunning = false; break; end
				end

			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
			vblEnd = flip(s);
			WaitSecs(0.01);

			if reachTarget == true
				if in.reward; giveReward(rM, in.rewardTime); end
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,2000,0.1,0.1);
				update(dt, true, phase, trialN, vblEnd-vblInit, stimulus);
				
				if ~isempty(sbg); draw(sbg); end
				drawText(s,['CORRECT! phase: ' num2str(phase)]);
				flip(s);
				WaitSecs(0.5+rand);
			elseif reachTarget == false && anyTouch == true
				update(dt, false, phase, trialN, vblEnd-vblInit, stimulus);
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,['FAIL! phase: ' num2str(phase)]);
				flip(s);
				beep(a,250,0.3,0.8);
				WaitSecs('YieldSecs',in.timeOut);
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
				WaitSecs(0.5+rand);
			end

			broadcast.send(struct('name',in.name,'trial',trialN,'result',dt.data.result));


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
		tVol = (9.38e-4 * in.rewardTime) * dt.data.rewards;
		fVol = (9.38e-4 * in.rewardTime) * dt.data.random;
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

	function success = processTouch()
		success = false;
		if tM.eventAvail % check we have touch event[s]
			if ~inTouch
				tM.window.X = object.xFinalD;
				tM.window.Y = object.yFinalD;
				result = checkTouchWindows(tM, [], true); % check we are touching
				evt = tM.event;
				if result 
					inTouch = true; 
					firstRun = true;
				end
			else
				tM.window.X = target1.xFinalD;
				tM.window.Y = target1.yFinalD;
				tM.window.radius = 3;
				evt = getEvent(tM);
				firstRun = false;
			end
			if isempty(evt); return; end
			if inTouch
				nowX = tM.x; nowY = tM.y;
				if tM.eventRelease && evt.Type == 4 % this is a RELEASE event
					if in.debug; fprintf('≣≣≣≣⊱ processTouch@%s%i:RELEASE X: %.1f Y: %.1f \n',tM.name, tM.x,tM.y); end
					xy = []; tx = []; ty = []; inTouch = false;
				elseif tM.eventPressed
					tx = [tx nowX];
					ty = [ty nowY];
					object.updateXY(nowX, nowY, true);
					object.alphaOut = 0.9;
					if in.debug; fprintf('≣≣≣≣⊱ processTouch@%s:TOUCH X: %.1f Y: %.1f \n',...
							tM.name, nowX, nowY); 
					end
				end
				if ~firstRun
					success = checkTouchWindows(tM,[],false);
					if success == true; fprintf('\nYAAAAAY %i\n',success); end
				end
			end
		end
	end

end
