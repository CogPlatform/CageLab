function [success, inTouch, nowX, nowY, tx, ty, object] = processTouch(tM, in, object, target1, fix, s, inTouch, nowX, nowY, tx, ty)
% V1.02
success = false; firstRun = false;
if tM.eventAvail % check we have touch event[s]
	if ~inTouch
		tM.window.X = object.xFinalD;
		tM.window.Y = object.yFinalD;
		result = checkTouchWindows(tM, [], true); % check we are touching
		evt = tM.event;
		if result 
			inTouch = true; 
			firstRun = true;
		end
	else
		tM.window.X = target1.xFinalD;
		tM.window.Y = target1.yFinalD;
		tM.window.radius = 3;
		evt = getEvent(tM);
		firstRun = false;
	end
	if isempty(evt); return; end
	if inTouch
		nowX = tM.x; nowY = tM.y;
		if tM.eventRelease && evt.Type == 4 % this is a RELEASE event
			if in.debug; fprintf('≣≣≣≣⊱ processTouch@%s%i:RELEASE X: %.1f Y: %.1f \n',tM.name, tM.x,tM.y); end
			xy = []; tx = []; ty = []; inTouch = false;
		elseif tM.eventPressed
			tx = [tx nowX];
			ty = [ty nowY];
			object.updateXY(nowX, nowY, true);
			object.alphaOut = 0.9;
			if in.debug; fprintf('≣≣≣≣⊱ processTouch@%s:TOUCH X: %.1f Y: %.1f \n',tM.name, nowX, nowY); end
		end
		if ~firstRun
			success = checkTouchWindows(tM,[],false);
			if success == true; fprintf('\nYAAAAAY %i\n',success); end
		end
	end
end
end
