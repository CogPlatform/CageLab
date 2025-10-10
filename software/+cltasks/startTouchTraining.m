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
		[s, sv, r, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName, in] = clutil.initialise(in, bgName, prefix);
		
		%% ============================task specific figures
		if matches(in.stimulus, 'Picture')
			target = imageStimulus('size', in.maxSize, 'filePath', [in.folder filesep 'flowers'], 'crop', 'square', 'circularMask', true);
		else
			target = discStimulus('size', in.maxSize, 'colour', in.fg);
		end
		set = metaStimulus;
		if in.debug; target.verbose = true; end

		%% ============================ custom stimuli setup
		setup(target, s);

		%% ============================ phase table
		sz = linspace(in.maxSize, in.minSize, 15);
		p = [];
		% SIZE
		for pn = 1:length(sz)
			p(pn).size = sz(pn); p(pn).hold = 0.0; p(pn).rel = 3; p(pn).pos = [0 0];
		end
		pn = length(p) + 1;
		% POSITION
		p(pn).size = sz(end); p(pn).hold = 0.0; p(pn).rel = 3; p(pn).pos = 3; pn = pn + 1;
		p(pn).size = sz(end); p(pn).hold = 0.0; p(pn).rel = 3; p(pn).pos = 5; pn = pn + 1;
		p(pn).size = sz(end); p(pn).hold = 0.0; p(pn).rel = 3; p(pn).pos = 7; pn = pn + 1;
		p(pn).size = sz(end); p(pn).hold = 0.0; p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
		if matches(in.task, 'Simple') % simple task
			if r.phase > length(p); r.phase = length(p); end
		else
			% HOLD
			hl = linspace(0.01, 0.8, 9);
			for hld = hl
				p(pn).size = sz(end); p(pn).hold = hld; p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
			end
			p(pn).size = sz(end); p(pn).hold = [0.5 1.2]; p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
			% RELEASE
			rl = linspace(3, 1, 6);
			for rel = hl
				p(pn).size = sz(end); p(pn).hold = hld; p(pn).rel = rel; p(pn).pos = 11; pn = pn + 1;
			end
			if r.phase > length(p); r.phase = length(p); end
		end
		fprintf('===> Total phases: %i\n', length(p));
		disp(p);
		disp('=====================================');

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while r.keepRunning
			if r.phase > length(p); r.phase = length(p); end
			if length(p(r.phase).pos) == 2
				x = p(r.phase).pos(1);
				y = p(r.phase).pos(2);
			else
				x = randi(p(r.phase).pos(1));
				if rand > 0.5; x = -x; end
				y = randi(p(r.phase).pos(1));
				y = y / r.aspect;
				if rand > 0.5; y = -y; end
			end
			if length(p(r.phase).hold) == 2
				hold = randi(p(r.phase).hold .* 1e3) / 1e3;
			else
				hold = p(r.phase).hold(1);
			end
			if isa(target,'imageStimulus') && target.circularMask == false
				radius = [p(r.phase).size/2 p(r.phase).size/2];
			else
				radius = p(r.phase).size / 2;
			end
			
			% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
			tM.updateWindow(x, y, radius,...
				[], [], [], in.trialTime, hold, p(r.phase).rel);

			target.xPositionOut = x;
			target.yPositionOut = y;
			target.sizeOut = p(r.phase).size;
			if isa(target,'imageStimulus')
				target.selectionOut = randi(target.nImages);
				r.stimulus = target.selectionOut;
			end
			update(target);

			r = clutil.initTrialVariables(r);
			txt = '';
			fail = false; hld = false;

			fprintf('\n===> START %s: %i - %i -- phase %i stim %i \n', upper(in.task), r.loopN, r.trialN+1, r.phase, r.stimulus);
			fprintf('===> Touch params X: %.1f Y: %.1f Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
				tM.window.X, tM.window.Y, tM.window.radius, tM.window.init, tM.window.hold, tM.window.release);
			
			if r.loopN == 1; dt.data.startTime = GetSecs; end
			fprintf('DBG-1');
			WaitSecs(0.01);
			reset(tM);
			flush(tM);
			fprintf('-2');
			if ~isempty(sbg); draw(sbg); end
			fprintf('-3');
			vbl = flip(s); 
			r.vblInit = vbl + sv.ifi; %start is actually next flip
			syncTime(tM, r.vblInit);
			fprintf('-4');
			while isempty(r.touchResponse) && vbl < r.vblInit + in.trialTime
				if ~isempty(sbg); draw(sbg); end
				if ~r.hldtime; draw(target); end
				fprintf('-5');
				if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
					drawText(s, txt);
					[xy] = s.toPixels([tM.x tM.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				fprintf('-6');
				vbl = flip(s);
				if r.phase < 5
					[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch] = testHold(tM,'yes','no');
				else
					[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch] = testHoldRelease(tM,'yes','no');
				end
				if tch
					r.reactionTime = vbl - r.vblInit;
					r.anyTouch = true;
				end
				fprintf('-7');
				if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
					txt = sprintf('Phase=%i Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i %.1f Init: %.2f Hold: %.2f Release: %.2f',...
						r.phase,r.touchResponse,tM.x,tM.y,hld, r.hldtime, rel, reli, se,...
						tM.window.radius,tM.window.init,tM.window.hold,tM.window.release);
				end
				[~,~,c] = KbCheck();
				if c(quitKey); r.keepRunning = false; break; end
				fprintf('-8');
			end
			fprintf('\n');
			%% check logic of task result
			r.vblFinal = GetSecs;
			if r.anyTouch
				r.trialN = r.trialN + 1; 
			end
			r.value = hld;
			if fail || hld == -100 || matches(r.touchResponse,'no')
				r.result = 0;
			elseif matches(r.touchResponse,'yes')
				r.result = 1;
			else
				r.result = -1;
			end

			%% update this trials reults
			[dt, r] = clutil.updateTrialResult(in, dt, r, rtarget, sbg, s, tM, rM, a);

		end % while keepRunning

		clutil.shutDownTask(s, sbg, fix, set, target, rtarget, tM, rM, saveName, dt, in, r);

	catch ME
		getReport(ME)
		try reset(target); end %#ok<*TRYNC>
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
