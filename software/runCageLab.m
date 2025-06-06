function runCageLab(cmd)
	% Note, this is used only for App deployment
	disp('===>>> Running CageLab via App Deployment…');
	disp(['===>>> $HOME is: ' getenv('HOME')]);
	disp(['===>>> App root is: ' ctfroot]);
	disp(['===>>> PTB root is: ' PsychtoolboxRoot]);
	disp(['===>>> PTB config is: ' PsychtoolboxConfigDir]);
	switch lower(cmd)
		case 'gui'
			disp('===>>> Running CageLab GUI…');
			CageLab;
		case 'server'
			disp('===>>> Running CageLab Server…');
			c = theConductor();
			run(c)
		otherwise
			error('Unknown command: %s', cmd);
	end
end
