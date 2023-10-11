function struct = json2struct(jsonFilepath)
% JSON2STRUCT Convert json file to matlab struct.

% Read file
fid = fopen(jsonFilepath, 'r');
text = textscan(fid, '%s');
fclose(fid);

% Convert to struct
json = horzcat(text{1}{:});
struct = jsondecode(json);

end