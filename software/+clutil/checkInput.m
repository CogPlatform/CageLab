function in = checkInput()
    %V1.02
	pth = fileparts(fileparts(mfilename('fullpath')));
    in.density = 70;
    in.distance = 30;
    in.timeOut = 4;

    in.fg = [1 1 0.75];
    in.bg = [0.5 0.5 0.5];

	in.IP = '127.0.0.1';
	in.port = 9012;

    in.folder = [pth filesep 'resources'];
    in.debug = true;
    in.dummy = true;
	
    in.audio = true;
	in.audioDevice = [];
    in.audioVolume = 0.2;

	in.phase = 1;
	in.stimulusType = 'Picture';
    in.task = 'generic';
	in.taskType = 'normal';

	in.name = 'simulcra';
    in.rewardmode = 1;
    in.volume = 250;
    in.random = 1;
    in.screen = 0;
    in.smartBackground = true;
    
	in.correctBeep = 3000;
    in.incorrectBeep = 400;

	in.trialTime = 5;
   
	in.rewardPort = '/dev/ttyACM0';
    in.rewardTime = 200;

	in.randomReward = 30;
    in.randomProbability = 0.25;
    in.randomReward = 0;
    in.volume = 250;

    in.nTrialsSample = 10;
	in.stepForward = 10;
	in.stepPercent = 80;
	in.stepBack = 10;

	in.doNegation = true;
    in.negationBuffer = 2;
    in.exclusionZone = [];
    in.drainEvents = true;
    in.strictMode = true;
    in.negateTouch = true;
    in.touchDevice = 1;
    in.touchDeviceName = 'ILITEK-TP';
    
	in.stimulus = 1;
	in.maxSize = 50;
	in.minSize = 4;
	in.initPosition = [0 4];
    in.initSize = 4;
    in.target1Pos = [-5 -5];
    in.target2Pos = [5 -5];
    in.targetSize = 10;
    in.startY = -10;
    in.distractorY = -1;
	
	in.zmq = [];
	
end
