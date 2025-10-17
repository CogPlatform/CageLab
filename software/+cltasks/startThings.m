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
	
	try
		%% ============================subfunction for shared initialisation
		[sM, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName] = clutil.initialise(in, bgName, prefix);

		%% ============================task specific figures
		
		[object, file] = clutil.getThingsImages(in);

		% for training use only
		pedestal = discStimulus('size', in.objectSize + 1,'colour',[0.5 1 1],'alpha',0.3,'yPosition',in.sampleY);

		% our three samples
		sampleA = imageStimulus('size', in.objectSize, 'randomiseSelection', false,...
			'filePath', 'star.png','yPosition',in.sampleY);
		sampleB = clone(sampleA);
		sampleC = clone(sampleA);
		
		samples = metaStimulus('stimuli',{pedestal, sampleA, sampleB, sampleC});
		samples.edit(1:3,'yPosition', in.sampleY);
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

		%% ============================ training mode parameters
		switch in.taskType, 
			case 'training 1'
				images = ["heptagon.png", "rectangle.png", "circle.png"];
				colours = {[1 0 0],[0 1 0],[0 0 1]};
				samples.edit(2:4,'randomizeSelection',false);
				in.doNegation = false;
				tM.window.doNegation = false;
			case 'training 2'
				pfix = ["A" "G" "L"];
				images = [" " " " " "];
				colours = {};
				samples.edit(2:4,'randomizeSelection',true);
				
			case 'training 3'
				images = ["heptagon.png", "rectangle.png", "circle.png"];
				colours = {[1 0 0],[0 1 0],[0 0 1]};
			otherwise
				images = [];
				colours = [];
				samples.edit(2:4,'randomizeSelection',false);
		end

		%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while r.keepRunning

			switch in.taskType
				case 'training 1'
					A = randi(3);
					B = A; while B == A; B = randi(3); end
					ooo = [A A B];
					ooo = ooo(randperm(3));
					choice = find(ooo == B);
					samples.fixationChoice = choice;
					samples{2}.filePath = images(ooo(1));
					samples{3}.filePath = images(ooo(2));
					samples{4}.filePath = images(ooo(3));
					samples.edit(2,'colourOut',colours{ooo(1)});
					samples.edit(3,'colourOut',colours{ooo(2)});
					samples.edit(4,'colourOut',colours{ooo(3)});
					showSet(samples, 1); % show all stimuli with pedestal
					samples.fixationChoice = 2:4;
				case 'training 2'
					A = randi(3);
					B = A; while B == A; B = randi(3); end
					ooo = [A A B];
					ooo = ooo(randperm(3));
					choice = find(ooo == B);
					samples.fixationChoice = choice;
					samples{2}.filePath = "in.folder" + filesep + "fractals" + filesep + pfix(ooo(1));;
					samples{3}.filePath = "in.folder" + filesep + "fractals" + filesep + pfix(ooo(2));
					samples{4}.filePath = "in.folder" + filesep + "fractals" + filesep + pfix(ooo(3));
					showSet(samples, 1); % show all stimuli with pedestal
					
				case 'training 3'

				otherwise
					samples{1}.filePath = object.trials(r.trialN,1);
					samples{2}.filePath = object.trials(r.trialN,2);
					samples{3}.filePath = object.trials(r.trialN,3);
					showSet(samples, 3); % show all stimuli without pedestal
					samples.fixationChoice = 2:4;
			end
			
			update(samples);

			%% ============================== initialise trial variables
			r = clutil.initTrialVariables(r);
			txt = '';
			fail = false; hld = false;

			%% ============================== Initiate a trial with a touch target
			[r, dt, r.vblInitT] = clutil.initTouchTrial(r, in, tM, sbg, sM, fix, quitKey, dt);

			%% ============================== start the actual task
			if matches(string(r.touchInit),"yes")
				% update trial number as we enter actal trial
				r.touchResponse = '';

				%% ================================== update the touch windows for correct targets
				[x, y] = targets.getFixationPositions;
				% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
				tM.updateWindow(x, y, repmat(target.size/2,1,length(x)),...
				repmat(in.doNegation,1,length(x)), ones(1,length(x)), true(1,length(x)),...
				repmat(in.trialTime,1,length(x)), ...
				repmat(in.targetHoldTime,1,length(x)), ones(1,length(x)));

				%% Get our start time
				if ~isempty(sbg); draw(sbg); end
				vbl = flip(sM);
				r.stimOnsetTime = vbl;
				r.vblInit = vbl + sv.ifi; %start is actually next flip
				syncTime(tM, r.vblInit);

				while isempty(r.touchResponse) && vbl <= (r.vblInit + in.trialTime)
					if ~isempty(sbg); draw(sbg); end
					draw(samples);
					if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
						drawText(sM, txt);
						[xy] = sM.toPixels([tM.x tM.y]);
						Screen('glPoint', sM.win, [1 0 0], xy(1), xy(2), 10);
					end
					vbl = flip(sM);
					[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch] = testHoldRelease(tM,'yes','no');
					if tch
						r.reactionTime = vbl - r.vblInit;
						r.anyTouch = true;
					end
					if in.debug; txt = sprintf('Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i fail:%i tch:%i WR: %.1f WInit: %.2f WHold: %.2f WRel: %.2f WX: %.2f WY: %.2f',...
						r.touchResponse, tM.x, tM.y, hld, r.hldtime, rel, reli, ...
						se, fail, tch, tM.window.radius,tM.window.init, ...
						tM.window.hold,tM.window.release,tM.window.X, ...
						tM.window.Y); end
					[~,~,c] = KbCheck();
					if c(quitKey); r.keepRunning = false; break; end
				end
			end
			
			%% ============================== check logic of task result
			r.vblFinal = GetSecs;
			r.value = hld;
			if fail || hld == -100 || matches(r.touchResponse,'no') || matches(r.touchInit,'no')
				r.result = 0;
			elseif matches(r.touchResponse,'yes')
				r.result = 1;
			else
				r.result = -1;
			end

			%% ============================== Wait for release, 
			% stops subject just holding on the screen
			if ~isempty(sbg); draw(sbg); else; drawBackground(sM, in.bg); end
			if in.debug; drawText(s,'Please release touchscreen...'); end
			flip(sM);
			while isTouch(tM)
				WaitSecs(0.5);
			end
			if ~isempty(sbg); draw(sbg); else; drawBackground(sM, in.bg); end
			flip(sM);

			%% ============================== update this trials reults
			[dt, r] = clutil.updateTrialResult(in, dt, r, rtarget, sbg, sM, tM, rM, a);

		end % while keepRunning
		target = [];
		clutil.shutDownTask(sM, sbg, fix, targets, target, rtarget, tM, rM, saveName, dt, in, r);

	catch ME
		getReport(ME)
		try reset(rtarget); end %#ok<*TRYNC>
		try reset(fix); end
		try reset(targets); end
		try close(sM); end
		try close(tM); end
		try close(rM); end
		try close(a); end
		try Priority(0); end
		try ListenChar(0); end
		try ShowCursor; end
		sca;
	end
end
