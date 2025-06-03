function startDragCategorisation(in)
	if ~exist('in','var') || isempty(in); in = clutil.checkInput(pth); end
	bgName = 'abstract4.jpg';
	prefix = 'DCAT';
	zmq = in.zmq;
	broadcast = matmoteGO.broadcast();
	
	try
		%% ============================subfunction for shared initialisation
		[s, sv, sbg, rtarget, fix, a, rM, tM, dt, quitKey] = clutil.initialise(in, bgName, prefix);
		
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

		%% ============================ run variables
		keepRunning = true;
		trialN = 0;
		phaseN = 0;
		phase = 1;
		stimulus = 1;
		randomRewardTimer = GetSecs;
		rRect = rtarget.mvRect;

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while keepRunning
			
			[~,idx] = Shuffle([1 2]);
			xy = [in.target1Pos; in.target2Pos];
			
			object.updateXY(0,0,true);
			target1.updateXY(xy(idx(1),1),xy(idx(1),2), true);
			target2.updateXY(xy(idx(2),1),xy(idx(2),2), true);

			r = randi(object.nImages); stimulus = r;
			object.selectionOut = r;
			target1.selectionOut = r;
			rr = r;
			for jj = 2
				r = randi(set{jj}.nImages);
				while any(r == rr)
					r = randi(set{jj}.nImages);
				end
				set{jj}.selectionOut = r;
				rr = [rr r];
			end

			hide(set);
			show(set,4);

			update(set);
			
			% reset touch window for initial touch
			tM.window.radius = fix.size/2;
			tM.window.init = 5;
			tM.window.hold = 0.05;
			tM.window.release = 1.0;
			tM.window.X = in.initPosition(1);
			tM.window.Y = in.initPosition(2);
			tM.window.doNegation = true;
			tM.exclusionZone = [];

			res = 0; phase = 1;
			keepRunning = true;
			touchInit = '';
			reachTarget = false;
			anyTouch = false; 
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			vblInit = NaN;
			
			%% Initiate a trial with a touch target
			[touchInit, hldtime, anyTouch, keepRunning, dt, vblInit] = clutil.startTouchTrial(trialN, in, tM, sbg, s, fix, hldtime, anyTouch, quitKey, keepRunning, dt);

			%% Success at initiation
			if matches(string(touchInit),"yes")
				tM.window.radius = [in.targetSize/2 in.targetSize/2];
				tM.window.init = in.trialTime;
				tM.window.hold = in.trialTime;
				tM.window.release = 1.0;
				tM.window.X = target1.xFinalD;
				tM.window.Y = target1.yFinalD;
				tM.window.doNegation = false;
				rect = CenterRectOnPointd([0 0 5*s.ppd 5*s.ppd],target2.xFinal,target2.yFinal);
				tM.exclusionZone = rect;
				hide(set,4);
				show(set,[1 2 3]);
				tx = [];
				ty = [];
				nowX = []; nowY = []; 
				inTouch = false; anyTouch = false; 
				reachTarget = false; exclusion = false;
				flush(tM);
				if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
				vbl = flip(s); vblInit = vbl;
				while ~reachTarget && ~exclusion && vbl < vblInit + in.trialTime+1
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
					[success, inTouch, nowX, nowY, tx, ty, object] = clutil.processTouch(tM, in, object, target1, fix, s, inTouch, nowX, nowY, tx, ty);
					if tM.eventPressed; anyTouch = true; end
					if success==true; reachTarget = true; end
					if success == -100; exclusion = true; reachTarget = false; end
					txt = sprintf('Response=%i x=%.2f y=%.2f',...
						reachTarget,tM.x,tM.y);
					[~,~,c] = KbCheck();
					if c(quitKey); keepRunning = false; break; end
				end

			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
			vblEnd = flip(s);
			WaitSecs(0.05);

			%% Get trial result
			if reachTarget == true
				if in.reward; giveReward(rM, in.rewardTime); end
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,in.correctBeep,0.1,in.audioVolume);
				update(dt, true, phase, trialN, vblEnd-vblInit, stimulus);
				if ~isempty(sbg); draw(sbg); end
				drawText(s,['CORRECT! phase: ' num2str(phase)]);
				flip(s);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs(0.5+rand);
			elseif reachTarget == false && anyTouch == true
				update(dt, false, phase, trialN, vblEnd-vblInit, stimulus);
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,['FAIL! phase: ' num2str(phase)]);
				flip(s);
				beep(a,in.incorrectBeep,0.5,in.audioVolume);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs('YieldSecs',in.timeOut);
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs(0.5+rand);
			end

			%% finalise this trial
			if keepRunning == false; break; end
			drawBackground(s,in.bg)
			if ~isempty(sbg); draw(sbg); end
			flip(s);
			if ~isempty(zmq) && zmq.poll('in')
				[cmd, ~] = zmq.receiveCommand();
				if ~isempty(cmd) && isstruct(cmd)
					if isfield(msg,'command') && matches(msg.command,'exittask')
						break;
					end
				end
			end
		end % while keepRunning

		clutil.shutDownTask(s, sbg, fix, set, target1, target2, tM, rM, saveName, dt, in, trialN);

	catch ME
		getReport(ME)
		try reset(rtarget); end
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

		