function [session, success] = initAlyxSession(alyx, session)
%INITALYXSESSION.M Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
	alyx = []
	session struct = []
end

arguments (Output)
	url string
	success logical
end

if isempty(alyx) || ~isa(alyx, 'alyxManager')
	alyx = alyxManager;
end

[path,id,dateID,name] = alyx.getALF(session.subjectName, session.labName, true);

if ~alyx.loggedIn; alyx.login; end

[url] = alyx.newExp(alyx.paths.ALFPath, session.paths.sessionID, session);
session.sessionURL = url;
fprintf('≣≣≣≣⊱ Alyx File Path Path: %s \n\t  Alyx URL: %s...\n',me.paths.ALFPath, me.paths.sessionURL);
	
end