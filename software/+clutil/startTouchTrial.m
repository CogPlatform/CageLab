function [touchInit, hldtime, anyTouch, keepRunning, dt, vblInit] = startTouchTrial(trialN, in, tM, sbg, s, fix, hldtime, anyTouch, quitKey, keepRunning, dt)
	% v1.02
	fprintf('\n===> START TRIAL: %i of task: %s\n', trialN, upper(in.task));
	fprintf('===> Touch params X: %.1f Y: %.1f Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', ...
		tM.window.X, tM.window.Y, tM.window.radius, tM.window.init, tM.window.hold, tM.window.release);

	if trialN == 1; dt.data.startTime = GetSecs; end

	touchInit = '';
	flush(tM);

	if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
	vbl = flip(s); vblInit = vbl;
	while isempty(touchInit) && vbl < vblInit + 5
		if ~isempty(sbg); draw(sbg); end
		if ~hldtime; draw(fix); end
		if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
			xy = s.toPixels([tM.x tM.y]);
			Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
		end
		vbl = flip(s);
		[touchInit, hld, hldtime, rel, reli, se, fail, tch] = testHold(tM, 'yes', 'no');
		if tch; anyTouch = true; end
		[~, ~, c] = KbCheck();
		if c(quitKey); keepRunning = false; break; end
	end

	fprintf('touchInit <%s>\n', touchInit);

	%%% Wait for release
	while isTouch(tM)
		if ~isempty(sbg); draw(sbg); else; drawBackground(s, in.bg); end
		vbl = flip(s);
	end
	flush(tM);
end
