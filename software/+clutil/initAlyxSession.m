function [session, success] = initAlyxSession(r, session)
%INITALYXSESSION Initialize an Alyx session for the current experiment.
%   [session, success] = INITALYXSESSION(r, session) registers or updates
%   a session record in the Alyx database using the manager stored in 'r'.
%
%   Inputs:
%       r       - Struct containing the alyxManager and path information.
%       session - Struct containing session metadata (subject, lab, etc.).
%
%   Outputs:
%       session - Updated session struct with initialization status and URL.
%       success - Logical flag indicating if the session was successfully created.
	arguments (Input)
		r struct
		session struct = []
	end
	arguments (Output)
		session struct
		success logical
	end

	if isempty(r.alyx) || ~isa(r.alyx, 'alyxManager')
		r.alyx = alyxManager;
		setSecrets(r.alyx);
	end

	alyx = r.alyx;
	alyx.logout;
	alyx.login;
	
	% create new session folder and name
	if ~exist(r.alyxPath)
		[path,id,dateID,name] = alyx.getALF(session.subjectName, session.labName, true);
		url = alyx.newExp(path, id, session);
	else
		url = alyx.newExp(r.alyxPath, r.sessionID, session);
	end

	if ~isempty(url)
		success = true;
		session.initialised = true;
		session.sessionURL = url;
		fprintf('≣≣≣≣⊱ Alyx File Path: %s \n\t  Alyx URL: %s...\n', alyx.paths.ALFPath, session.sessionURL);
	else
		session.sessionURL = '';
		session.initialised = false;
		success = false;
		warning('≣≣≣≣⊱ Failed to init Alyx File Path: %s\n',alyx.paths.ALFPath);
	end
	
end