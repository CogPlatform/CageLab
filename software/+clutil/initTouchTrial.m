function [r, dt, vblInit] = initTouchTrial(r, in, tM, sM, dt)
	% INITTOUCHTRIAL Initializes a touch trial, by using a touch target to
	% confirm a subjects intent to engage in this trial
	%   [R, DT, VBLINIT] = INITTOUCHTRIAL(R, IN, TM, SM, DT)
	%   initializes a touch trial by setting up the touch window and waiting for
	%   a touch to occur.
	arguments (Input)
		r struct % run struct
		in struct % input struct
		tM touchManager % touchManager
		sM screenManager % screen manager
		dt struct % data struct
	end

	arguments (Output)
		r struct % updated run struct
		dt struct % updated data struct
		vblInit double % VBL time at init start
	end

	% reset touch window for initial touch
	% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
	tM.updateWindow(in.initPosition(1), in.initPosition(2),r.fix.size/2,...
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

	if ~isempty(r.sbg); draw(r.sbg); else; drawBackground(s, in.bg); end
	vbl = flip(sM); vblInit = vbl + s.screenVals.ifi;
	dt.data.times.initStart(r.trialN+1) = vblInit;
	while isempty(r.touchInit) && vbl < vblInit + 5
		if ~isempty(r.sbg); draw(r.sbg); end
		if ~r.hldtime; draw(r.fix); end
		if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
			xy = s.toPixels([tM.x tM.y]);
			Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
		end
		vbl = flip(sM);
		[r.touchInit, hld, r.hldtime, ~, ~, ~, fail, tch] = testHold(tM, 'yes', 'no');
		if tch
			r.anyTouch = true;
			dt.data.times.initTouch(r.trialN+1) = vbl;
			dt.data.times.initRT(r.trialN+1) = vbl - vblInit;
		end
		[~, ~, keys] = KbCheck(-1);
		if keys(r.quitKey); r.keepRunning = false; break; end
	end

	dt.data.times.initEnd(r.trialN+1) = vbl - vblInit;
	fprintf('===> touchInit: <%s> hld:%i fail:%i touch:%i RT:%.2fs\n', ...
		r.touchInit, hld, fail, tch, vbl - vblInit);

	%%% Wait for release
	while isTouch(tM)
		if ~isempty(r.sbg); draw(r.sbg); else; drawBackground(sM, in.bg); end
		if in.debug; drawText(sM,'Please release touchscreen...'); end
		flip(sM);
	end
	if ~isempty(r.sbg); draw(r.sbg); else; drawBackground(sM, in.bg); end
	flip(sM);
	flush(tM);
end
