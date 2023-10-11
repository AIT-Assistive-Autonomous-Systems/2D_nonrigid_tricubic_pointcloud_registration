function struct2json(struct, jsonFilepath)
% STRUCT2JSON Convert matlab struct to json file.

text = jsonencode(struct);

% Write file
fid = fopen(jsonFilepath, 'wt');
fwrite(fid, text);
fclose(fid);

end