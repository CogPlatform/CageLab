function [session, error] = endAlyxSession(r, session, result)
	%ENDALYXSESSION End an Alyx session for the current experiment.
	%   [session, error] = ENDALYXSESSION(r, session, result) finalizes
	%   an Alyx session and uploads registered files to the MINIO AWS server.
	%
	%   Inputs:
	%       r       - Struct containing the alyxManager and path information.
	%       session - Struct containing session metadata (subject, lab, etc.).
	%       result  - String indicating the result of the experiment (e.g., "PASS", "FAIL").
	%
	%   Outputs:
	%       session - Updated session struct with finalization status and URL.
	%       error   - String containing any error messages.
	arguments (Input)
		r struct
		session struct
		result string = "FAIL"
	end

	arguments (Output)
		session struct
		error string
	end

	if ~session.useAlyx; return; end

	alyx = r.alyx;
	error = '';

	%% close the session
	fprintf('≣≣≣≣⊱ Closing ALYX Session: %s\n', alyx.sessionURL);
	finalisedSession = alyx.closeSession('', result);
	if isempty(finalisedSession)
		error = 'Failed to finalise ALYX session!';
		return;
	end

	%% upload the data
	try
		%% register the files to ALYX
		[datasets, filenames] = alyx.registerALFFiles(alyx.paths, session);


		fprintf('≣≣≣≣⊱ Added Files to ALYX Session: %s\n', alyx.sessionURL);
		try arrayfun(@(ss)disp([ss.name ' - bytes: ' num2str(ss.file_size)]),datasets); end

		%% get the ALYX UUID for each file registered
		uuids = {};
		if length(datasets) == length(filenames)
			for ii = 1:length(filenames)
				if contains(filenames{ii},datasets(ii).name)
					uuids{ii} = datasets(ii).id;
				else
					uuids{ii} = '';
				end
			end
		end

		%% upload the files to MINIO AWS server
		secrets = alyx.getSecrets;
		if ~isempty(secrets.AWS_ID)
			aws = awsManager(secrets.AWS_ID,secrets.AWS_KEY, session.dataURL);
			bucket = lower(session.labName);
			aws.checkBucket(bucket);
			for ii = 1:length(filenames)
				[~,f,e] = fileparts(filenames{ii});
				if ~isempty(uuids) && ~isempty(uuids{ii})
					% append the uuid to the filename, seems to
					% be required by ONE protocol
					key = [alyx.paths.ALFKeyShort filesep f '.' uuids{ii} e];
				else
					key = [alyx.paths.ALFKeyShort filesep f e];
				end
				aws.copyFiles(filenames{ii}, bucket, key);
			end
		else
			warning('To upload Alyx files you need to set setSecrets: AWS_ID and AWS_KEY!!!');
			warning('YOU MUST UPLOAD MANUALLY NOW!!!');
			error = sprintf('Could not upload files to Server!!!!!!\n');
		end
	catch ME
		getReport(ME)
		error = sprintf('Could not register datasets for session: %s with error %s\n', alyx.sessionURL, ME.message);
		datasets = [];
		return;
	end
	if ~isempty(error)
		warning(error);
	end

end