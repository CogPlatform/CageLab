function startDragCategorisation(in)
	if ~exist('in','var') || isempty(in); in = clutil.checkInput(pth); end
	bgName = 'abstract4.jpg';
	prefix = 'DCAT';
	
	try
		%% ============================subfunction for shared initialisation
		[s, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName] = clutil.initialise(in, bgName, prefix);
		
		%% ============================task specific figures
		object = imageStimulus('name','object', 'size', in.targetSize, 'filePath', ...
			[in.folder filesep 'flowers'],'crop', 'square', 'circularMask', false,...
			'xPosition',in.initPosition(1),'yPosition',in.initPosition(2));
		target1 = clone(object);
		target1.name = 'target1';
		target1.xPosition = in.target1Pos(1);
		target1.yPosition = in.target1Pos(2);
		target2 = clone(object);
		target2.name = 'target2';
		target2.xPosition = in.target2Pos(1);
		target2.yPosition = in.target2Pos(2);
		set = metaStimulus('stimuli',{target1, target2, object, fix});
		set.fixationChoice = 1;

		%% ============================ custom stimuli setup
		setup(set, s);

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while r.keepRunning
			
			[~,idx] = Shuffle([1 2]);
			xy = [in.target1Pos; in.target2Pos];
			
			object.updateXY(0,0,true);
			target1.updateXY(xy(idx(1),1),xy(idx(1),2), true);
			target2.updateXY(xy(idx(2),1),xy(idx(2),2), true);

			rs = randi(object.nImages); r.stimulus = rs;
			object.selectionOut = rs;
			target1.selectionOut = rs;
			rr = rs;
			for jj = 2
				rs = randi(set{jj}.nImages);
				while any(rs == rr)
					rs = randi(set{jj}.nImages);
				end
				set{jj}.selectionOut = rs;
				rr = [rr rs];
			end

			hide(set);
			show(set,4);

			update(set);
			
			% reset touch window for initial touch
			% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
			tM.updateWindow(in.initPosition(1), in.initPosition(2), fix.size/2,...
				true, [], [], in.trialTime, 0.05, 1);
			tM.exclusionZone = [];

			r.loopN = r.loopN + 1;
			r.keepRunning = true;
			r.touchResponse = '';
			r.touchInit = '';
			r.anyTouch = false;
			r.hldtime = false;
			txt = '';
			fail = false; hld = false;
			
			%% Initiate a trial with a touch target
			[r, dt, r.vblInitT] = clutil.startTouchTrial(r, in, tM, sbg, s, fix, quitKey, dt);

			%% Success at initiation
			if matches(string(r.touchInit),"yes")
				% update trial number as we enter actual trial
				r.trialN = r.trialN + 1;

				% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
				radius = [in.targetSize/2 in.targetSize/2];
				tM.updateWindow(target1.xFinalD, target1.yFinalD, radius,...
				false, [], [], in.trialTime, in.trialTime, 1.0);

				rect = CenterRectOnPointd([0 0 5*s.ppd 5*s.ppd],target2.xFinal,target2.yFinal);
				tM.exclusionZone = rect;

				hide(set,4);
				show(set,[1 2 3]);

				tx = [];
				ty = [];
				nowX = []; nowY = []; 
				r.inTouch = false;
				r.reachTarget = false; r.exclusion = false;
				flush(tM);

				if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
				vbl = flip(s); r.vblInit = vbl;
				while ~r.reachTarget && ~r.exclusion && vbl < r.vblInit + in.trialTime+1
					if ~isempty(sbg); draw(sbg); end
					draw(set)
					if in.debug
						drawText(s, txt);
						if ~isempty(tM.x) && ~isempty(tM.y)
							[xy] = s.toPixels([tM.x tM.y]);
							Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
						end
					end
					vbl = flip(s);
					[success, r.inTouch, nowX, nowY, tx, ty, object] = clutil.processTouch(tM, in, object, target1, fix, s, r.inTouch, nowX, nowY, tx, ty);
					if tM.eventPressed
						r.firstTouchTime = vbl - r.vblInit;
						r.anyTouch = true; 
					end
					if success==true; r.reachTarget = true; end
					if success == -100; r.exclusion = true; r.reachTarget = false; end
					txt = sprintf('Response=%i x=%.2f y=%.2f',...
						r.reachTarget, tM.x, tM.y);
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

		