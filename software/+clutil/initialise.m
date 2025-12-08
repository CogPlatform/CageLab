function [sM, sv, r, sbg, rtarget, fix, aM, rM, tM, dt, quitKey, saveName, in] = initialise(in, bgName, prefix)
	%[sM, sv, r, sbg, rtarget, fix, aM, rM, tM, dt, quitKey, saveName, in] = initialise(in, bgName, prefix)
	% INITIALISE orchestrates the CageLab runtime by configuring display/audio/touch hardware,
	% instantiating stimulus and reward managers, preparing Alyx bookkeeping, and returning the
	% state structs (`sv`, `r`, `dt`, etc.) required for downstream task control.
	
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
		aM (1,1) audioManager
		rM (1,1) PTBSimia.pumpManager
		tM (1,1) touchManager
		dt (1,1) touchData
		quitKey (1,1) double
		saveName (1,:) char
		in struct
	end

	%% ========================== get hostname
	[~,hname] = system('hostname');
	hname = strip(hname);
	if isempty(hname); hname = 'unknown'; end
	
	% Provide defaults for optional Psychtoolbox window overrides used in debug mode.
	%% =========================== debug mode?
	% When no full PTB screen is available, fall back to a windowed context so development
	% can proceed without physical rig hardware.
	windowed = [];
	sf = [];
	if (in.screen == 0 || max(Screen('Screens'))==0) && in.debug
		if IsLinux || IsOSX
			sf = kPsychGUIWindow; windowed = [0 0 1600 900]; 
		else
			PsychDebugWindowConfiguration;
		end
	end
	
	% initial config for PTB
	PsychDefaultSetup(2);
	
	% Prevent the OS from blanking the display or entering power-save while experiments run.
	try system('xdotool key shift'); end
	try system('xset dpms force on; xset s off'); end
	
	%% ============================ screen & background
	% Create the main screen manager and optional smart background image that matches rig geometry.
	sM = screenManager('screen', in.screen,'blend', in.useBlending,...
		'pixelsPerCm', in.density, 'distance', in.distance,...
		'disableSyncTests', in.disableSync, 'hideFlash', true, ...
		'backgroundColour', in.bg,'windowed', windowed,'specialFlags', sf);
	if in.smartBackground
		sbg = imageStimulus('crop','stretch','alpha', 1, 'filePath', [in.folder filesep 'background' filesep bgName]);
	else 
		sbg = [];
	end

	%% ============================ stimuli
	% Instantiate the on-screen reward target and fixation stimuli with default positions/sizes.
	rtarget = imageStimulus('size', 2, 'colour', [0.2 1 0], 'filePath', 'heptagon.png');
	fix = discStimulus('size', in.initSize, 'colour', [1 1 0.5], 'alpha', 0.5,...
			'xPosition', in.initPosition(1),'yPosition', in.initPosition(2));
	
	%% ============================ audio
	% Prepare the audio manager, respecting silent-mode/debug flags, and preload feedback beeps.
	aM = audioManager('device',in.audioDevice);
	if in.debug; aM.verbose = true; end
	if in.audioVolume == 0 || in.audio == false
		aM.silentMode = true; 
	else
		setup(aM);
		beep(aM,in.correctBeep,0.1,in.audioVolume);
		beep(aM,in.incorrectBeep,0.1,in.audioVolume);
	end
	
	%% ============================touch
	% Configure the touch manager (real or dummy) and align negation/verbosity with session settings.
	tM = touchManager('isDummy',in.dummy,'device',in.touchDevice,...
		'deviceName',in.touchDeviceName,'exclusionZone',in.exclusionZone,...
		'drainEvents',in.drainEvents,'trackID',in.trackID);
	tM.window.doNegation = in.doNegation;
	tM.window.negationBuffer = in.negationBuffer;
	if in.debug || in.verbose; tM.verbose = true; end

	%% ============================reward
	% Pump manager runs in dummy mode when hardware rewards are disabled.
	if in.reward
		dummy = false;
	else %dummy mode pass true to constructor
		dummy = true;
	end
	rM = PTBSimia.pumpManager(dummy);
	
	%% ============================setup
	% Open the display, size the background stimulus to the current rig, and present initial text.
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
	lines = string(in.task+" "+in.command+" - CageLab V"+clutil.version+" on "+hname+" @ "+string(datetime('now')));
	drawTextNow(sM,char(lines(1)));
	
	rtarget.size = 5;
	rtarget.xPosition = sv.rightInDegrees - 4;
	rtarget.yPosition = sv.topInDegrees + 4;
	setup(rtarget, sM);
	in.rRect = rtarget.mvRect;

	setup(fix, sM);
	setup(tM, sM);
	try
		createQueue(tM);
	catch ME
		try displayInfo(tM); end
		rethrow(ME);
	end
	start(tM);

	%% ================================ save file name
	% Set up Alyx context locally (even when the struct was passed remotely) and derive save paths.
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

	lines(2) = in.saveName;
	lines(3) = in.diaryName;
	writelines(lines, "~/cagelab-start.txt");

	%% ================================ touch data
	% Seed the touch-data log with session metadata so downstream tasks can append trial info.
	dt = touchData();
	dt.name = in.alyxName;
	dt.subject = in.name;
	dt.data(1).comment = lines(1);
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
	% Lock keyboard input to the quit key, reduce verbosity, and set OS-level priority/cursor state.
	quitKey = KbName('escape');
	shotKey = KbName('F1');
	RestrictKeysForKbCheck([quitKey shotKey]);
	Screen('Preference','Verbosity',4);
		
	if ~in.debug; Priority(1); end
	if ~in.debug || ~in.dummy; HideCursor; end

	%% ============================ run variables
	% r aggregates runtime status used by task loops, Alyx syncing, and remote control hooks.
	r = [];
	r.hostname = hname;
	r.saveName = in.saveName;
	r.version = clutil.version;
	r.alyx = alyx; % alyx manager object
	r.alyxPath = in.alyxPath;
	r.alyxName = in.alyxName;
	r.sessionID = in.sessionID; % alyx session ID
	if in.remote
		r.remote = true;
		r.zmq = in.zmq;
	else
		r.remote = false;
		r.zmq = [];
	end
	try in = rmfield(in,'zmq'); end % clean up input struct
	r.broadcast = matmoteGO.broadcast(); % initialize data broadcast object
	r.status = matmoteGO.status(); % initialize experiment status object
	r.keepRunning = true;
	r.phase = in.phase; % phase of the experiment for those with automatic progression
	r.phaseinit = r.phase;
	r.totalPhases = r.phase;
	r.correctRate = NaN; % overall correct rate
	r.correctRateRecent = NaN; % recent correct rate
	r.loopN = 0; % number of loops completed
	r.trialN = 0; % number of trials initiated
	r.trialW = 0; % number of trials won
	r.phaseN = 0; 
	r.phaseMax = r.phase; % maximum phase number
	r.stimulus = 1; % current stimulus index
	r.randomRewardTimer = GetSecs; % timer for random rewards
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
	
	%% task status set to true for cogmoteGO
	% Update CogmoteGO dashboards so operators know the task is live before the first trial.
	currentStatus = r.status.updateStatusToRunning();
	disp('===>>> CogmoteGO Task Status: ');
	disp(currentStatus.Body.Data);

	%% broadcast the initial status to cogmoteGO
	% Push an initial status packet so remote monitors have the starting state.
	clutil.broadcastTrial(in, r, dt, true);
end