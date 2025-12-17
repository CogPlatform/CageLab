function [session, success] = initAlyxSession(r, session)
%INITALYXSESSION.M init a alyx session
%   Detailed explanation goes here
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