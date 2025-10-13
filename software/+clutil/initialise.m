function [sM, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName, in] = initialise(in, bgName, prefix)
	%[s, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName, in] = +clutils.initialise(in, bgName);
	arguments (Input)
		in struct
		bgName (1,:) char {mustBeNonempty} % background image filename
		prefix (1,:) char = '' % prefix to add to save name
	end
	arguments (Output)
		sM (1,1) screenManager
		sv struct
		r struct
		sbg % can be [] or imageStimulus; leave untyped to allow empty
		rtarget (1,1) imageStimulus
		fix (1,1) discStimulus
		a (1,1) audioManager
		rM (1,1) PTBSimia.pumpManager
		tM (1,1) touchManager
		dt (1,1) touchData
		quitKey (1,1) double
		saveName (1,:) char
		in struct
	end
	
	windowed = [];
	sf = [];

	%% =========================== debug mode?
	if (in.screen == 0 || max(Screen('Screens'))==0) && in.debug
		if IsLinux || IsOSX
			sf = kPsychGUIWindow; windowed = [0 0 1600 900]; 
		else
			PsychDebugWindowConfiguration;
		end
	end
	
	% initial config for PTB
	PsychDefaultSetup(2);
	try 
		!xset -dpms s off
	end
	
	%% ============================ screen & background
	sM = screenManager('screen', in.screen,'blend', true,...
		'pixelsPerCm', in.density, 'distance', in.distance,...
		'disableSyncTests', true, 'hideFlash', true, ...
		'backgroundColour', in.bg,'windowed', windowed,'specialFlags', sf);
	if in.smartBackground
		sbg = imageStimulus('alpha', 1, 'filePath', [in.folder filesep 'background' filesep bgName]);
	else 
		sbg = [];
	end

	%% s============================ stimuli
	rtarget = imageStimulus('colour', [0 1 0], 'filePath', 'star.png');
	fix = discStimulus('size', in.initSize, 'colour', [1 1 0.5], 'alpha', 0.8,...
			'xPosition', in.initPosition(1),'yPosition', in.initPosition(2));
	
	%% ============================ audio
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
		dummy = false;
	else %dummy mode pass true to constructor
		dummy = true;
	end
	rM = PTBSimia.pumpManager(dummy); 
	
	%% ============================setup
	sv = open(sM); % open screen
	if in.smartBackground
		sbg.size = max([sv.widthInDegrees sv.heightInDegrees]);
		setup(sbg, sM);
		if sbg.heightD < sv.heightInDegrees
			sbg.sizeOut = sbg.sizeOut + (sv.heightInDegrees - sbg.heightD);
			update(sbg);
		end
		draw(sbg);
	end
	
	drawTextNow(sM,['Initialising CageLab V' clutil.version '...']);
	
	rtarget.size = 5;
	rtarget.xPosition = sv.rightInDegrees - 4;
	rtarget.yPosition = sv.topInDegrees + 4;
	setup(rtarget, sM);
	in.rRect = rtarget.mvRect;

	setup(fix, sM);
	setup(tM, sM);
	createQueue(tM);
	start(tM);

	%% ================================ save file name
	% but remember alyx comes from remote machine, need to regenerate
	% paths.
	if isfield(in,'alyx') && isa(in.alyx,'alyxManager')
		alyx = in.alyx;
	else
		alyx = alyxManager();
	end
	try in = rmfield(in,'alyx'); end %#ok<*TRYNC>
	checkPaths(alyx);
	alyx.user = in.session.researcherName;
	alyx.lab = in.session.labName;
	alyx.subject = in.session.subjectName;

	[in.alyxPath, in.sessionID, in.dateID, in.alyxName] = alyx.getALF(in.name, in.lab, true);
	in.saveName = [ in.alyxPath filesep 'opticka.raw.' prefix in.alyxName '.mat'];
	in.diaryName = [ in.alyxPath filesep '_matlab_diary.' prefix in.alyxName '.log'];
	diary(in.diaryName);
	saveName = in.saveName;
	fprintf('===>>> CageLab Save: %s', in.saveName);

	%% ================================ touch data
	dt = touchData();
	dt.name = in.alyxName;
	dt.subject = in.name;
	dt.data(1).comment = [in.task ' ' in.command ' - CageLab V' clutil.version];
	dt.data(1).result = [];
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

	%% ============================ settings
	quitKey = KbName('escape');
	RestrictKeysForKbCheck(quitKey);
	Screen('Preference','Verbosity',4);
		
	if ~in.debug; Priority(1); end
	if ~in.debug || ~in.dummy; HideCursor; end

	[~,hname] = system('hostname');
	hname = strip(hname);
	if isempty(hname); hname = 'unknown'; end

	%% ============================ run variables
	r = [];
	r.hostname = hname;
	r.saveName = in.saveName;
	r.alyx = alyx;
	r.alyxPath = in.alyxPath;
	r.alyxName = in.alyxName;
	r.sessionID = in.sessionID;
	if in.remote
		r.remote = true;
		r.zmq = in.zmq;
	else
		r.remote = false;
		r.zmq = [];
	end
	try in = rmfield(in,'zmq'); end
	r.broadcast = matmoteGO.broadcast();
	r.status = matmoteGO.status();
	r.keepRunning = true;
	r.phase = in.phase;
	r.correctRate = NaN;
	r.correctRateRecent = NaN;
	r.loopN = 0;
	r.trialN = 0;
	r.trialW = 0;
	r.phaseN = 0;
	r.phaseMax = r.phase;
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
	r.startTime = NaN;
	r.endTime = NaN;
	
	%% enable task status to cogmoteGO
	currentStatus = r.status.updateStatusToRunning();
	disp(currentStatus.Body.Data);

	%% broadcast the initial status to cogmoteGO
	clutil.broadcastTrial(in, r, dt, true);

end