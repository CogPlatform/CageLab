function startMatchToSample(in)
	pth = fileparts(which(mfilename));
	if ~exist('in','var') || isempty(in); in = clutil.checkInput(pth); end
	windowed = [];
	sf = [];
	zmq = in.zmq;
	broadcast = matmoteGO.broadcast();
	
	% =========================== debug mode?
	if (in.screen == 0 || max(Screen('Screens'))==0) && in.debug; sf = kPsychGUIWindow; windowed = [0 0 1300 800]; end
		
	try
		%% ============================screen & background
		s = screenManager('screen',in.screen,'blend',true,'pixelsPerCm',...
			in.density, 'distance', in.distance,...
			'backgroundColour',in.bg,'windowed',windowed,'specialFlags',sf);
		if in.smartBackground
			sbg = imageStimulus('alpha', 1, 'filePath', [in.folder filesep 'background' filesep 'abstract1.jpg']);
		else 
			sbg = [];
		end
		% s============================stimuli
		fix = discStimulus('size', in.initSize, 'colour', in.fg, 'alpha', 0.8,...
			'xPosition', in.initPosition(1),'yPosition', in.initPosition(2));
		pedestal = discStimulus('size', in.objectSize + 1,'colour',[0.5 1 1],'alpha',0.3,'yPosition',in.startY);
		target1 = imageStimulus('size', in.objectSize, 'randomiseSelection', false,...
			'filePath', [in.folder filesep in.object filesep 'B'],'yPosition',in.startY);
		target2 = clone(target1);
		distractor1 = clone(target1);
		distractor1.filePath = [in.folder filesep in.object filesep 'C'];
		distractor2 = clone(target1);
		distractor2.filePath = [in.folder filesep in.object filesep 'D'];
		distractor3 = clone(target1);
		distractor3.filePath = [in.folder filesep in.object filesep 'E'];
		distractor4 = clone(target1);
		distractor4.filePath = [in.folder filesep in.object filesep 'H'];
		set = metaStimulus('stimuli',{pedestal, target1, target2, distractor1, distractor2, distractor3, distractor4});
		set.fixationChoice = 3;

	

		%% ============================audio
		a = audioManager;
		if in.debug; a.verbose = true; end
		if in.audioVolume == 0 || in.audio == false; a.silentMode = true; end
		setup(a);
		beep(a,in.correctBeep,0.1,in.audioVolume);
		beep(a,in.incorrectBeep,0.1,in.audioVolume);

		%% ============================touch
		tM = touchManager('isDummy',in.dummy,'device',in.touchDevice,...
			'deviceName',in.touchDeviceName,'exclusionZone',in.exclusionZone,...
			'drainEvents',in.drainEvents);
		tM.window.doNegation = in.doNegation;
		tM.window.negationBuffer = in.negationBuffer;
		if in.debug; tM.verbose = true; end

		%% ============================reward
		if in.reward; rM = PTBSimia.pumpManager(); else; rM = []; end
		
		%% ============================setup
		sv = open(s);
		drawTextNow(s,'Initialising...');
		if in.smartBackground
			sbg.size = max([sv.widthInDegrees sv.heightInDegrees]);
			setup(sbg, s);
		end
		aspect = sv.width / sv.height;
		setup(fix, s);
		setup(set, s);
		setup(tM, s);
		createQueue(tM);
		start(tM);

		%% ==============================save file name
		[path, sessionID, dateID, name] = s.getALF(in.name, in.lab, true);
		saveName = [ path filesep 'MTS-' name '.mat'];
		dt = touchData;
		dt.name = saveName;
		dt.subject = in.name;
		dt.data.random = 0;
		dt.data.rewards = 0;
		dt.data.in = in;

		%% ============================settings
		quitKey = KbName('escape');
		RestrictKeysForKbCheck(quitKey);
		Screen('Preference','Verbosity',4);
		
		if ~in.debug && ~in.dummy; Priority(1); HideCursor; end
		keepRunning = true;
		trialN = 0;
		phaseN = 1;phase = 1;

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while keepRunning

			set.fixationChoice = 3;
			pedestal.xPositionOut = 0;
			pedestal.yPositionOut = in.startY;
			target1.xPositionOut = 0;
			target1.yPositionOut = in.startY;
			sep = in.objectSep;
			N = in.distractorN;
			Y = in.distractorY;
			switch N
				case 1
					[~,idx] = Shuffle([1 2]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand];
					xy = xy(:,idx);
					target2.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2));
					hide(set);
					show(set,[1 2 3 4]);
				case 2
					[~,idx] = Shuffle([1 2 3]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand];
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
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand Y-rand];
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
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand Y-rand Y+rand];
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
			
			% reset touch window for initial touch
			tM.window.radius = fix.size/2;
			tM.window.init = 5;
			tM.window.hold = 0.05;
			tM.window.release = 1.0;
			tM.window.X = in.initPosition(1);
			tM.window.Y = in.initPosition(2);
			tM.window.doNegation = true;
			tM.exclusionZone = [];

			res = 0; phase = 1;
			keepRunning = true;
			touchResponse = '';
			anyTouch = false;
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			
			%% Initiate a trial with a touch target
			[touchInit, hldtime, anyTouch, keepRunning, dt] = clutil.startTouchTrial(trialN, in, tM, sbg, s, fix, hldtime, anyTouch, quitKey, keepRunning, dt);

			if matches(string(touchInit),"yes")
				touchResponse = '';
				[x,y] = set.getFixationPositions;
				tM.window.radius = target2.size/2;
				tM.window.init = in.trialTime;
				tM.window.hold = 0.05;
				tM.window.release = 1;
				tM.window.X = x;
				tM.window.Y = y;
				vblInit = vbl;
				while isempty(touchResponse) && vbl < (vblInit + in.trialTime)
					if ~isempty(sbg); draw(sbg); end
					draw(set);
					if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
						drawText(s, txt);
						[xy] = s.toPixels([tM.x tM.y]);
						Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
					end
					vbl = flip(s);
					[touchResponse, hld, hldtime, rel, reli, se, fail, tch] = testHold(tM,'yes','no');
					if tch; anyTouch = true; end
					txt = sprintf('Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i tch:%i WR: %.1f WInit: %.2f WHold: %.2f WRel: %.2f WX: %.2f WY: %.2f',...
						touchResponse, tM.x, tM.y, hld, hldtime, rel, reli, se, tch, ...
						tM.window.radius,tM.window.init,tM.window.hold,tM.window.release,tM.window.X,tM.window.Y);
					[~,~,c] = KbCheck();
					if c(quitKey); keepRunning = false; break; end
				end
			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
			vblEnd = flip(s);
			WaitSecs(0.05);

			% lets check the result:
			if anyTouch == false
				
			elseif strcmp(touchResponse,'yes')
				if in.reward; giveReward(rM, in.rewardTime); end
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,in.correctBeep,0.1,in.audioVolume);
				update(dt, true, phase, trialN, vblEnd-vblInit, stimulus);
				if ~isempty(sbg); draw(sbg); end
				drawText(s,['CORRECT! phase: ' num2str(phase)]);
				flip(s);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs(0.5+rand);
			elseif strcmp(touchResponse,'no')
				update(dt, false, phase, trialN, vblEnd-vblInit, stimulus);
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,['FAIL! phase: ' num2str(phase)]);
				flip(s);
				beep(a,in.incorrectBeep,0.5,in.audioVolume);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs('YieldSecs',in.timeOut);
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs(0.5+rand);
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
		try reset(set); end
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
