function [s, sv, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName, in] = initialise(in, bgName, prefix, windowed, sf)
	%[s, sbg, rtarget, a, rM, tM] = +clutils.initialise(pth, in, bgName, prefix, windowed, sf);
	windowed = [];
	sf = [];

	% =========================== debug mode?
	if (in.screen == 0 || max(Screen('Screens'))==0) && in.debug
		sf = kPsychGUIWindow; windowed = [0 0 1300 800]; 
	end
	
	%% ============================screen & background
	s = screenManager('screen',in.screen,'blend',true,'pixelsPerCm',...
		in.density, 'distance', in.distance,...
		'backgroundColour',in.bg,'windowed',windowed,'specialFlags',sf);
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
	if in.reward
		rM = PTBSimia.pumpManager(); 
	else %dummy mode
		rM = PTBSimia.pumpManager(true); 
	end
	
	%% ============================setup
	sv = open(s);
	if in.smartBackground
		sbg.size = max([sv.widthInDegrees sv.heightInDegrees]);
		setup(sbg, s);
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
	dt.data(1).in = in;

	%% ============================settings
	quitKey = KbName('escape');
	RestrictKeysForKbCheck(quitKey);
	Screen('Preference','Verbosity',4);
		
	if ~in.debug && ~in.dummy; Priority(1); HideCursor; end
	
end