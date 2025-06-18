function startTouchTraining(in)
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

		%% ============================steps table
		sz = linspace(in.maxSize, in.minSize, 5);
		if matches(in.task, 'Simple') % simple task
			if r.phase > 9; r.phase = 9; end
			pn = 1; p = [];
			%size
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			% position
			p(pn).size = sz(end); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = 3; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = 5; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = 7; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = 11;
		else
			pn = 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.02; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			% 6
			p(pn).size = sz(end); p(pn).hold = 0.02; p(pn).rel = 1; p(pn).pos = 3; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.02; p(pn).rel = 1; p(pn).pos = 5; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.02; p(pn).rel = 1; p(pn).pos = 7; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.02; p(pn).rel = 1; p(pn).pos = 11;
			% 10
			p(pn).size = sz(end); p(pn).hold = 0.1;   p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.2;   p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.4;   p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.8;   p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 1;     p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
			% 16
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 2;	p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.75; p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.5;	p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.25; p(pn).pos = 11; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1;	p(pn).pos = 11; pn = pn + 1;
		end

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

			r.result = -1;
			r.value = NaN;
			r.keepRunning = true;
			r.touchInit = '';
			r.touchResponse = '';
			r.anyTouch = false;
			r.loopN = r.loopN + 1;
			r.hldtime = false;
			r.vblInit = NaN;
			txt = '';
			fail = false; hld = false;

			fprintf('\n===> START %s: %i - %i -- phase %i stim %i \n', upper(in.task), r.loopN, r.trialN+1, r.phase, r.stimulus);
			fprintf('===> Touch params X: %.1f Y: %.1f Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
				tM.window.X, tM.window.Y, tM.window.radius, tM.window.init, tM.window.hold, tM.window.release);
			
			if r.loopN == 1; dt.data.startTime = GetSecs; end
			
			WaitSecs(0.01);
			reset(tM);
			flush(tM);
			
			if ~isempty(sbg); draw(sbg); end
			vbl = flip(s); r.vblInit = vbl;
			while isempty(r.touchResponse) && vbl < r.vblInit + in.trialTime
				if ~isempty(sbg); draw(sbg); end
				if ~r.hldtime; draw(target); end
				if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
					drawText(s, txt);
					[xy] = s.toPixels([tM.x tM.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch] = testHoldRelease(tM,'yes','no');
				if tch
					r.firstTouchTime = vbl;
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

			r.vblFinal = GetSecs;
			if r.anyTouch; r.trialN = r.trialN + 1; end
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
