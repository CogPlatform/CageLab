function [session, success] = initAlyxSession(alyx, session)
%INITALYXSESSION.M init a alyx session
%   Detailed explanation goes here
	arguments (Input)
		alyx alyxManager
		session struct = []
	end
	arguments (Output)
		session struct
		success logical
	end
	
	if isempty(alyx) || ~isa(alyx, 'alyxManager')
		alyx = alyxManager;
		setSecrets(alyx);
	end
	
	% create new session folder and name
	[path,id,dateID,name] = alyx.getALF(session.subjectName, session.labName, true);
	
	if ~alyx.loggedIn; alyx.login; end
	
	[url] = alyx.newExp(alyx.paths.ALFPath, session.paths.sessionID, session);
	if ~isempty(url)
		success = true;
		session.sessionURL = url;
		fprintf('≣≣≣≣⊱ Alyx File Path: %s \n\t  Alyx URL: %s...\n', alyx.paths.ALFPath, session.sessionURL);
	else
		success = false;
		warning('≣≣≣≣⊱ Failed to init Alyx File Path: %s\n',alyx.paths.ALFPath);
	end
	
end