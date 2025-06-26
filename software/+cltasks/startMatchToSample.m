function startMatchToSample(in)
	if ~exist('in','var') || isempty(in); in = clutil.checkInput(pth); end
	if matches(in.task,'mts')
		bgName = 'abstract2.jpg';
		prefix = 'MTS';
	else
		bgName = 'abstract3.jpg';
		prefix = 'DMTS';
	end
	
	try
		%% ============================subfunction for shared initialisation
		[s, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName] = clutil.initialise(in, bgName, prefix);

		%% ============================task specific figures
		switch lower(in.object)
			case 'fractals'
				pfix = ["A" "B" "C" "D" "E" "F" "G" "H" "I"];
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
		target1 = imageStimulus('size', in.objectSize, 'randomiseSelection', false,...
			'filePath', string(in.folder) + filesep + in.object + filesep + pfix1,'yPosition',in.sampleY);
		target2 = clone(target1);
		target2.yPosition = in.distractorY;
		distractor1 = clone(target2);
		distractor1.filePath = string(in.folder) + filesep + in.object + filesep + pfix2;
		distractor2 = clone(target2);
		distractor2.filePath = string(in.folder) + filesep + in.object + filesep + pfix3;
		distractor3 = clone(target2);
		distractor3.filePath = string(in.folder) + filesep + in.object + filesep + pfix4;
		distractor4 = clone(target2);
		distractor4.filePath = string(in.folder) + filesep + in.object + filesep + pfix5;
		set = metaStimulus('stimuli',{pedestal, target1, target2, distractor1, distractor2, distractor3, distractor4});
		set.fixationChoice = 3;
		set.stimulusSets{1} = 1:7;
		set.stimulusSets{2} = 1:7;
		set.stimulusSets{3} = 1:2;
		set.stimulusSets{4} = 3:7;

		% distractors to optionally show in the delay period
		distractor5 = clone(distractor2);
		distractor5.xPosition = -in.objectSep;
		distractor6 = clone(distractor3);
		distractor6.xPosition = 0;
		distractor7 = clone(distractor4);
		distractor7.xPosition = +in.objectSep;
		set2 = metaStimulus('stimuli',{distractor5, distractor6, distractor7});
		set2.edit(1:3,'alpha',0.75);
		set2.edit(1:3,'yPosition',in.sampleY);
		
		%% ============================ custom stimuli setup
		setup(fix, s);
		setup(set, s);
		setup(set2, s);
		show(set2);

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while r.keepRunning
			set.fixationChoice = 3;
			pedestal.xPositionOut = 0;
			pedestal.yPositionOut = in.sampleY;
			target1.xPositionOut = 0;
			target1.yPositionOut = in.sampleY;
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
					distractor1.updateXY(xy(1,2), xy(2,2), true);
					set.stimulusSets{2} = [1 2 3 4];
					set.stimulusSets{4} = [3 4];
				case 2
					[~,idx] = Shuffle([1 2 3]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand];
					xy = xy(:,idx);
					target2.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2), true);
					distractor2.updateXY(xy(1,3), xy(2,3), true);
					set.stimulusSets{2} = [1 2 3 4 5];
					set.stimulusSets{4} = [3 4 5];
				case 3
					[~,idx] = Shuffle([1 2 3 4]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand Y-rand];
					xy = xy(:,idx);
					target2.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2), true);
					distractor2.updateXY(xy(1,3), xy(2,3), true);
					distractor3.updateXY(xy(1,4), xy(2,4), true);
					set.stimulusSets{2} = [1 2 3 4 5 6];
					set.stimulusSets{4} = [3 4 5 6];
				otherwise
					[~,idx] = Shuffle([1 2 3 4 5]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand Y-rand Y+rand];
					xy = xy(:,idx);
					target2.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2), true);
					distractor2.updateXY(xy(1,3), xy(2,3), true);
					distractor3.updateXY(xy(1,4), xy(2,4), true);
					distractor4.updateXY(xy(1,5), xy(2,5), true);
					set.stimulusSets{2} = [1 2 3 4 5 6 7];
					set.stimulusSets{4} = [3 4 5 6 7];
			end

			hide(set);
			if matches(in.task,'dmts')
				showSet(set, 3); % just pedestal and target1
			else
				showSet(set, 2); % pedestal, target and distractors
			end
			
			rs = randi(target1.nImages); r.stimulus = rs;
			target1.selectionOut = rs;
			target2.selectionOut = rs;
			rr = rs;
			for jj = 4:7
				rn = randi(set{jj}.nImages);
				while any(rn == rr)
					rn = randi(set{jj}.nImages);
				end
				set{jj}.selectionOut = rn;
				rr = [rr rn];
			end

			update(set);
			update(set2);
			
			% reset touch window for initial touch
			% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
			tM.updateWindow(in.initPosition(1), in.initPosition(2),fix.size/2,...
				true, [], [], 5, 0.05, 1.0);
			tM.exclusionZone = [];

			r.loopN = r.loopN + 1;
			r.keepRunning = true;
			r.touchResponse = '';
			r.touchInit = '';
			r.anyTouch = false;
			r.hldtime = false;
			txt = '';
			fail = false; hld = false;
			
			% sampleTime and delayTime can be single or range values
			if isscalar(in.sampleTime)
				sampleTime = in.sampleTime;
			else
				sampleTime = in.sampleTime(1) + (in.sampleTime(2)-in.sampleTime(1))*rand;
			end
			if isscalar(in.delayTime)
				delayTime = in.delayTime;
			else
				delayTime = in.delayTime(1) + (in.delayTime(2)-in.delayTime(1))*rand;
			end

			%% Initiate a trial with a touch target
			[r, dt, r.vblInitT] = clutil.startTouchTrial(r, in, tM, sbg, s, fix, quitKey, dt);

			%% start the actual task
			if matches(string(r.touchInit),"yes")
				% update trial number as we enter actal trial
				r.trialN = r.trialN + 1;
				r.touchResponse = '';
				[x,y] = set.getFixationPositions;
				% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
				tM.updateWindow(x, y, target2.size/2,...
				[], [], [], in.trialTime, 0.05, 1.0);

				if matches(in.task,'dmts')
					vblInit = GetSecs; vbl = vblInit;
					while vbl < vblInit + sampleTime
						if ~isempty(sbg); draw(sbg); end
						draw(set);
						if in.debug; drawText(s, 'Delay period...'); end
						vbl = flip(s);
						[~,~,c] = KbCheck(); if c(quitKey); r.keepRunning = false; break; end
					end
					if ~isempty(sbg); draw(sbg); end
					if in.delayDistractors; draw(set2); end
					flip(s);
					WaitSecs(delayTime-sv.ifi);
					showSet(set, 4); %just target2 and distractors
				end

				r.vblInit = GetSecs; vbl = r.vblInit;
				while isempty(r.touchResponse) && vbl < (r.vblInit + in.trialTime)
					if ~isempty(sbg); draw(sbg); end
					draw(set);
					if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
						drawText(s, txt);
						[xy] = s.toPixels([tM.x tM.y]);
						Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
					end
					vbl = flip(s);
					[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch] = testHold(tM,'yes','no');
					if tch
						r.firstTouchTime = vbl - r.vblInit;
						r.anyTouch = true; 
					end
					txt = sprintf('Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i fail:%i tch:%i WR: %.1f WInit: %.2f WHold: %.2f WRel: %.2f WX: %.2f WY: %.2f',...
						r.touchResponse, tM.x, tM.y, hld, r.hldtime, rel, reli, se, fail, tch, ...
						tM.window.radius,tM.window.init,tM.window.hold,tM.window.release,tM.window.X,tM.window.Y);
					[~,~,c] = KbCheck();
					if c(quitKey); r.keepRunning = false; break; end
				end
			end

			r.vblFinal = GetSecs;
			r.value = hld;
			if fail || hld == -100 || matches(r.touchResponse,'no') || matches(r.touchInit,'no')
				r.result = 0;
			elseif matches(r.touchResponse,'yes')
				r.result = 1;
			else
				r.result = -1;
			end

			%% update this trials reults
			[dt, r] = clutil.updateTrialResult(in, dt, r, rtarget, sbg, s, tM, rM, a);
			
		end % while keepRunning
		target = [];
		clutil.shutDownTask(s, sbg, fix, set, target, rtarget, tM, rM, saveName, dt, in, r);

	catch ME
		getReport(ME)
		try reset(rtarget); end %#ok<*TRYNC>
		try reset(fix); end
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
