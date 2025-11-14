function r = initTrialVariables(r)
	%> Initialise the current trial variables for a new loop/trial.
	%>
	%> @param r The current trial result structure.
	%> @return r The updated trial result structure with initialised values.

	% keep task running?
	r.keepRunning = true;
	% loop and results
	r.loopN = r.loopN + 1;
	r.result = -1;
	r.value = NaN;
	% touch parameters
	r.touchInit = '';
	r.touchResponse = '';
	r.anyTouch = false;
	r.hldtime = false;
	% times
	r.vblInit = NaN;
	r.vblFinal = NaN;
	r.stimOnsetTime = NaN;
	r.reactionTime = NaN;
	r.firstTouchTime = NaN;
	r.sampleTime = NaN;
	r.delayTime = NaN;
	% text
	r.summary = '';
	r.txt = '';
	
end