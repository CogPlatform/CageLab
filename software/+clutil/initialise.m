function [s, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName, in] = initialise(in, bgName, prefix)
	%[s, sbg, rtarget, a, rM, tM] = +clutils.initialise(pth, in, bgName, prefix, windowed, sf);
	windowed = [];
	sf = [];

	% =========================== debug mode?
	if (in.screen == 0 || max(Screen('Screens'))==0) && in.debug
		%sf = kPsychGUIWindow; windowed = [0 0 1300 800]; 
		PsychDebugWindowConfiguration
	end
	
	%% ============================screen & background
	s = screenManager('screen', in.screen,'blend', true,...
		'pixelsPerCm', in.density, 'distance', in.distance,...
		'disableSyncTests', true, 'hideFlash', true, ...
		'backgroundColour', in.bg,'windowed', windowed,'specialFlags', sf);
	if in.smartBackground
		sbg = imageStimulus('alpha', 1, 'filePath', [in.folder filesep 'background' filesep bgName]);
	else 
		sbg = [];
	end

	%% s============================stimuli
	rtarget = imageStimulus('colour', [0 1 0], 'filePath', 'star.png');
	fix = discStimulus('size', in.initSize, 'colour', [1 1 0.5], 'alpha', 0.8,...
			'xPosition', in.initPosition(1),'yPosition', in.initPosition(2));
	
	%% ============================audio
	a = audioManager('device',in.audioDevice);
	if in.debug; a.verbose = true; end
	if in.audioVolume == 0 || in.audio == false
		a.silentMode = true; 
	else
		setup(a);
		beep(a,in.correctBeep,0.1,in.audioVolume);
		beep(a,in.incorrectBeep,0.1,in.audioVolume);
	end
	
	%% ============================touch
	tM = touchManager('isDummy',in.dummy,'device',in.touchDevice,...
		'deviceName',in.touchDeviceName,'exclusionZone',in.exclusionZone,...
		'drainEvents',in.drainEvents,'trackID',in.trackID);
	tM.window.doNegation = in.doNegation;
	tM.window.negationBuffer = in.negationBuffer;
	if in.debug || in.verbose; tM.verbose = true; end

	%% ============================reward
	if in.reward
		rM = PTBSimia.pumpManager(); 
	else %dummy mode pass true to constructor
		rM = PTBSimia.pumpManager(true); 
	end
	
	%% ============================setup
	sv = open(s); % open screen
	if in.smartBackground
		sbg.size = max([sv.widthInDegrees sv.heightInDegrees]);
		setup(sbg, s);
		if sbg.heightD < sv.heightInDegrees
			sbg.sizeOut = sbg.sizeOut + (sv.heightInDegrees - sbg.heightD);
			update(sbg);
		end
		draw(sbg);
	end
	
	drawTextNow(s,'Initialising...');
	
	rtarget.size = 5;
	rtarget.xPosition = sv.rightInDegrees - 6;
	rtarget.yPosition = sv.topInDegrees + 6;
	setup(rtarget, s);
	in.rRect = rtarget.mvRect;

	setup(fix, s);
	setup(tM, s);
	createQueue(tM);
	start(tM);

	%% ==============================save file name
	[path, sessionID, dateID, name] = s.getALF(in.name, in.lab, true);
	in.sessionID = sessionID;
	in.dateID = dateID;
	saveName = [ path filesep prefix '-' name '.mat'];
	dt = touchData;
	dt.name = saveName;
	dt.subject = in.name;
	dt.data(1).comment = [in.task ' ' in.command ' - CageLab V' clutil.version];
	dt.data(1).random = 0;
	dt.data(1).rewards = 0;
	dt.data(1).times.initStart = [];
	dt.data(1).times.initTouch = [];
	dt.data(1).times.initRT = [];
	dt.data(1).times.taskStart = [];
	dt.data(1).times.taskEnd = [];
	dt.data(1).times.taskRT = [];

	if isempty(dt.info); dt.info(1).name = dt.name; end
	dt.info.screenVals = sv;
	dt.info.settings = in;

	%% ============================settings
	quitKey = KbName('escape');
	RestrictKeysForKbCheck(quitKey);
	Screen('Preference','Verbosity',4);
		
	if ~in.debug; Priority(1); end
	if ~in.debug || ~in.dummy; HideCursor; end

	%% ============================ run variables
	r = [];
	r.zmq = in.zmq;
	r.broadcast = matmoteGO.broadcast();
	r.keepRunning = true;
	r.phase = in.phase;
	r.correctRate = NaN;
	r.loopN = 0;
	r.trialN = 0;
	r.trialW = 0;
	r.phaseN = 0;
	r.stimulus = 1;
	r.randomRewardTimer = GetSecs;
	r.rRect = rtarget.mvRect;
	r.result = -1;
	r.value = NaN;
	r.txt = '';
	r.aspect = sv.widthInDegrees / sv.heightInDegrees;
	r.quitKey = quitKey;
	r.vblInit = NaN;
	r.vblFinal = NaN;
	r.reactionTime = NaN;
	r.firstTouchTime = NaN;
end