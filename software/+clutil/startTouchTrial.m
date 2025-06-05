function [r, dt, vblInit] = startTouchTrial(r, in, tM, sbg, s, fix, quitKey, dt)
	% v1.02
	fprintf('\n===> START TRIAL: %i of task: %s\n', r.trialN, upper(in.task));
	fprintf('===> Touch params X: %.1f Y: %.1f Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
		tM.window.X, tM.window.Y, tM.window.radius, tM.window.init, tM.window.hold, tM.window.release);

	if r.trialN == 1; dt.data.startTime = GetSecs; end

	r.touchInit = '';
	flush(tM);

	if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
	vbl = flip(s); vblInit = vbl;
	while isempty(r.touchInit) && vbl < vblInit + 5
		if ~isempty(sbg); draw(sbg); end
		if ~r.hldtime; draw(fix); end
		if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
			xy = s.toPixels([tM.x tM.y]);
			Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
		end
		vbl = flip(s);
		[r.touchInit, hld, r.hldtime, rel, reli, se, fail, tch] = testHold(tM, 'yes', 'no');
		if tch; r.anyTouch = true; end
		[~, ~, c] = KbCheck();
		if c(quitKey); r.keepRunning = false; break; end
	end

	fprintf('===> touchInit: <%s> hld:%i fail:%i touch:%i\n', r.touchInit, hld, fail,tch);

	%%% Wait for release
	while isTouch(tM)
		if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
		vbl = flip(s);
	end
	flush(tM);
end
