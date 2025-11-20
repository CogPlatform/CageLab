function startTouchTraining(in)
	% startTouchTraining(in)
	% Start a touch training task, using automated steps to train hold and release
	% in comes from CageLab GUI or can be a struct with the following fields:
	%   in.task = 'Simple' or 'Full' (default = 'Full')
	%   in.stimulus = 'Picture' or 'Disc' (default = 'Picture')
	%   in.fg = [0 0 0] (default) or [1 1 1]
	%   in.minSize = minimum stimulus size in degrees (default = 2)
	%   in.maxSize = maximum stimulus size in degrees (default = 10)
	%   in.trialTime = maximum trial time in seconds (default = 5)

	if ~exist('in','var') || isempty(in); in = clutil.checkInput(); end
	bgName = 'abstract1.jpg';
	prefix = 'TT';
	
	try
		%% ============================subfunction for shared initialisation
		[sM, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName, in] = clutil.initialise(in, bgName, prefix);
		
		%% ============================task specific figures
		if matches(in.stimulus, 'Picture')
			target = imageStimulus('size', in.maxSize, ...
				'filePath', [in.folder filesep 'flowers'], ...
				'crop', 'square', 'circularMask', true);
		else
			target = discStimulus('size', in.maxSize, 'colour', in.fg);
		end
		set = metaStimulus;
		if in.debug; target.verbose = true; end

		%% ============================ custom stimuli setup
		fix.sizeOut = 8; fix.xPositionOut = 0; 
		fix.yPositionOut = -10; fix.type = 'flash';
		fix.alpha = 1;
		update(fix);
		setup(target, sM);

		%% ============================ phase table
		sz = linspace(in.maxSize, in.minSize, 15);
		phases = [];
		%------------------ SIZE
		for pn = 1:length(sz)
			phases(pn).size = sz(pn); phases(pn).hold = 0.0; phases(pn).rel = 3; phases(pn).pos = [0 0];
		end
		pn = length(phases) + 1;
		%------------------ POSITION
		phases(pn).size = sz(end); phases(pn).hold = 0.0; phases(pn).rel = 3; phases(pn).pos = 3; pn = pn + 1;
		phases(pn).size = sz(end); phases(pn).hold = 0.0; phases(pn).rel = 3; phases(pn).pos = 5; pn = pn + 1;
		phases(pn).size = sz(end); phases(pn).hold = 0.0; phases(pn).rel = 3; phases(pn).pos = 7; pn = pn + 1;
		phases(pn).size = sz(end); phases(pn).hold = 0.0; phases(pn).rel = 3; phases(pn).pos = 11; pn = pn + 1;
		if matches(in.task, 'Simple') % simple task
			if r.phase > length(phases); r.phase = length(phases); end
		else
			%------------------ HOLD
			
			for hld = linspace(0.01, 0.4, 12)
				phases(pn).size = sz(end); phases(pn).hold = hld; phases(pn).rel = 3; phases(pn).pos = 5; pn = pn + 1;
			end
			%------------------ RELEASE
			
			for rel = linspace(3, 1, 6)
				phases(pn).size = sz(end); phases(pn).hold = hld; phases(pn).rel = rel; phases(pn).pos = 5; pn = pn + 1;
			end
			phases(pn).size = sz(end); phases(pn).hold = [0.5 1.2]; phases(pn).rel = 1; phases(pn).pos = 7;
			if r.phase > length(phases); r.phase = length(phases); end
		end
		r.totalPhases = length(phases);
		r.phases = phases;
		fprintf('===> Total phases: %i\n', r.totalPhases);
		disp(struct2table(phases));
		disp('=====================================');

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TASK
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LOOP
		while r.keepRunning

			% get values from p phases structure
			if r.phase > length(phases); r.phase = length(phases); end
			if length(phases(r.phase).pos) == 2
				x = phases(r.phase).pos(1);
				y = phases(r.phase).pos(2);
			else
				x = randi(phases(r.phase).pos(1));
				if rand > 0.5; x = -x; end
				y = randi(phases(r.phase).pos(1));
				y = y / r.aspect;
				if rand > 0.5; y = -y; end
			end
			if length(phases(r.phase).hold) == 2
				hold = randi(phases(r.phase).hold .* 1e3) / 1e3;
			else
				hold = phases(r.phase).hold(1);
			end
			if isa(target,'imageStimulus') && target.circularMask == false
				radius = [phases(r.phase).size/2 phases(r.phase).size/2];
			else
				radius = phases(r.phase).size / 2;
			end
			
			% update touch target
			% updateWindow(tM,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
			updateWindow(tM, x, y, radius,...
				[], [], [], in.trialTime, hold, phases(r.phase).rel);
			reset(tM); flush(tM);

			% update visual target
			target.xPositionOut = x;
			target.yPositionOut = y;
			target.sizeOut = phases(r.phase).size;
			if isa(target,'imageStimulus')
				target.selectionOut = randi(target.nImages);
				r.stimulus = target.selectionOut;
			end
			update(target);

			% reset trial variables held in r structure
			r = clutil.initTrialVariables(r);
			txt = '';
			fail = false; hld = false;

			%% ============================== Wait for release
			ensureTouchRelease(false);

			%% ============================== Get ready to start trial
			if r.loopN == 1; dt.data.startTime = GetSecs; end
			fprintf('\n===> START %s %s: %i - %i -- phase %i stim %i rewards %i\n', in.session.subjectName, upper(in.task), r.loopN, r.trialN+1, r.phase, r.stimulus, dt.data.rewards);
			if in.debug
				fprintf('===> Touch Params X: %.1f Y: %.1f Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
					sprintf("<%.1f>",tM.window.X), sprintf("<%.1f>",tM.window.Y),...
					sprintf("<%.1f>",tM.window.radius), sprintf("<%.2f>",tM.window.init),...
					sprintf("<%.2f>",tM.window.hold), sprintf("<%.1f>",tM.window.release));
			end

			% reset the touch window
			reset(tM); flush(tM);

			if ~isempty(sbg); draw(sbg); else; drawBackground(sM, in.bg); end
			vbl = flip(sM); 
			r.vblInit = vbl + sv.ifi; %start is actually next flip
			syncTime(tM, r.vblInit);
			while isempty(r.touchResponse) && vbl < r.vblInit + in.trialTime
				if ~isempty(sbg); draw(sbg); end
				if ~r.hldtime; draw(target); end
				if r.hldtime && r.phase > 31; draw(fix); end
				if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
					drawText(sM, txt);
					[xy] = sM.toPixels([tM.x tM.y]);
					Screen('glPoint', sM.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(sM);
				if r.phase < 3
					[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch] = testHold(tM,'yes','no');
				else
					[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch] = testHoldRelease(tM,'yes','no');
				end
				if tch
					r.reactionTime = vbl - r.vblInit;
					r.anyTouch = true;
				end
				if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
					txt = sprintf('Phase=%i Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i %.1f Init: %.2f Hold: %.2f Release: %.2f',...
						r.phase,r.touchResponse,tM.x,tM.y,hld, r.hldtime, rel, reli, se,...
						tM.window.radius,tM.window.init,tM.window.hold,tM.window.release);
				end
				[~,~,c] = KbCheck();
				if c(quitKey); r.keepRunning = false; break; end
			end
			
			if ~isempty(sbg); draw(sbg); else; drawBackground(sM, in.bg); end
			r.vblFinal = flip(sM);
			
			%% ============================== check logic of task result
			if r.anyTouch %correct or incorrect touch
				r.trialN = r.trialN + 1; 
			end
			r.value = hld;
			if fail || hld == -100 || matches(r.touchResponse,'no')
				r.result = 0; % incorrect
			elseif matches(r.touchResponse,'yes')
				r.result = 1; % correct
			else
				r.result = -1; %unknown error
			end

			%% ============================== Ensure release of touch screen
			ensureTouchRelease(true);

			%% ============================== update this trials reults
			[dt, r] = clutil.updateTrialResult(in, dt, r, rtarget, sbg, sM, tM, rM, a);

			%% ============================== inter-trial pause
			WaitSecs('YieldSecs',in.ITI-(GetSecs-r.vblFinal));

		end % while keepRunning

		clutil.shutDownTask(sM, sbg, fix, set, target, rtarget, tM, rM, saveName, dt, in, r);

	catch ME
		getReport(ME)
		try reset(target); end %#ok<*TRYNC>
		try close(target); end
		try close(fix); end
		try close(rtarget); end
		try close(sM); end
		try close(tM); end
		try close(rM); end
		try close(a); end
		try Priority(0); end
		try ListenChar(0); end
		try RestrictKeysForKbCheck([]); end
		try ShowCursor; end
		rethrow(ME);
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

end %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
