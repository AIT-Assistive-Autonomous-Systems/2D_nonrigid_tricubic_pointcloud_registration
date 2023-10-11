clc; clear; close;

outdir = 'point_cloud_pairs/scenario01_rotation-only';

pcFix = syntheticPtCloud;

pcFix.addRectangle(5, 0, 15, 10, 0.2, 1);
pcFix.addRectangle(-40, -20, 5, 8, 0.2, 1);
pcFix.addLine(-45, -5, -35, 5, 0.2, 2);
pcFix.addLine(-45, 5, -35, -5, 0.2, 2);
pcFix.addLine(-45, -10, 15, -10, 0.2, 2);
pcFix.addLine(-45, -11.5, 15, -11.5, 0.2, 2);
pcFix.addLine(-25, -28, -25, 10, 0.2, 2);
pcFix.addLine(-26.5, -28, -26.5, 10, 0.2, 2);
pcFix.addLine(-7.5, -8, -7.5, 8, 2, 2);
pcFix.addLine(-20, -18, 5, -18, 2, 2);
pcFix.addCircle(-17, 0, 4, 0.2, 3);
pcFix.addCircle(10, -20, 2, 0.2, 3);

pcFix.estimateNormals('SearchRadius', 1);
pcFix.A.corrId = transpose(1:pcFix.noPoints);

pcMov = pcFix.copy;

% pcMov.transformByShift(-1.2, 2);
pcMov.transformByRotation(2*pi/180, 10, 15);
% pcMov.transformBySinusFunction('x', 15, 2);
% pcMov.transformBySinusFunction('y', 15, 2);

pcMov.estimateNormals('SearchRadius', 1);

if ~exist(outdir, 'dir')
    mkdir(outdir);
end
pcFix.export(fullfile(outdir, 'pcFix.csv'));
pcMov.export(fullfile(outdir, 'pcMov.csv'));

% Plot
figure('Color', 'k');
pcFix.plot('MarkerSize', 10, 'Color', 'A.linearity'); hold on;
pcFix.plotNormals('Scale', 1);
pcMov.plot('MarkerSize', 10, 'Color', 'r');
setDarkMode(gca);
grid on;
axis equal;