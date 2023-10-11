% Notes:
% - we omit z here
% - for this dataset point-to-point with ByID matching is the only reasonable option. Thus, we set
%   for all points as it does not matter:
%   - nx = 1
%   - ny = 0
%   - roughness = 0
%   - linearity = 1

clc; clear; close;

restoredefaultpath;

addpath('../../../../src');

convertpc('pcfix.xyz', '../pcFix.csv')
convertpc('pcmov.xyz', '../pcMov.csv')

function convertpc(inputFilepath, outputFilepath)

T = readtable(inputFilepath, 'FileType', 'delimitedtext');
pcfix = ptCloud;
pcfix.x = T.Var1;
pcfix.y = T.Var2;
pcfix.A.class = zeros(height(T),1);
pcfix.A.nx = ones(height(T),1);
pcfix.A.ny = zeros(height(T),1);
pcfix.A.roughness = zeros(height(T),1);
pcfix.A.linearity = ones(height(T),1);
pcfix.A.corrId = transpose(1:height(T));
pcfix.act = true(height(T),1);
pcfix.export(outputFilepath);

end