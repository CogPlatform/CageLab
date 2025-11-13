classdef status < handle
    properties
		ip = 'localhost'
		port = 9012
        basePath = {'api', 'status'};
        headers = [matlab.net.http.field.ContentTypeField("application/json")];
        http_get = matlab.net.http.RequestMethod.GET;
        http_patch = matlab.net.http.RequestMethod.PATCH;
	end

	properties(Dependent=true, GetAccess=public)
		% depends in ip and port
		baseURI
	end

    methods
        function obj = status(ip,port)
			if exist('ip','var'); obj.ip = ip; end
			if exist('port','var'); obj.port = port; end
		end

		function baseURI = get.baseURI(obj)
			baseURI = matlab.net.URI(sprintf('http://%s:%d', obj.ip, obj.port));
		end

		function response = updateStatus(obj, isRunning, id)
			if exist('isRunning','var'); msg.is_running = isRunning; end
			if exist('id','var'); msg.id = id; end
			msgBody = matlab.net.http.MessageBody(msg);
            request = matlab.net.http.RequestMessage(obj.http_patch, obj.headers, msgBody);

            updateURL = obj.baseURI;
            updateURL.Path = obj.basePath;

            response = obj.sendRequest(request, updateURL);
        end

        function response = updateStatusToRunning(obj)
            msg = struct('is_running', true);
            response = obj.updateStatus(msg);
        end

        function response = updateStatusToStopped(obj)
            msg = struct('is_running', false);
            response = obj.updateStatus(msg);
		end

        function [isRunning, id, response] = getStatus(obj)
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