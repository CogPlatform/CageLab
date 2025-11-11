function touchTest(dev, screenId, verbose)
	arguments(Input)
		dev = []
		screenId = max(Screen('Screens'))
		verbose = true
	end

	PsychDefaultSetup(2);

	% If no user-specified 'dev' was given, try to auto-select:
	if isempty(dev)
		% Get first touchscreen:
		dev = min(GetTouchDeviceIndices([], 1));
	end

	if isempty(dev)
		% Get first touchpad if no touchscreen found:
		dev = min(GetTouchDeviceIndices([], 0));
	end

	if isempty(dev) || ~ismember(dev, GetTouchDeviceIndices)
		fprintf('No touch input device found, or invalid dev given. Bye.\n');
		return;
	else
		fprintf('Touch device properties:\n');
		info = GetTouchDeviceInfo(dev);
		disp(info);
	end

	% Open a default onscreen window with black background color and 0-1 color range:
	[w, rect] = PsychImaging('OpenWindow', screenId, 0.1);

	% Get maximum supported dot diameter for smooth dots:
	[~, maxSmoothPointSize] = Screen('DrawDots', w);

	% Select good diameter for touch point blobs, but no more than what 'DrawDots' supports:
	baseSize = min(RectWidth(rect) / 10, maxSmoothPointSize);

	try
		% Create and start touch queue for window and device:
		TouchQueueCreate(w, dev);
		TouchQueueStart(dev);

		% Wait for the go!
		KbReleaseWait;

		% blobcol tracks active touch points - and dying ones:
		blobcol = {};
		buttonstate = 0;
		blobmin = inf;

		vbl = Screen('Flip',w); start = vbl;

		% Main loop: Run until keypress:
		while vbl < start + 20
			% Process all currently pending touch events:
			while TouchEventAvail(dev)
				% Process next touch event 'evt':
				evt = TouchEventGet(dev, w);

				% Touch blob id - Unique in the session at least as
				% long as the finger stays on the screen:
				id = evt.Keycode;

				% Keep the id's low, so we have to iterate over less blobcol slots
				% to save computation time:
				if isinf(blobmin)
					blobmin = id - 1;
				end
				id = id - blobmin;

				if evt.Type == 0
					% Not a touch point, but a button press or release on a
					% physical (or emulated) button associated with the touch device:
					buttonstate = evt.Pressed;
					continue;
				end

				if evt.Type == 1
					% Not really a touch point, but movement of the
					% simulated mouse cursor, driven by the primary
					% touch-point:
					Screen('DrawDots', w, [evt.MappedX; evt.MappedY], baseSize, [1,1,1], [], 1, 1);
					continue;
				end

				if evt.Type == 2
					% New touch point -> New blob!
					blobcol{id}.col = rand(3, 1);
					blobcol{id}.mul = 1.0;
					blobcol{id}.x = evt.MappedX;
					blobcol{id}.y = evt.MappedY;
					blobcol{id}.t = evt.Time;
					% Track time delta in msecs between touch point updates:
					blobcol{id}.dt = 0;
				end

				if evt.Type == 3
					% Moving touch point -> Moving blob!
					blobcol{id}.x = evt.MappedX;
					blobcol{id}.y = evt.MappedY;
					blobcol{id}.dt = ceil((evt.Time - blobcol{id}.t) * 1000);
					blobcol{id}.t = evt.Time;
				end

				if evt.Type == 4
					% Touch released - finger taken off the screen -> Dying blob!
					blobcol{id}.mul = 0.999;
					blobcol{id}.x = evt.MappedX;
					blobcol{id}.y = evt.MappedY;
				end

				if evt.Type == 5
					% Lost touch data for some reason:
					% Flush screen red for one video refresh cycle.
					fprintf('Ooops - Sequence data loss! 3rd party interference or overload?\n');
					Screen('FillRect', w, [1 0 0]);
					Screen('Flip', w);
					Screen('FillRect', w, 0);
					continue;
				end
			end

			% Now that all touches for this iteration are processed, repaint screen
			% with all live blobs at their new positions, and fade out the dying/orphaned
			% blobs:
			for i=1:length(blobcol)
				if ~isempty(blobcol{i}) && blobcol{i}.mul > 0.1
					% Draw it: .mul defines size of the blob:
					Screen('DrawDots', w, [blobcol{i}.x, blobcol{i}.y], blobcol{i}.mul * baseSize, blobcol{i}.col, [], 1, 1);
					if blobcol{i}.mul < 1
						% An orphaned blob with no finger touching anymore, so slowly fade it out:
						blobcol{i}.mul = blobcol{i}.mul * 0.95;
					else
						% An active touch. Print its unique touch id and dT timestamp delta between updates in msecs:
						if verbose
							Screen('DrawText', w, num2str(i), blobcol{i}.x, blobcol{i}.y, [1 1 0]);
							Screen('DrawText', w, num2str(blobcol{i}.dt), blobcol{i}.x, blobcol{i}.y - 100, [1 1 0]);
						end
					end
				else
					% Below threshold: Kill the blob:
					blobcol{i} = [];
				end
			end

			if buttonstate
				Screen('FrameRect', w, [1, 1, 0], [], 5);
			end

			% Done repainting - Show it:
			vbl = Screen('Flip', w);

			% Next touch processing -> redraw -> flip cycle:
		end

		TouchQueueStop(dev);
		TouchQueueRelease(dev);
		RestrictKeysForKbCheck([]);
		ShowCursor(w);
		sca;
	catch
		TouchQueueRelease(dev);
		RestrictKeysForKbCheck([]);
		sca;
		psychrethrow(psychlasterror);
	end
end
