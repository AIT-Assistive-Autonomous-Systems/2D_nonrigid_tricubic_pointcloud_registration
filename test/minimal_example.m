clc; clear; close;

addpath('../src')

% Parameters
prm.cellSize = 5;
prm.buffer = 10;
prm.errorMetric = 'point-to-point';
prm.weightZeroObsF = 0.02;
prm.weightZeroObsFxFy = 0.01;
prm.weightZeroObsFxy = 0.01;

% Read point clouds
pcFix = ptCloud(Filename='point_cloud_pairs/dataset10_fish/pcFix.csv');
pcMov = ptCloud(Filename='point_cloud_pairs/dataset10_fish/pcMov.csv');

% Create optimization object
adjustment = estimateTrafo(pcFix, pcMov);

% Initialize translation grids
adjustment.pcMov.initializeTranslationGrids(...
    prm.cellSize, ...
    Buffer=prm.buffer);

% Select points for matching
adjustment.selectPoints;

% Match points by id
adjustment.match(Mode='ById');

% Run adjustment! (no additional iterations needed, since we are matching by id)
adjustment.adjustment(...
    WeightZeroObsF=prm.weightZeroObsF, ...
    WeightZeroObsFx=prm.weightZeroObsFxFy, ...
    WeightZeroObsFy=prm.weightZeroObsFxFy, ...
    WeightZeroObsFxy=prm.weightZeroObsFxy, ...
    ErrorMetric=prm.errorMetric);

% Plot original state
figure('Color', 'w');
tiledlayout(1,2)
nexttile
plot(adjustment.pcMov.x, adjustment.pcMov.y, 'r.', 'MarkerSize', 20);
hold on
plot(adjustment.pcFix.x, adjustment.pcFix.y, 'b.', 'MarkerSize', 10);
legend('Loose', 'Fixed')
title('Original state')
axis equal tight;
xlim([-15 11]); ylim([-13 22]);

% Plot adjusted state
nexttile
plot(adjustment.pcMov.xT, adjustment.pcMov.yT, 'r.', 'MarkerSize', 20);
hold on
plot(adjustment.pcFix.x, adjustment.pcFix.y, 'b.', 'MarkerSize', 10);
legend('Loose', 'Fixed')
title('Adjusted state')
axis equal tight;
xlim([-15 11]); ylim([-13 22]);