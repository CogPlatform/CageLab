function [object,files] = getThingsImages(in)

if ~exist(in.folder,'dir'); error("No resource folder available!"); end

% Image file extensions to look for
imageExts = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tif', '.tiff', '.webp'};

object = struct;
files = string.empty;

d = dir(in.folder);

for ii = 1:length(d)
	if d(ii).isdir == false || matches(d(ii).name,[".","..",".git"]); continue; end
	
	% Get the folder name
	folderName = d(ii).name;
	folderPath = fullfile(d(ii).folder, folderName);
	
	% Store folder info
	object.(folderName).name = folderPath;
	object.(folderName).files = {};
	
	% Get all files in this subfolder (one level deep)
	subFiles = dir(fullfile(folderPath, '*.*'));
	
	for jj = 1:length(subFiles)
		% Skip directories and navigation entries
		if subFiles(jj).isdir; continue; end
		
		% Check if file has an image extension
		[~, ~, ext] = fileparts(subFiles(jj).name);
		if ~any(strcmpi(ext, imageExts)); continue; end
		
		% Build full path
		fullPath = fullfile(subFiles(jj).folder, subFiles(jj).name);
		
		% Add to object's file list
		object.(folderName).files{end+1} = fullPath;
		
		% Add to global files array
		files(end+1) = fullPath;
	end

	% get number of files in each collection.
	object.(folderName).N = length(object.(folderName).files);
	
	% Convert cell array to string array for consistency
	object.(folderName).files = string(object.(folderName).files);
end

% I want to show 3 pictures per trial. Each trial should be a unique combination across the objects. For example say I have object.A with 4 images, object.B with 5 images and object.C with 6 images. Then I want to show all 4*5*6 = 120 combinations before repeating any. The order should be randomised.
% The output should be a table with 3 columns (A, B, C) and 120 rows. Each row should be a unique combination of images from the objects. The order of the rows should be randomised.
% The input is the object structure created above.

% Get field names (object categories)
fieldNames = fieldnames(object);
nCategories = length(fieldNames);

% Option to equalize image counts across categories
% If in.equalizeImages is true, use only the smallest N images from each category
if isfield(in, 'equalizeImages') && in.equalizeImages
	if isfield(in, 'equalizeN')
		minImages = in.equalizeN;
	else
		% Find minimum number of images across all categories
		minImages = inf;
		for ii = 1:nCategories
			minImages = min(minImages, object.(fieldNames{ii}).N);
		end
	end
	
	% Trim each category to use only the first minImages
	for ii = 1:nCategories
		fn = fieldNames{ii};
		if object.(fn).N > minImages
			object.(fn).files = object.(fn).files(1:minImages);
			object.(fn).N = minImages;
		end
	end
end

% Each trial shows exactly 3 pictures from 3 different categories
nPicsPerTrial = 3;

if nCategories < nPicsPerTrial
	error('Need at least %d categories, but only found %d', nPicsPerTrial, nCategories);
end

% Get all combinations of 3 categories from available categories
% Using nchoosek to get all C(n,3) combinations
categoryCombinations = nchoosek(1:nCategories, nPicsPerTrial);
nCategoryCombos = size(categoryCombinations, 1);

% For each category combination, generate all image combinations
allTrials = {};

for cc = 1:nCategoryCombos
	% Get the 3 categories for this combination
	catIndices = categoryCombinations(cc, :);
	cat1 = fieldNames{catIndices(1)};
	cat2 = fieldNames{catIndices(2)};
	cat3 = fieldNames{catIndices(3)};
	
	% Get file lists for these 3 categories
	files1 = object.(cat1).files;
	files2 = object.(cat2).files;
	files3 = object.(cat3).files;
	
	% Generate all combinations of images from these 3 categories
	n1 = length(files1);
	n2 = length(files2);
	n3 = length(files3);
	
	[idx1, idx2, idx3] = ndgrid(1:n1, 1:n2, 1:n3);
	
	% Flatten and create combinations
	nCombos = n1 * n2 * n3;
	for tt = 1:nCombos
		allTrials{end+1, 1} = files1(idx1(tt));
		allTrials{end, 2} = files2(idx2(tt));
		allTrials{end, 3} = files3(idx3(tt));
	end
end

% Convert to table with column names A, B, C
object.trials = cell2table(allTrials, 'VariableNames', {'A', 'B', 'C'});

% Randomize the row order
nTrials = height(object.trials);
object.trials = object.trials(randperm(nTrials), :);

end
