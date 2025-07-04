function [r, dt, vblInit] = initTouchTrial(r, in, tM, sbg, s, fix, quitKey, dt)
	
	% reset touch window for initial touch
	% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
	tM.updateWindow(in.initPosition(1), in.initPosition(2),fix.size/2,...
		true, [], [], 5, in.initHoldTime, 1.0);
	tM.exclusionZone = [];

	fprintf('\n===> START %s: %i - %i -- phase %i stim %i \n', upper(in.task), r.loopN, r.trialN, r.phase, r.stimulus);
	fprintf('===> Touch params X: %.1f Y: %.1f Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
		tM.window.X, tM.window.Y, tM.window.radius, tM.window.init, tM.window.hold, tM.window.release);

	if r.trialN == 1; dt.data.startTime = GetSecs; end

	dt.data.times.initStart(r.trialN+1) = NaN;
	dt.data.times.initTouch(r.trialN+1) = NaN;
	dt.data.times.initRT(r.trialN+1) = NaN;
	dt.data.times.initEnd(r.trialN+1) = NaN;

	r.touchInit = '';
	flush(tM);

	if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
	vbl = flip(s); vblInit = vbl + s.screenVals.ifi;
	dt.data.times.initStart(r.trialN+1) = vblInit;
	while isempty(r.touchInit) && vbl < vblInit + 5
		if ~isempty(sbg); draw(sbg); end
		if ~r.hldtime; draw(fix); end
		if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
			xy = s.toPixels([tM.x tM.y]);
			Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
		end
		vbl = flip(s);
		[r.touchInit, hld, r.hldtime, rel, reli, se, fail, tch] = testHold(tM, 'yes', 'no');
		if tch
			r.anyTouch = true; 
			dt.data.times.initTouch(r.trialN+1) = vbl;
			dt.data.times.initRT(r.trialN+1) = vbl - vblInit;
		end
		[~, ~, c] = KbCheck();
		if c(quitKey); r.keepRunning = false; break; end
	end

	dt.data.times.initEnd(r.trialN+1) = vbl - vblInit;
	fprintf('===> touchInit: <%s> hld:%i fail:%i touch:%i RT:%.2fs\n', ...
		r.touchInit, hld, fail, tch, vbl - vblInit);

	%%% Wait for release
	while isTouch(tM)
		if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
		if in.debug; drawText(s,'Please release touchscreen...'); end
		flip(s);
	end
	if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
	flip(s);
	flush(tM);
	WaitSecs('YieldSecs',0.01);
end
