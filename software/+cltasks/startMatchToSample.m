function startMatchToSample(in)
	if ~exist('in','var') || isempty(in); in = clutil.checkInput(pth); end
	bgName = 'abstract2.jpg';
	prefix = 'MTS';
	zmq = in.zmq;
	broadcast = matmoteGO.broadcast();

	try
		%% ============================subfunction for shared initialisation
		[s, sv, sbg, rtarget, fix, a, rM, tM, dt, quitKey, saveName] = clutil.initialise(in, bgName, prefix);

		%% ============================task specific figures
		switch lower(in.object)
			case 'fractals'
				pfix = ["A" "B" "C" "D" "E" "F" "G" "H" "I"];
				pfix1 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix1);
				pfix2 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix2);
				pfix3 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix3);
				pfix4 = pfix(randi(length(pfix)));
				pfix = setxor(pfix3,pfix4);
				pfix5 = pfix(randi(length(pfix)));
			case 'quaddles'
				pfix = ["A" "B" "C" "D" "E" "F" "G" "H"];
				pfix1 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix1);
				pfix2 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix2);
				pfix3 = pfix(randi(length(pfix)));
				pfix = setxor(pfix,pfix3);
				pfix4 = pfix(randi(length(pfix)));
				pfix = setxor(pfix3,pfix4);
				pfix5 = pfix(randi(length(pfix)));
			case 'flowers'
				[pfix1 pfix2 pfix3 pfix4 pfix5] = deal("");
		end
		pedestal = discStimulus('size', in.objectSize + 1,'colour',[0.5 1 1],'alpha',0.3,'yPosition',in.sampleY);
		target1 = imageStimulus('size', in.objectSize, 'randomiseSelection', false,...
			'filePath', [string(in.folder) + filesep + in.object + filesep + pfix1],'yPosition',in.sampleY);
		target2 = clone(target1);
		distractor1 = clone(target1);
		distractor1.filePath = [string(in.folder) + filesep + in.object + filesep + pfix2];
		distractor2 = clone(target1);
		distractor2.filePath = [string(in.folder) + filesep + in.object + filesep + pfix3];
		distractor3 = clone(target1);
		distractor3.filePath = [string(in.folder) + filesep + in.object + filesep + pfix4];
		distractor4 = clone(target1);
		distractor4.filePath = [string(in.folder) + filesep + in.object + filesep + pfix5];
		set = metaStimulus('stimuli',{pedestal, target1, target2, distractor1, distractor2, distractor3, distractor4});
		set.fixationChoice = 3;

		
		%% ============================ custom stimuli setup
		setup(fix, s);
		setup(set, s);

		%% ============================ run variables
		keepRunning = true;
		trialN = 0;
		phaseN = 1;phase = 1;

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while keepRunning

			set.fixationChoice = 3;
			pedestal.xPositionOut = 0;
			pedestal.yPositionOut = in.sampleY;
			target1.xPositionOut = 0;
			target1.yPositionOut = in.sampleY;
			sep = in.objectSep;
			N = in.distractorN;
			Y = in.distractorY;
			switch N
				case 1
					[~,idx] = Shuffle([1 2]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand];
					xy = xy(:,idx);
					target2.updateXY(xy(1,1), xy(2,1), true);
					distractor1.updateXY(xy(1,2), xy(2,2));
					hide(set);
					show(set,[1 2 3 4]);
				case 2
					[~,idx] = Shuffle([1 2 3]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand];
					xy = xy(:,idx);
					target2.xPositionOut = xy(1,1);
					target2.yPositionOut = xy(2,1);
					distractor1.xPositionOut = xy(1,2);
					distractor1.yPositionOut = xy(2,2);
					distractor2.xPositionOut = xy(1,3);
					distractor2.yPositionOut = xy(2,3);
					hide(set);
					show(set,[1 2 3 4 5]);
				case 3
					[~,idx] = Shuffle([1 2 3 4]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand Y-rand];
					xy = xy(:,idx);
					target2.xPositionOut = xy(1,1);
					target2.yPositionOut = xy(2,1);
					distractor1.xPositionOut = xy(1,2);
					distractor1.yPositionOut = xy(2,2);
					distractor2.xPositionOut = xy(1,3);
					distractor2.yPositionOut = xy(2,3);
					distractor3.xPositionOut = xy(1,4);
					distractor3.yPositionOut = xy(2,4);
					hide(set);
					show(set,[1 2 3 4 5 6]);
				otherwise
					[~,idx] = Shuffle([1 2 3 4 5]);
					x = (0:sep:sep*N) - (sep*N/2);
					xy = [x; Y+rand Y-rand Y+rand Y-rand Y+rand];
					xy = xy(:,idx);
					target2.xPositionOut = xy(1,1);
					target2.yPositionOut = xy(2,1);
					distractor1.xPositionOut = xy(1,2);
					distractor1.yPositionOut = xy(2,2);
					distractor2.xPositionOut = xy(1,3);
					distractor2.yPositionOut = xy(2,3);
					distractor3.xPositionOut = xy(1,4);
					distractor3.yPositionOut = xy(2,4);
					distractor4.xPositionOut = xy(1,5);
					distractor4.yPositionOut = xy(2,5);
					hide(set);
					show(set,[1 2 3 4 5 6 7]);
			end
			
			r = randi(target1.nImages); stimulus = r;
			target1.selectionOut = r;
			target2.selectionOut = r;
			rr = r;
			for jj = 4:7
				r = randi(set{jj}.nImages);
				while any(r == rr)
					r = randi(set{jj}.nImages);
				end
				set{jj}.selectionOut = r;
				rr = [rr r];
			end

			update(set);
			
			% reset touch window for initial touch
			tM.window.radius = fix.size/2;
			tM.window.init = 5;
			tM.window.hold = 0.05;
			tM.window.release = 1.0;
			tM.window.X = in.initPosition(1);
			tM.window.Y = in.initPosition(2);
			tM.window.doNegation = true;
			tM.exclusionZone = [];

			res = 0; phase = 1;
			keepRunning = true;
			touchResponse = '';
			anyTouch = false;
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			
			%% Initiate a trial with a touch target
			[touchInit, hldtime, anyTouch, keepRunning, dt] = clutil.startTouchTrial(trialN, in, tM, sbg, s, fix, hldtime, anyTouch, quitKey, keepRunning, dt);

			if matches(string(touchInit),"yes")
				touchResponse = '';
				[x,y] = set.getFixationPositions;
				tM.window.radius = target2.size/2;
				tM.window.init = in.trialTime;
				tM.window.hold = 0.05;
				tM.window.release = 1;
				tM.window.X = x;
				tM.window.Y = y;
				vblInit = GetSecs; vbl = vblInit;
				while isempty(touchResponse) && vbl < (vblInit + in.trialTime)
					if ~isempty(sbg); draw(sbg); end
					draw(set);
					if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
						drawText(s, txt);
						[xy] = s.toPixels([tM.x tM.y]);
						Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
					end
					vbl = flip(s);
					[touchResponse, hld, hldtime, rel, reli, se, fail, tch] = testHold(tM,'yes','no');
					if tch; anyTouch = true; end
					txt = sprintf('Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i tch:%i WR: %.1f WInit: %.2f WHold: %.2f WRel: %.2f WX: %.2f WY: %.2f',...
						touchResponse, tM.x, tM.y, hld, hldtime, rel, reli, se, tch, ...
						tM.window.radius,tM.window.init,tM.window.hold,tM.window.release,tM.window.X,tM.window.Y);
					[~,~,c] = KbCheck();
					if c(quitKey); keepRunning = false; break; end
				end
			end

			if ~isempty(sbg); draw(sbg); else; drawBackground(s,in.bg); end
			vblEnd = flip(s);
			WaitSecs(0.05);

			% lets check the result:
			if anyTouch == false
				
			elseif strcmp(touchResponse,'yes')
				if in.reward; giveReward(rM, in.rewardTime); end
				dt.data.rewards = dt.data.rewards + 1;
				fprintf('===> CORRECT :-)\n');
				beep(a,in.correctBeep,0.1,in.audioVolume);
				update(dt, true, phase, trialN, vblEnd-vblInit, stimulus);
				if ~isempty(sbg); draw(sbg); end
				drawText(s,['CORRECT! phase: ' num2str(phase)]);
				flip(s);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs(0.5+rand);
			elseif strcmp(touchResponse,'no')
				update(dt, false, phase, trialN, vblEnd-vblInit, stimulus);
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,['FAIL! phase: ' num2str(phase)]);
				flip(s);
				beep(a,in.incorrectBeep,0.5,in.audioVolume);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs('YieldSecs',in.timeOut);
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				if ~isempty(sbg); draw(sbg); end
				flip(s);
				broadcast.send(struct('task',in.task,'name',in.name,'trial',trialN,'result',dt.data.result));
				WaitSecs(0.5+rand);
			end

			%% finalise this trial
			if keepRunning == false; break; end
			drawBackground(s,in.bg)
			if ~isempty(sbg); draw(sbg); end
			flip(s);
			if ~isempty(zmq) && zmq.poll('in')
				[cmd, ~] = zmq.receiveCommand();
				if ~isempty(cmd) && isstruct(cmd)
					if isfield(msg,'command') && matches(msg.command,'exittask')
						break;
					end
				end
			end
		end % while keepRunning

		clutil.shutDownTask(s, sbg, fix, set, target1, target2, tM, rM, saveName, dt, in, trialN);

	catch ME
		getReport(ME)
		try reset(rtarget); end %#ok<*TRYNC>
		try reset(fix); end
		try reset(set); end
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
