function r = initTrialVariables(r)
	%> Initialise the current trial variables for a new loop/trial.
	%>
	%> @param r The current trial result structure.
	%> @return r The updated trial result structure with initialised values.

	r.summary = '';
	r.loopN = r.loopN + 1;
	r.result = -1;
	r.value = NaN;
	r.keepRunning = true;
	r.touchInit = '';
	r.touchResponse = '';
	r.anyTouch = false;
	r.hldtime = false;
	r.vblInit = NaN;
	r.vblFinal = NaN;
	r.reactionTime = NaN;
	r.firstTouchTime = NaN;
	r.txt = '';
	r.sampleTime = NaN;
	r.delayTime = NaN;

end