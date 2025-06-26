function [r, dt, vblInit] = startTouchTrial(r, in, tM, sbg, s, fix, quitKey, dt)
	% v1.02
	fprintf('\n===> START %s: %i - %i -- phase %i stim %i \n', upper(in.task), r.loopN, r.trialN, r.phase, r.stimulus);
	fprintf('===> Touch params X: %.1f Y: %.1f Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
		tM.window.X, tM.window.Y, tM.window.radius, tM.window.init, tM.window.hold, tM.window.release);

	if r.trialN == 1; dt.data.startTime = GetSecs; end

	r.touchInit = '';
	flush(tM);

	if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
	vbl = flip(s); vblInit = vbl;
	dt.data.times.initStart(r.trialN+1) = vbl;
	while isempty(r.touchInit) && vbl < vblInit + 5
		if ~isempty(sbg); draw(sbg); end
		if ~r.hldtime; draw(fix); end
		if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
			xy = s.toPixels([tM.x tM.y]);
			Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
		end
		vbl = flip(s);
		[r.touchInit, hld, r.hldtime, rel, reli, se, fail, tch] = testHold(tM, 'yes', 'no');
		if tch; r.anyTouch = true; dt.data.times.initTouch(r.trialN+1) = vbl; end
		[~, ~, c] = KbCheck();
		if c(quitKey); r.keepRunning = false; break; end
	end

	dt.data.times.initRT(r.trialN+1) = vbl - vlbInit;
	fprintf('===> touchInit: <%s> hld:%i fail:%i touch:%i RT:%.2fs\n', r.touchInit, hld, fail,tch, vlb-vblInit);

	%%% Wait for release
	while isTouch(tM)
		if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
		if in.debug; drawText(s,'Please release touchscreen...'); end
		flip(s);
	end
	if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
	flip(s);
	flush(tM);
	WaitSecs('YieldSecs',0.02);
end
