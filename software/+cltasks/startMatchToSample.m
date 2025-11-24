function startMatchToSample(in)
	% startMatchToSample(in)
	% Start a match-to-sample task (MTS, DMTS or DNTS)
	% in comes from CageLab GUI or can be a struct with the following fields:
	% Example:
	%   in = struct();
	%   in.task = 'mts'; % 'mts', 'dmts' or 'dnts'
	%   in.object = 'fractals'; % 'fractals', 'quaddles' or 'flowers'
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
	if matches(in.task,'mts')
		bgName = 'abstract2.jpg';
		prefix = 'MTS';
	elseif matches(in.task,'dmts')
		bgName = 'abstract3.jpg';
		prefix = 'DMTS';
	elseif matches(in.task,'dnts')
		bgName = 'creammarbleB.jpg';
		prefix = 'DNTS';
	end

	try
		%% ============================subfunction for shared initialisation
		[sM, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName] = clutil.initialise(in, bgName, prefix);

		%% ============================task specific figures
		switch lower(in.object)
			case 'fractals'
				pfix = ["A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L"];
				pfix1 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix1);
				pfix2 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix2);
				pfix3 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix3);
				pfix4 = pfix(randi(length(pfix)));
				pfix = setxor(pfix3,pfix4);
				pfix5 = pfix(randi(length(pfix)));
			case 'quaddles'
				pfix = ["A" "B" "C" "D" "E" "F" "G" "H"];
				pfix1 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix1);
				pfix2 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix2);
				pfix3 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix3);
				pfix4 = pfix(randi(length(pfix)));
				pfix = setxor(pfix3,pfix4);
				pfix5 = pfix(randi(length(pfix)));
			case 'flowers'
				[pfix1, pfix2, pfix3, pfix4, pfix5] = deal("");
		end
		pedestal = discStimulus('size', in.objectSize + 1,'colour',[0.5 1 1],'alpha',0.3,'yPosition',in.sampleY);
		sample = imageStimulus('size', in.objectSize, 'randomiseSelection', false,...
			'filePath', string(in.folder) + filesep + in.object + filesep + pfix1,'yPosition',in.sampleY);
		target = clone(sample);
		target.yPosition = in.distractorY;
		distractor1 = clone(target);
		distractor1.filePath = string(in.folder) + filesep + in.object + filesep + pfix2;
		distractor2 = clone(target);
		distractor2.filePath = string(in.folder) + filesep + in.object + filesep + pfix3;
		distractor3 = clone(target);
		distractor3.filePath = string(in.folder) + filesep + in.object + filesep + pfix4;
		distractor4 = clone(target);
		distractor4.filePath = string(in.folder) + filesep + in.object + filesep + pfix5;
		targets = metaStimulus('stimuli',{pedestal, sample, target, distractor1, distractor2, distractor3, distractor4});
		targets.fixationChoice = 3;
		targets.stimulusSets{1} = 1:7; % all stimuli for mts
		targets.stimulusSets{2} = 1:2; % pedestal + sample
		targets.stimulusSets{3} = 3; %target 
		targets.stimulusSets{4} = 3:7; % all targets + distractors

		% distractors to optionally show in the delay period
		distractor5 = clone(distractor2);
		distractor5.xPosition = -in.objectSep;
		distractor6 = clone(distractor3);
		distractor6.xPosition = 0;
		distractor7 = clone(distractor4);
		distractor7.xPosition = +in.objectSep;
		delayDistractors = metaStimulus('stimuli',{distractor5, distractor6, distractor7});
		delayDistractors.edit(1:3,'alpha',0.75);
		delayDistractors.edit(1:3,'yPosition',in.sampleY);

		%% ============================ custom stimuli setup
		setup(fix, sM);
		setup(targets, sM);
		setup(delayDistractors, sM);
		show(delayDistractors);

		%% ============================ training, only use 1 arget
		if contains(in.taskType, 'training')
			in.doNegation = false;
			tM.window.doNegation = false;
			in.distractorN = 0;
			in.delayDistractors = false;
			r.sampleTime = 1;
			r.delayTime = 0.1;
		end

		%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while r.keepRunning
			pedestal.xPositionOut = 0;
			pedestal.yPositionOut = in.sampleY;
			sample.xPositionOut = 0;
			sample.yPositionOut = in.sampleY;
			sep = in.objectSep;
			N = in.distractorN;
			Y = in.distractorY;
			targets.fixationChoice = 3;
			switch N
				case 1
					[~,idx] = Shuffle([1 2]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand];
					xy = xy(:,idx);
					target.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2), true);
					targets.stimulusSets{4} = [3 4];
					if matches(in.task,"dnts")
						targets.fixationChoice = 4;
					end
				case 2
					[~,idx] = Shuffle([1 2 3]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand];
					xy = xy(:,idx);
					target.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2), true);
					distractor2.updateXY(xy(1,3), xy(2,3), true);
					targets.stimulusSets{4} = [3 4 5];
					if matches(in.task,"dnts")
						targets.fixationChoice = [4 5];
					end
				case 3
					[~,idx] = Shuffle([1 2 3 4]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand Y-rand];
					xy = xy(:,idx);
					target.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2), true);
					distractor2.updateXY(xy(1,3), xy(2,3), true);
					distractor3.updateXY(xy(1,4), xy(2,4), true);
					targets.stimulusSets{4} = [3 4 5 6];
					if matches(in.task,"dnts")
						targets.fixationChoice = [4 5 6];
					end
				otherwise
					[~,idx] = Shuffle([1 2 3 4 5]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand Y-rand Y+rand];
					xy = xy(:,idx);
					target.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2), true);
					distractor2.updateXY(xy(1,3), xy(2,3), true);
					distractor3.updateXY(xy(1,4), xy(2,4), true);
					distractor4.updateXY(xy(1,5), xy(2,5), true);
					targets.stimulusSets{4} = [3 4 5 6 7];
					if matches(in.task,"dnts")
						targets.fixationChoice = [4 5 6 7];
					end
			end

			if contains(in.taskType, 'training')
				targets.stimulusSets{1} = [1 2 3];
				if matches(in.task,"dnts")
					targets.stimulusSets{4} = 4;
				else
					targets.stimulusSets{3} = 3;
				end
			end

			hide(targets);
			if matches(in.task,"mts")
				showSet(targets, 1); % pedestal, target and distractors for mts
			else
				showSet(targets, 2); % only pedestal + sample
			end

			rs = randi(sample.nImages); r.stimulus = rs;
			sample.selectionOut = rs;
			target.selectionOut = rs;
			rr = rs;
			for jj = 4:7
				rn = randi(targets{jj}.nImages);
				while any(rn == rr)
					rn = randi(targets{jj}.nImages);
				end
				targets{jj}.selectionOut = rn;
				rr = [rr rn];
			end

			update(targets);
			update(delayDistractors);

			%% ============================== initialise trial variables
			r = clutil.initTrialVariables(r);
			txt = '';
			fail = false; hld = false;

			%% ============================== Wait for release
			ensureTouchRelease(false);

			%% =============================== timers for sample and delay
			%  sampleTime and delayTime can be single or range values
			if isscalar(in.sampleTime)
				r.sampleTime = in.sampleTime;
			else
				r.sampleTime = in.sampleTime(1) + (in.sampleTime(2)-in.sampleTime(1))*rand;
			end
			if isscalar(in.delayTime)
				r.delayTime = in.delayTime;
			else
				r.delayTime = in.delayTime(1) + (in.delayTime(2)-in.delayTime(1))*rand;
			end

			%% Initiate a trial with a touch target
			[r, dt, r.vblInitT] = clutil.initTouchTrial(r, in, tM, sbg, sM, fix, quitKey, dt);

			%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% ===============================start the actual task
			if matches(string(r.touchInit),"yes")
				
				% update trial number as we enter actal trial
				r.trialN = r.trialN + 1;
				r.touchResponse = '';

				if matches(in.task,["dmts","dnts"])
					vbl = GetSecs; vblInit = vbl + sv.ifi;
					% sample time
					while vbl <= vblInit + r.sampleTime
						if ~isempty(sbg); draw(sbg); end
						draw(targets);
						if in.debug; drawText(sM, 'Sample period...'); end
						vbl = flip(sM);
						if isTouch(tM)
							r.touchResponse = 'no';
							break
						end
						[~,~,c] = KbCheck(); if c(quitKey); r.keepRunning = false; break; end
					end
					% delay time
					vblInit = vbl + sv.ifi;
					while vbl <= vblInit + r.delayTime
						if ~isempty(sbg); draw(sbg); end
						if in.delayDistractors; draw(delayDistractors); end
						vbl = flip(sM);
						if isTouch(tM)
							r.touchResponse = 'no';
							break
						end
					end
					% show distractors
					showSet(targets, 4); %just target and distractors
				end

				%% ================================== update the touch windows for correct targets
				[x, y] = targets.getFixationPositions;
				% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
				tM.updateWindow(x, y, repmat(target.size/2,1,length(x)),...
				repmat(in.doNegation,1,length(x)), ones(1,length(x)), true(1,length(x)),...
				repmat(in.trialTime,1,length(x)), ...
				repmat(in.targetHoldTime,1,length(x)), ones(1,length(x)));

				%% Get our start time
				vbl = GetSecs;
				r.stimOnsetTime = vbl;
				r.vblInit = vbl + sv.ifi; %start is actually next flip
				syncTime(tM, r.vblInit);

				while isempty(r.touchResponse) && vbl <= (r.vblInit + in.trialTime)
					if ~isempty(sbg); draw(sbg); end
					draw(targets);
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
						tM.window.Y); end
					[~,~,c] = KbCheck();
					if c(quitKey); r.keepRunning = false; break; end
				end
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
			[dt, r] = clutil.updateTrialResult(in, dt, r, rtarget, sbg, sM, tM, rM, a);

		end % while keepRunning
		target = [];
		clutil.shutDownTask(sM, sbg, fix, targets, target, rtarget, tM, rM, saveName, dt, in, r);

	catch ME
		getReport(ME)
		try r.status.updateStatusToStopped();end
		try clutil.broadcastTrial(in, r, dt, false); end
		try system('xset s 300 dpms 600 0 0'); end
		try reset(rtarget); end %#ok<*TRYNC>
		try reset(fix); end
		try reset(targets); end
		try reset(sbg); end
		try close(sM); end
		try close(tM); end
		try close(rM); end
		try close(a); end
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
