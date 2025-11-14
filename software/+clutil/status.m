classdef status < handle
	% manages the status API in cogmoteGO: https://cogmotego.apifox.cn/get-exps-status

	properties
		% server IP and port
		ip = '127.0.0.1'
		port = 9012
	end

	properties(Dependent=true, GetAccess=public)
		% depends in ip and port
		baseURI
	end

	properties (Constant, Access = private)
		basePath = {'api', 'status'};
		headers = [matlab.net.http.field.ContentTypeField("application/json")];
		http_get = matlab.net.http.RequestMethod.GET;
		http_patch = matlab.net.http.RequestMethod.PATCH;
	end

	methods
		%% constructor
		function obj = status(ip, port)
			if exist('ip','var') && ~isempty(ip); obj.ip = ip; end
			if exist('port','var') && ~isempty(port); obj.port = port; end
		end

		%% get baseURI
		function baseURI = get.baseURI(obj)
			baseURI = matlab.net.URI(sprintf('http://%s:%i', obj.ip, obj.port));
		end

		%% update status
		function response = updateStatus(obj, isRunning, id)
			arguments(Input)
				obj (1,1) status
				isRunning (1,1) logical = logical([])
				id (1,:) char = ''
			end
			arguments(Output)
				response
			end
			if ~isempty('isRunning','var'); msg.is_running = isRunning; end
			if ~isempty('id','var'); msg.id = id; end
			msgBody = matlab.net.http.MessageBody(msg);
			request = matlab.net.http.RequestMessage(obj.http_patch, obj.headers, msgBody);

			updateURL = obj.baseURI;
			updateURL.Path = obj.basePath;

			response = obj.sendRequest(request, updateURL);
		end

		%% set status to true
		function response = updateStatusToRunning(obj)
			response = obj.updateStatus(true);
		end

		%% set status to false
		function response = updateStatusToStopped(obj)
			response = obj.updateStatus(false);
		end

		%% get status
		function [isRunning, id, response] = getStatus(obj)
			arguments(Input)
				obj
			end
			arguments(Output)
				isRunning (1,1) logical
				id (1,:) char
				response
			end
			isRunning = false; id = ''; response = [];
			request = matlab.net.http.RequestMessage(obj.http_get, obj.headers);
			updateURL = obj.baseURI;
			updateURL.Path = obj.basePath;
			response = obj.sendRequest(request, updateURL);
			if isempty(response); return; end
			try isRunning = response.Body.Data.is_running; end
			try id = response.Body.Data.id; end
		end
	end

	methods (Access = private)
		%% send request
		function response = sendRequest(~, request, url)
			try
				response = request.send(url);
			catch exception
				disp("Error: Failed to send request - " + exception.message);
				response = [];
			end
		end
	end
end