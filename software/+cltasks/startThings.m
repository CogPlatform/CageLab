function startThings(in)
	% startThings(in)
	% Start an odd-one-out task
	% in comes from CageLab GUI or can be a struct with the following fields:
	% Example:
	%   in = struct();
	%   in.task = 'ooo'
	%   in.objectSize = 10; % size of objects in degrees
	%   in.objectSep = 15; % separation of objects in degrees
	%   in.sampleY = 0; % vertical position of sample object in degrees
	%   in.distractorY = -10; % vertical position of distractor objects in degrees
	%   in.distractorN = 2; % number of distractors (1-4)
	%   in.sampleTime = 1.0; % sample time in seconds (or [min max] range)
	%   in.delayTime = 1.0; % delay time in seconds (or [min max] range)
	%   in.delayDistractors = true; % show distractors during delay
	%   in.trialTime = 5.0; % max trial time in seconds
	%   in.targetHoldTime = 0.2; % target hold time in seconds
	%   in.folder = 'C:\data\stimuli'; % folder containing object images
	%   in.fixSize = 2; % fixation size in degrees
	%   in.fixWindow = 4; % fixation window size in degrees

	if ~exist('in','var') || isempty(in); in = clutil.checkInput(); end
	bgName = 'creammarbleD.jpg';
	prefix = 'OOO';
	in.sampleY = in.distractorY;
	
	try
		%% ============================subfunction for shared initialisation
		[sM, sv, r, sbg, rtarget, fix, aM, rM, tM, dt, quitKey, saveName] = clutil.initialise(in, bgName, prefix);

		%% ============================task specific figures
		object = clutil.getThingsImages(in);

		% for training use only
		pedestal = discStimulus('size', in.objectSize + 2,'colour',[1 1 0.5],...
			'alpha',in.pedestalOpacity,'yPosition',in.sampleY);

		% our three samples
		sampleA = imageStimulus('size', in.objectSize, 'randomiseSelection', false,...
			'yPosition',in.sampleY);
		sampleB = clone(sampleA);
		sampleC = clone(sampleA);
		
		samples = metaStimulus('stimuli',{pedestal, sampleA, sampleB, sampleC});
		samples.edit(1:4,'yPosition', in.sampleY);
		samples{2}.xPosition = -in.objectSep;
		samples{3}.xPosition = 0;
		samples{4}.xPosition = +in.objectSep;
		samples.fixationChoice = 2:4;
		samples.stimulusSets{1} = 1:4; % all stimuli
		samples.stimulusSets{2} = 1:2; % single stimulus set with pedestal + sampleA
		samples.stimulusSets{3} = 2:4; % samples only

		%% ============================ custom stimuli setup
		setup(fix, sM); % our init trial touch marker
		setup(samples, sM);
		hide(samples); % hide all stimuli at start

		%% ============================ training parameters
		r.totalPhases = 20;
		dAlpha = linspace(0,1,r.totalPhases);
		pAlpha = linspace(1,0,r.totalPhases);
		for ii = 1:20
			phases(ii).dAlpha = dAlpha(ii);
			phases(ii).pAlpha = pAlpha(ii);
		end
		if in.phase > r.totalPhases || ~in.useStaircase
			r.phase = 20;
			phases(20).dAlpha = in.distractorOpacity;
			phases(20).pAlpha = in.pedestalOpacity;
		end
		
		%% ============================ training mode parameters
		switch in.taskType
			case 'training 1'
				images = ["heptagon.png", "triangle2.png", "circle.png"];
				colours = {[1 0 0],[0 1 0],[0 0 1]};
				samples.edit(2:4,'randomiseSelection',false);
				in.doNegation = false;
				tM.window.doNegation = false;
			case 'training 2'
				pfix = ["A" "G" "L"];
				images = [" " " " " "];
				colours = {};
				samples.edit(2:4,'randomiseSelection',true);
			case 'training 3'
				images = ["heptagon.png", "rect1.png", "circle.png"];
				colours = {[1 0 0],[0 1 0],[0 0 1]};
				samples.edit(2:4,'randomiseSelection',false);
				in.doNegation = false;
				tM.window.doNegation = false;
			otherwise
				images = [];
				colours = [];
				samples.edit(2:4,'randomiseSelection',false);
		end

		%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while r.keepRunning
			if in.phase > 20; r.phase = 20; end
			switch in.taskType
				case 'training 1'
					samples{1}.alphaOut = phases(r.phase).pAlpha;
					A = randi(3);
					B = A; while B == A; B = randi(3); end
					ooo = [A A B];
					ooo = ooo(randperm(3));
					choice = find(ooo == B);
					alpha = repmat(phases(r.phase).dAlpha,1,3);
					alpha(choice) = 1;
					samples.fixationChoice = choice + 1;
					samples{1}.xPositionOut = samples{choice + 1}.xPosition;
					samples{2}.filePath = images(ooo(1));
					samples{3}.filePath = images(ooo(2));
					samples{4}.filePath = images(ooo(3));
					samples{2}.colourOut = colours{ooo(1)};
					samples{3}.colourOut = colours{ooo(2)};
					samples{4}.colourOut = colours{ooo(3)};
					samples{2}.alphaOut = alpha(1);
					samples{3}.alphaOut = alpha(2);
					samples{4}.alphaOut = alpha(3);
					samples{2}.angleOut = randi(360);
					samples{3}.angleOut = randi(360);
					samples{4}.angleOut = randi(360);
					showSet(samples, 1); % show all stimuli with pedestal
				case 'training 2'
					samples{1}.alphaOut = phases(r.phase).pAlpha;
					A = randi(3);
					B = A; while B == A; B = randi(3); end
					ooo = [A A B];
					ooo = ooo(randperm(3));
					choice = find(ooo == B);
					alpha = repmat(phases(r.phase).dAlpha,1,3);
					alpha(choice) = 1;
					samples.fixationChoice = choice+1;
					samples{1}.xPositionOut = samples{choice+1}.xPosition;
					samples{2}.filePath = string(in.folder) + filesep + "fractals" + filesep + pfix(ooo(1));
					samples{3}.filePath = string(in.folder) + filesep + "fractals" + filesep + pfix(ooo(2));
					samples{4}.filePath = string(in.folder) + filesep + "fractals" + filesep + pfix(ooo(3));
					samples{2}.alphaOut = alpha(1);
					samples{3}.alphaOut = alpha(2);
					samples{4}.alphaOut = alpha(3);
					showSet(samples, 1); % show all stimuli with pedestal
				case 'training 3'

				otherwise
					samples{2}.filePath = object.trials{r.trialN+1, "A"};
					samples{3}.filePath = object.trials{r.trialN+1, "B"};
					samples{4}.filePath = object.trials{r.trialN+1, "C"};
					showSet(samples, 3); % show all stimuli without pedestal
					samples.fixationChoice = 2:4;
			end
			
			update(samples);

			%% ============================== initialise trial variables
			r = clutil.initTrialVariables(r);
			txt = '';
			fail = false; hld = false;

			%% ============================== Wait for release
			ensureTouchRelease(false);

			%% ============================== Initiate a trial with a touch target
			[r, dt, r.vblInitT] = clutil.initTouchTrial(r, in, tM, sbg, sM, fix, quitKey, dt);

			%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% ============================== start the actual task
			if matches(string(r.touchInit),"yes")
				
				% update trial number as we enter actal trial
				r.trialN = r.trialN + 1;
				r.touchResponse = '';

				%% ================================== update the touch windows for correct targets
				[x, y] = samples.getFixationPositions;
				% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
				tM.updateWindow(x, y, repmat(in.objectSize/1.9,1,length(x)),...
				repmat(in.doNegation,1,length(x)), ones(1,length(x)), true(1,length(x)),...
				repmat(in.trialTime,1,length(x)), ...
				repmat(in.targetHoldTime,1,length(x)), ones(1,length(x)));

				%% Get our start time
				if ~isempty(sbg); draw(sbg); end
				vbl = flip(sM);
				r.stimOnsetTime = vbl;
				r.vblInit = vbl + sv.ifi; %start is actually next flip
				syncTime(tM, r.vblInit);

				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				while isempty(r.touchResponse) && vbl <= (r.vblInit + in.trialTime)
					if ~isempty(sbg); draw(sbg); end
					draw(samples);
					if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
						drawText(sM, txt);
						[xy] = sM.toPixels([tM.x tM.y]);
						Screen('glPoint', sM.win, [1 0 0], xy(1), xy(2), 10);
					end
					vbl = flip(sM);
					[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch] = testHold(tM,'yes','no');
					if tch
						r.reactionTime = vbl - r.vblInit;
						r.anyTouch = true;
					end
					if in.debug; txt = sprintf('Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i fail:%i tch:%i WR: %.1f WInit: %.2f WHold: %.2f WRel: %.2f WX: %.2f WY: %.2f',...
						r.touchResponse, tM.x, tM.y, hld, r.hldtime, rel, reli, ...
						se, fail, tch, tM.window.radius,tM.window.init, ...
						tM.window.hold,tM.window.release,tM.window.X, ...
						tM.window.Y); 
					end
					[~,~,c] = KbCheck();
					if c(quitKey); r.keepRunning = false; break; end
				end
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			end
			
			r.vblFinal = GetSecs;
			r.value = hld;
			
			%% ============================== check logic of task result
			if fail || hld == -100 || matches(r.touchResponse,'no') || matches(r.touchInit,'no')
				r.result = 0;
			elseif matches(r.touchResponse,'yes')
				r.result = 1;
			else
				r.result = -1;
			end

			%% ============================== Wait for release
			ensureTouchRelease(true);

			%% ============================== update this trials reults
			[dt, r] = clutil.updateTrialResult(in, dt, r, rtarget, sbg, sM, tM, rM, aM);

		end % while keepRunning
		target = [];
		clutil.shutDownTask(sM, sbg, fix, samples, target, rtarget, tM, rM, saveName, dt, in, r);

	catch ME
		getReport(ME)
		try reset(samples); end %#ok<*TRYNC>
		try reset(fix); end
		try reset(rtarget); end
		try reset(sbg); end
		try close(sM); end
		try close(tM); end
		try close(rM); end
		try close(aM); end
		try Priority(0); end
		try ListenChar(0); end
		try RestrictKeysForKbCheck([]); end
		try ShowCursor; end
		rethrow(ME)
	end


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% make sure the subject is NOT touching the screen
	function ensureTouchRelease(afterResult)
		if ~exist('afterResult','var'); afterResult = false; end
		if ~isempty(sbg); draw(sbg); else; drawBackground(sM, in.bg); end
		if in.debug; drawText(sM,'Please release touchscreen...'); end
		svbl = flip(sM); blue = 0;
		if ~afterResult; when="BEFORE"; else when="AFTER"; end
		while isTouch(tM)
			now = WaitSecs(0.2);
			fprintf("Subject holding screen %s trial end %.1fsecs...\n", when, now-svbl);
			if now - svbl >= 1
				drawBackground(sM,[1 blue 1]);
				flip(sM);
				blue = abs(~blue);
			end
			if afterResult && now - svbl >= 3
				r.result = -1;
				fprintf("INCORRECT: Subject kept holding screen %s trial for %.1fsecs...\n", when, now-svbl);
				break;
			end
		end
		if ~isempty(sbg); draw(sbg); else; drawBackground(sM, in.bg); end
		flip(sM);
	end

end
