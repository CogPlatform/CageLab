function session = endAlyxSession(alyx, session, result)
%FINALISEALYXSESSION Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
	alyx
	result string = "FAIL"
end

if ~session.useAlyx; return; end

if isempty(result); result = "FAIL"; end

fprintf('Closing ALYX Session: %s\n', alyx.sessionURL);
session = alyx.closeSession("", result);

if isSecret("AWS_ID")
	aws = awsManager(getSecret("AWS_ID"),getSecret("AWS_KEY"), "http://172.16.102.77:9000");
	buckets = aws.list;
	if ~contains(buckets,lower(session.labName))
		aws.createBucket(lower(session.labName));
	end
	p = alyx.paths.ALFPath;
	rp = [session.subjectName '/' alyx.paths.dateIDShort '/' sprintf('%0.3d',alyx.paths.sessionID)];
	try
		r = aws.copyFiles(p,lower(session.labName));
	catch
		warning('aws.copyFiles FAILED!');
	end
	d = dir(p);
	for i = 3:length(d)
		if r
			try
				dataset = alyx.registerFile(['Minio-' session.labName], d(i).name, rp);
				disp(dataset);
			catch
				warning('Failed to upload %s to minio',d(i).name);
			end
		end
		%dataset = alyx.registerFile('Local-Files', sname, rp);
	end
else
	warning("AWS ID and KEY are not present, cannot upload data to MINIO!!!");
end



end