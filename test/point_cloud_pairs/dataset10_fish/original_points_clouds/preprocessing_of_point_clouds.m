% Notes:
% - for this dataset point-to-point with ByID matching is the only reasonable option. Thus, we set
%   for all points as it does not matter:
%   - nx = 1
%   - ny = 0
%   - roughness = 0
%   - linearity = 1

clc; clear; close;

restoredefaultpath;

addpath('../../../../src');

convertpc('fish_target.txt', '../pcFix.csv')
convertpc('fish_source.txt', '../pcMov.csv')

function convertpc(inputFilepath, outputFilepath)

X = readmatrix(inputFilepath);
X = round(X, 4);
scale = 10;
X = X*scale;
noPoints = size(X,1);
pc = ptCloud;
pc.x = X(:,1);
pc.y = X(:,2);
pc.A.class = zeros(noPoints,1);
pc.A.nx = ones(noPoints,1);
pc.A.ny = zeros(noPoints,1);
pc.A.roughness = zeros(noPoints,1);
pc.A.linearity = ones(noPoints,1);
pc.A.corrId = transpose(1:noPoints);
pc.act = true(noPoints,1);
pc.export(outputFilepath);

end