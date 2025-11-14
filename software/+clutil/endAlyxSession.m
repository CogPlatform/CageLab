function session = endAlyxSession(r, session, result)
%FINALISEALYXSESSION Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
	r struct
	session struct
	result string = "FAIL"
end

arguments (Output)
	session struct
end

if ~session.useAlyx; return; end

alyx = r.alyx;

%% close the session
fprintf('≣≣≣≣⊱ Closing ALYX Session: %s\n', alyx.sessionURL);
finalisedSession = alyx.closeSession('', result);

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
	end
catch ME
	getReport(ME)
end

end