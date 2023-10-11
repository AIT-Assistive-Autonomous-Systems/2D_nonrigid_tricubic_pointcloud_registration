classdef nonrigidRegistrationGUI < handle
    
    properties
        
        arguments
        datasets % dirs containing point cloud pairs
        ui
        adjustment
        vCorr = []; % residuals
        
    end
    
    properties (Dependent)
        
        pathToPointClouds
        pathToInitialParams
        adjustmentOptions
        plotOptions
        
    end
    
    methods
        
        function obj = nonrigidRegistrationGUI(options)
            
            arguments
                options.pathToDatasets (1,1) string {mustBeFolder}
            end
            
            obj.arguments.options = options;
            
            % Get directory with to datasets if not specified
            if ~isfield(obj.arguments.options, 'pathToDatasets')
                obj.arguments.options.pathToDatasets = uigetdir;
                mustBeFolder(obj.arguments.options.pathToDatasets);
            end
            
            obj.getDatasets;
            
            % GUI
            obj.createFigureWithMainStructure
            obj.createMainMapFigure;
            
            obj.createListboxWithDatasets;
            obj.populateAdjustmentOptions;
            obj.populatePlotOptions;
            
            obj.runPipeline({'setParams' 'initializeAdjustment' 'plotMainMap'});
            
        end
        
        function getDatasets(obj)
            
            listing = dir(obj.arguments.options.pathToDatasets);
            
            % Keep only subdirs
            keep = true(numel(listing),1);
            for i = 1:numel(listing)
                if (i <= 2) || ~listing(i).isdir
                    keep(i) = false;
                end
            end
            
            obj.datasets = {listing(keep).name}';
            
        end
        
        function createFigureWithMainStructure(obj)
            
            % Main figure
            obj.ui.figures.main = uifigure;
            obj.ui.figures.main.Name = '2D_nonrigid_bicubic_pointcloud_registration';
            obj.ui.figures.main.Position = [200 350 550 550];
            obj.ui.figures.main.CloseRequestFcn = @(fig, event) closerequest(fig, obj);
            
            function closerequest(fig, obj)
                
                selection = uiconfirm(fig, 'Close application?', 'Confirmation');
                
                switch selection
                    case 'OK'
                        obj.close;
                        
                    case 'Cancel'
                        return
                end
                
            end
            
            % Configuration grid
            obj.ui.gridConfiguration = uigridlayout(obj.ui.figures.main, [2 1]);
            obj.ui.gridConfiguration.RowHeight = {'1x', 'fit'};
            
            % Tabs
            obj.ui.tabGroup = uitabgroup(obj.ui.gridConfiguration);
            obj.ui.tabGroup.Layout.Row = 2;
            obj.ui.tabGroup.Layout.Column = 1;
            obj.ui.adjustmentOptions.tab = uitab(obj.ui.tabGroup, 'Title', 'Adjustment');
            obj.ui.plotOptions.tab = uitab(obj.ui.tabGroup, 'Title', 'Plot');
            
        end
        
        function createMainMapFigure(obj)
            
            % Create figure and set general figure properties
            % We use an extra window for the axes (uses java only) as the integration of an axes
            % within an app (built on web technologies) is extremely slow and unresponsive.
            % https://www.mathworks.com/matlabcentral/answers/773307-unusable-uiaxes-axes-in-apps?s_tid=srchtitle
            obj.ui.figures.mainMap = figure;
            obj.setFigureProperties(obj.ui.figures.mainMap);
            
            % Set individual figure properties
            obj.ui.figures.mainMap.Name = '2D_nonrigid_bicubic_pointcloud_registration main map';
            obj.ui.figures.mainMap.Position = [750 200 900 700];
            
            % Create axes and set general axes properties
            obj.ui.axes.mainMap = axes(obj.ui.figures.mainMap);
            
        end
        
        function createListboxWithDatasets(obj)
            
            pipelineStages = {'setParams' 'initializeAdjustment' 'plotMainMap'};
            
            obj.ui.datasets.listbox = uilistbox(obj.ui.gridConfiguration);
            obj.ui.datasets.listbox.Items = obj.datasets;
            obj.ui.datasets.listbox.Layout.Row = 1;
            obj.ui.datasets.listbox.Layout.Column = 1;
            obj.ui.datasets.listbox.ValueChangedFcn =  ...
                @(src, event) runPipeline(obj, pipelineStages);
            
        end
        
        function populateAdjustmentOptions(obj)
            
            obj.ui.adjustmentOptions.grid = uigridlayout(obj.ui.adjustmentOptions.tab, [7 2]);
            obj.ui.adjustmentOptions.grid.ColumnWidth = {300, '1x'};
            
            idxRow = 0;
            
            % cellSize
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'cell size';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.editFieldCellSize = uieditfield(...
                obj.ui.adjustmentOptions.grid, 'numeric');
            obj.ui.adjustmentOptions.editFieldCellSize.Limits = [0 Inf];
            obj.ui.adjustmentOptions.editFieldCellSize.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.editFieldCellSize.Layout.Column = 2;
            
            % buffer
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'buffer';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.editFieldBuffer = uieditfield(...
                obj.ui.adjustmentOptions.grid, 'numeric');
            obj.ui.adjustmentOptions.editFieldBuffer.Limits = [0 Inf];
            obj.ui.adjustmentOptions.editFieldBuffer.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.editFieldBuffer.Layout.Column = 2;
            
            % weightZeroObsF
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            % label.Text = 'weight zero obs F';
            label.Text = 'w_d0';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsF = uieditfield(...
                obj.ui.adjustmentOptions.grid, 'numeric');
            obj.ui.adjustmentOptions.editFieldWeightZeroObsF.Limits = [0 Inf];
            obj.ui.adjustmentOptions.editFieldWeightZeroObsF.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsF.Layout.Column = 2;
            
            % weightZeroObsFxFy
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            % label.Text = 'weight zero obs Fx/Fy';
            label.Text = 'w_d1';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxFy = uieditfield(...
                obj.ui.adjustmentOptions.grid, 'numeric');
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxFy.Limits = [0 Inf];
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxFy.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxFy.Layout.Column = 2;
            
            % weightZeroObsFxy
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            % label.Text = 'weight zero obs Fxy';
            label.Text = 'w_d2';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxy = uieditfield(...
                obj.ui.adjustmentOptions.grid, 'numeric');
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxy.Limits = [0 Inf];
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxy.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxy.Layout.Column = 2;
            
            % optionalConstraints
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'optional constraints';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.dropdownOptionalConstraints = ...
                uidropdown(obj.ui.adjustmentOptions.grid);
            obj.ui.adjustmentOptions.dropdownOptionalConstraints.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.dropdownOptionalConstraints.Layout.Column = 2;
            obj.ui.adjustmentOptions.dropdownOptionalConstraints.Items = ...
                {'none'
                'x translation grid only'
                'y translation grid only'
                'x translation grid is constant'
                'y translation grid is constant'
                'x and y translation grids are constant'
                'rotation only'
                'rigid body transformation'
                'affine transformation'};
            
            % matchingMode
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'matching mode';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.dropdownMatchingMode = ...
                uidropdown(obj.ui.adjustmentOptions.grid);
            obj.ui.adjustmentOptions.dropdownMatchingMode.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.dropdownMatchingMode.Layout.Column = 2;
            obj.ui.adjustmentOptions.dropdownMatchingMode.Items = ...
                {'ById', 'NearestNeighbor'};
            
            % errorMetric
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'error metric';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.dropdownErrorMetric = ...
                uidropdown(obj.ui.adjustmentOptions.grid);
            obj.ui.adjustmentOptions.dropdownErrorMetric.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.dropdownErrorMetric.Layout.Column = 2;
            obj.ui.adjustmentOptions.dropdownErrorMetric.Items = ...
                {'point-to-point', 'point-to-line'};
            
            % minLinearity
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'min linearity of points for matching';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.editFieldMinLinearity = uieditfield(...
                obj.ui.adjustmentOptions.grid, 'numeric');
            obj.ui.adjustmentOptions.editFieldMinLinearity.Limits = [-1 1];
            obj.ui.adjustmentOptions.editFieldMinLinearity.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.editFieldMinLinearity.Layout.Column = 2;
            
            % noIterations
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.adjustmentOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'number of iterations';
            label.Layout.Row = idxRow;
            label.Layout.Column = 1;
            obj.ui.adjustmentOptions.editFieldNoIterations = uieditfield(...
                obj.ui.adjustmentOptions.grid, 'numeric');
            obj.ui.adjustmentOptions.editFieldNoIterations.RoundFractionalValues = 'on';
            obj.ui.adjustmentOptions.editFieldNoIterations.Limits = [1 Inf];
            obj.ui.adjustmentOptions.editFieldNoIterations.Layout.Row = idxRow;
            obj.ui.adjustmentOptions.editFieldNoIterations.Layout.Column = 2;
            
            % runAdjustment
            idxRow = idxRow+1;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            buttonRunAdjustment = uibutton(obj.ui.adjustmentOptions.grid);
            buttonRunAdjustment.Layout.Row = idxRow;
            buttonRunAdjustment.Layout.Column = 1;
            buttonRunAdjustment.Text = 'Run adjustment';
            buttonRunAdjustment.ButtonPushedFcn = ...
                @(src, event) runPipeline(obj, {'initializeAdjustment' 'runAdjustment' 'plotMainMap'});
            
            % reset
            idxRow = idxRow;
            obj.ui.adjustmentOptions.grid.RowHeight{idxRow} = 22;
            buttonReset = uibutton(obj.ui.adjustmentOptions.grid);
            buttonReset.Layout.Row = idxRow;
            buttonReset.Layout.Column = 2;
            buttonReset.Text = 'Reset';
            buttonReset.ButtonPushedFcn = ...
                @(src, event) runPipeline(obj, {'initializeAdjustment' 'plotMainMap'});
            
        end
        
        function populatePlotOptions(obj)
            
            obj.ui.plotOptions.grid = uigridlayout(obj.ui.plotOptions.tab, [8 3]);
            obj.ui.plotOptions.grid.ColumnWidth = {'1x', '1x', '1x'};
            
            pipelineStages = {'plotMainMap'};
            
            idxRow = 0;
            
            % Plot original point cloud?
            idxRow = idxRow+1;
            obj.ui.plotOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.plotOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'plot original point cloud?';
            label.Layout.Row = idxRow;
            label.Layout.Column = [1 2];
            obj.ui.plotOptions.checkboxPlotOriginalPointCloud = uicheckbox(obj.ui.plotOptions.grid);
            obj.ui.plotOptions.checkboxPlotOriginalPointCloud.Layout.Row = idxRow;
            obj.ui.plotOptions.checkboxPlotOriginalPointCloud.Layout.Column = 3;
            obj.ui.plotOptions.checkboxPlotOriginalPointCloud.Value = 1;
            obj.ui.plotOptions.checkboxPlotOriginalPointCloud.Text = '';
            obj.ui.plotOptions.checkboxPlotOriginalPointCloud.ValueChangedFcn = ...
                @(src, event) runPipeline(obj, pipelineStages);
            
            % Plot correspondences?
            idxRow = idxRow+1;
            obj.ui.plotOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.plotOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'plot correspondences?';
            label.Layout.Row = idxRow;
            label.Layout.Column = [1 2];
            obj.ui.plotOptions.checkboxPlotCorrespondences = uicheckbox(obj.ui.plotOptions.grid);
            obj.ui.plotOptions.checkboxPlotCorrespondences.Layout.Row = idxRow;
            obj.ui.plotOptions.checkboxPlotCorrespondences.Layout.Column = 3;
            obj.ui.plotOptions.checkboxPlotCorrespondences.Value = 1;
            obj.ui.plotOptions.checkboxPlotCorrespondences.Text = '';
            obj.ui.plotOptions.checkboxPlotCorrespondences.ValueChangedFcn = ...
                @(src, event) runPipeline(obj, pipelineStages);
            
            % Plot translation grid?
            idxRow = idxRow+1;
            obj.ui.plotOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.plotOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'plot grid cells?';
            label.Layout.Row = idxRow;
            label.Layout.Column = [1 2];
            obj.ui.plotOptions.checkboxPlotTranslationGrid = uicheckbox(obj.ui.plotOptions.grid);
            obj.ui.plotOptions.checkboxPlotTranslationGrid.Layout.Row = idxRow;
            obj.ui.plotOptions.checkboxPlotTranslationGrid.Layout.Column = 3;
            obj.ui.plotOptions.checkboxPlotTranslationGrid.Value = 1;
            obj.ui.plotOptions.checkboxPlotTranslationGrid.Text = '';
            obj.ui.plotOptions.checkboxPlotTranslationGrid.ValueChangedFcn = ...
                @(src, event) runPipeline(obj, pipelineStages);
            
            % Plot translation vectors?
            idxRow = idxRow+1;
            obj.ui.plotOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.plotOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'plot translation vectors?';
            label.Layout.Row = idxRow;
            label.Layout.Column = [1 2];
            obj.ui.plotOptions.checkboxPlotTranslationVectors = uicheckbox(obj.ui.plotOptions.grid);
            obj.ui.plotOptions.checkboxPlotTranslationVectors.Layout.Row = idxRow;
            obj.ui.plotOptions.checkboxPlotTranslationVectors.Layout.Column = 3;
            obj.ui.plotOptions.checkboxPlotTranslationVectors.Value = 1;
            obj.ui.plotOptions.checkboxPlotTranslationVectors.Text = '';
            obj.ui.plotOptions.checkboxPlotTranslationVectors.ValueChangedFcn = ...
                @(src, event) runPipeline(obj, pipelineStages);
            
            % Plot translation grid contours?
            idxRow = idxRow+1;
            obj.ui.plotOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.plotOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'translation grid contours';
            label.Layout.Row = idxRow;
            label.Layout.Column = [1 2];
            obj.ui.plotOptions.dropdownTranslationGridContours = ...
                uidropdown(obj.ui.plotOptions.grid);
            obj.ui.plotOptions.dropdownTranslationGridContours.Layout.Row = idxRow;
            obj.ui.plotOptions.dropdownTranslationGridContours.Layout.Column = 3;
            obj.ui.plotOptions.dropdownTranslationGridContours.Items = ...
                {'none' 'x' 'y'};
            obj.ui.plotOptions.dropdownTranslationGridContours.ValueChangedFcn = ...
                @(src, event) runPipeline(obj, pipelineStages);
            
            % dLevels
            idxRow = idxRow+1;
            obj.ui.plotOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.plotOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'contours dLevel';
            label.Layout.Row = idxRow;
            label.Layout.Column = [1 2];
            obj.ui.plotOptions.editFielddLevels = uieditfield(...
                obj.ui.plotOptions.grid, 'numeric');
            obj.ui.plotOptions.editFielddLevels.Limits = [0 Inf];
            obj.ui.plotOptions.editFielddLevels.Layout.Row = idxRow;
            obj.ui.plotOptions.editFielddLevels.Layout.Column = 3;
            obj.ui.plotOptions.editFielddLevels.Value = 0.2;
            obj.ui.plotOptions.editFielddLevels.ValueChangedFcn = ...
                @(src, event) runPipeline(obj, pipelineStages);
            
            % Show contour text?
            idxRow = idxRow+1;
            obj.ui.plotOptions.grid.RowHeight{idxRow} = 22;
            label = uilabel(obj.ui.plotOptions.grid);
            label.HorizontalAlignment = 'right';
            label.Text = 'show contour text?';
            label.Layout.Row = idxRow;
            label.Layout.Column = [1 2];
            obj.ui.plotOptions.checkboxShowText = uicheckbox(obj.ui.plotOptions.grid);
            obj.ui.plotOptions.checkboxShowText.Layout.Row = idxRow;
            obj.ui.plotOptions.checkboxShowText.Layout.Column = 3;
            obj.ui.plotOptions.checkboxShowText.Value = 0;
            obj.ui.plotOptions.checkboxShowText.Text = '';
            obj.ui.plotOptions.checkboxShowText.ValueChangedFcn = ...
                @(src, event) runPipeline(obj, pipelineStages);
            
            % Button: surf plot of translation grids
            idxRow = idxRow+2;
            obj.ui.plotOptions.grid.RowHeight{idxRow} = 22;
            buttonSurfPlotTranslationGrids = uibutton(obj.ui.plotOptions.grid);
            buttonSurfPlotTranslationGrids.Layout.Row = idxRow;
            buttonSurfPlotTranslationGrids.Layout.Column = 1;
            buttonSurfPlotTranslationGrids.Text = '3D grid view';
            buttonSurfPlotTranslationGrids.ButtonPushedFcn = ...
                @(src, event) runPipeline(obj, {'surfPlotTranslationGrids'});
            
            buttonPlotHistogramOfResidualsPlot = uibutton(obj.ui.plotOptions.grid);
            buttonPlotHistogramOfResidualsPlot.Layout.Row = idxRow;
            buttonPlotHistogramOfResidualsPlot.Layout.Column = 2;
            buttonPlotHistogramOfResidualsPlot.Text = 'Histogram residuals';
            buttonPlotHistogramOfResidualsPlot.ButtonPushedFcn = ...
                @(src, event) runPipeline(obj, {'plotHistogramOfResiduals'});
            
        end
        
        function runPipeline(obj, stages)
            
            arguments
                obj
                stages (1,:) cell
            end
            
            for i = 1:numel(stages)
                obj.(stages{i});
            end
            
        end
        
        function setParams(obj)
            
            % Set default params
            obj.ui.adjustmentOptions.editFieldCellSize.Value = 10;
            obj.ui.adjustmentOptions.editFieldBuffer.Value = 20;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsF.Value = 0.1;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxFy.Value = 0.1;
            obj.ui.adjustmentOptions.editFieldWeightZeroObsFxy.Value = 0.1;
            obj.ui.adjustmentOptions.dropdownOptionalConstraints.Value = 'none';
            obj.ui.adjustmentOptions.dropdownMatchingMode.Value = 'ById';
            obj.ui.adjustmentOptions.dropdownErrorMetric.Value = 'point-to-point';
            obj.ui.adjustmentOptions.editFieldMinLinearity.Value = -1;
            obj.ui.adjustmentOptions.editFieldNoIterations.Value = 5;
            
            % Set params from file (if it exists)
            if ~isempty(obj.pathToInitialParams)
                params = json2struct(obj.pathToInitialParams);
                
                if isfield(params, 'cellSize')
                    obj.ui.adjustmentOptions.editFieldCellSize.Value = params.cellSize;
                end
                if isfield(params, 'buffer')
                    obj.ui.adjustmentOptions.editFieldBuffer.Value = params.buffer;
                end
                if isfield(params, 'weightZeroObsF')
                    obj.ui.adjustmentOptions.editFieldWeightZeroObsF.Value = params.weightZeroObsF;
                end
                if isfield(params, 'weightZeroObsFxFy')
                    obj.ui.adjustmentOptions.editFieldWeightZeroObsFxFy.Value = params.weightZeroObsFxFy;
                end
                if isfield(params, 'weightZeroObsFxy')
                    obj.ui.adjustmentOptions.editFieldWeightZeroObsFxy.Value = params.weightZeroObsFxy;
                end
                if isfield(params, 'optionalConstraints')
                    obj.ui.adjustmentOptions.dropdownOptionalConstraints.Value = params.optionalConstraints;
                end
                if isfield(params, 'matchingMode')
                    obj.ui.adjustmentOptions.dropdownMatchingMode.Value = params.matchingMode;
                end
                if isfield(params, 'errorMetric')
                    obj.ui.adjustmentOptions.dropdownErrorMetric.Value = params.errorMetric;
                end
                if isfield(params, 'minLinearity')
                    obj.ui.adjustmentOptions.editFieldMinLinearity.Value = params.minLinearity;
                end
                if isfield(params, 'noIterations')
                    obj.ui.adjustmentOptions.editFieldNoIterations.Value = params.noIterations;
                end
            end
            
        end
        
        function initializeAdjustment(obj)
            
            logging(sprintf('Initialize adjustment for dataset "%s"', ...
                obj.ui.datasets.listbox.Value));
            
            % Reset residuals
            obj.vCorr = [];
            
            % Read point clouds
            pcFix = ptCloud(Filename=obj.pathToPointClouds.pcFix);
            pcMov = ptCloud(Filename=obj.pathToPointClouds.pcMov);
            
            % Create optimization object
            obj.adjustment = estimateTrafo(pcFix, pcMov);
            
            % Initialize translation grids
            obj.adjustment.pcMov.initializeTranslationGrids(...
                obj.adjustmentOptions.cellSize, ...
                Buffer=obj.adjustmentOptions.buffer);
            obj.adjustment.pcMov.addPointsForTranslationVectors(...
                dxy=obj.adjustmentOptions.cellSize/5);
            
            % Select points for matching
            if strcmp(obj.adjustmentOptions.errorMetric, 'point-to-line')
                excludePointsWithoutNormals = true;
            else
                excludePointsWithoutNormals = false;
            end
            obj.adjustment.selectPoints(...
                ExcludePointsWithoutNormals=excludePointsWithoutNormals, ...
                MinLinearity=obj.adjustmentOptions.minLinearity, ...
                ExcludeClasses=-1);
            
            % First matching
            obj.adjustment.match('Mode', obj.adjustmentOptions.matchingMode);
            
        end
        
        function runAdjustment(obj)
            
            logging('Run adjustment');
            
            for idxIt = 1:obj.adjustmentOptions.noIterations
                
                logging(sprintf('Iteration %d', idxIt));
                
                obj.adjustment.match('Mode', obj.adjustmentOptions.matchingMode);
                
                tic;
                [~, obj.vCorr, ~] = obj.adjustment.adjustment(...
                    WeightZeroObsF=obj.adjustmentOptions.weightZeroObsF, ...
                    WeightZeroObsFx=obj.adjustmentOptions.weightZeroObsFxFy, ...
                    WeightZeroObsFy=obj.adjustmentOptions.weightZeroObsFxFy, ...
                    WeightZeroObsFxy=obj.adjustmentOptions.weightZeroObsFxy, ...
                    ErrorMetric=obj.adjustmentOptions.errorMetric, ...
                    OptionalConstraints=obj.adjustmentOptions.optionalConstraints);
                toc;
                
            end
            
        end
        
        function plotMainMap(obj)
            
            logging('Plot main map');
            
            % Set main map to current axes
            set(0, 'CurrentFigure', obj.ui.figures.mainMap);
            
            obj.adjustment.plot(...
                PlotPcMovOriginal=obj.plotOptions.plotOriginalPointCloud, ...
                PlotTranslationGrid=obj.plotOptions.plotTranslationGrid, ...
                PlotCorrespondences=obj.plotOptions.plotCorrespondences, ...
                PlotTranslationVectors=obj.plotOptions.plotTranslationVectors, ...
                PlotTranslationGridContours=obj.plotOptions.plotTranslationGridContours, ...
                dLevels=obj.plotOptions.dLevels, ...
                ShowText=obj.plotOptions.showText, ...
                Title='');
            
        end
        
        function surfPlotTranslationGrids(obj, options)
            
            arguments
                obj
                options.CreateFigure = true;
            end
            
            if options.CreateFigure
                
                obj.ui.figures.surfPlotTranslationGrids = figure;
                obj.setFigureProperties(obj.ui.figures.surfPlotTranslationGrids);
                
                obj.ui.figures.surfPlotTranslationGrids.Name = ...
                    '2D_nonrigid_bicubic_pointcloud_registration surf plot';
                obj.ui.figures.surfPlotTranslationGrids.Position = [750 200 1400 700];
                
            end
            
            if isvalid(obj.ui.figures.surfPlotTranslationGrids)
                
                logging('Surf plot of translation grids');
                
                set(0, 'CurrentFigure', obj.ui.figures.surfPlotTranslationGrids);
                
                hAxes1 = subplot(1,2,1);
                plotGrid(hAxes1, obj.adjustment.pcMov.xTranslationGrid);
                title(hAxes1, 'scalar field tx');
                hAxes2 = subplot(1,2,2);
                plotGrid(hAxes2, obj.adjustment.pcMov.yTranslationGrid);
                title(hAxes2, 'scalar field ty');
                
                link = linkprop([hAxes1 hAxes2], {'CameraPosition' 'CameraUpVector'});
                setappdata(gcf, 'StoreTheLink', link);
                
            end
            
            function plotGrid(hAxes, grid)
                
                grid.surf('EdgeColor', 'none'); hold on;
                % grid.plot;
                rotate3d('on');
                hAxes.DataAspectRatioMode = 'manual';
                hAxes.DataAspectRatio = [1 1 1/50];
                % xlim(hAxes, grid.xLim);
                xlim(hAxes, (grid.xLim - mean(grid.xLim))*1.01+mean(grid.xLim));
                % ylim(hAxes, grid.yLim);
                ylim(hAxes, (grid.yLim - mean(grid.yLim))*1.01+mean(grid.yLim));
                xlabel('x');
                ylabel('y');
                zlabel('translation [m]');
                
            end
            
        end
        
        function plotHistogramOfResiduals(obj)
            
            logging('Plot histogram of residuals');
            
            if ~isempty(obj.vCorr)
                
                % Create figure
                fig = figure;
                fig.Color = 'k';
                fig.NumberTitle = 'off';
                fig.Name = '2D_nonrigid_bicubic_pointcloud_registration histogram of residuals';
                fig.MenuBar = 'none';
                fig.ToolBar = 'none';
                
                % Plot histogram
                histogram(obj.vCorr, 50, 'Normalization', 'pdf');
                
                % Add normal distribution
                hold('on');
                x = linspace(min(obj.vCorr), max(obj.vCorr), 1000);
                y = normpdf(x, mean(obj.vCorr), std(obj.vCorr));
                plot(x, y, 'r', 'LineWidth', 2);
                
                grid('on');
                setDarkMode;
                
            else
                
                warning('No residuals available');
                
            end
            
        end
        
        function close(obj)
            
            delete(obj.ui.figures.main);
            delete(obj.ui.figures.mainMap);
            
        end
        
        function pathToPointClouds = get.pathToPointClouds(obj)
            
            pathToPointClouds.pcFix = fullfile(obj.arguments.options.pathToDatasets, ...
                obj.ui.datasets.listbox.Value, 'pcFix.csv');
            pathToPointClouds.pcMov = fullfile(obj.arguments.options.pathToDatasets, ...
                obj.ui.datasets.listbox.Value, 'pcMov.csv');
            
            mustBeFile(pathToPointClouds.pcFix);
            mustBeFile(pathToPointClouds.pcMov);
            
        end
        
        function pathToInitialParams = get.pathToInitialParams(obj)
            
            pathToInitialParams = fullfile(obj.arguments.options.pathToDatasets, ...
                obj.ui.datasets.listbox.Value, 'initialParams.json');
            
            if ~exist(pathToInitialParams, 'file')
                pathToInitialParams = '';
            end
            
        end
        
        function adjustmentOptions = get.adjustmentOptions(obj)
            
            adjustmentOptions.cellSize = ...
                obj.ui.adjustmentOptions.editFieldCellSize.Value;
            adjustmentOptions.buffer = ...
                obj.ui.adjustmentOptions.editFieldBuffer.Value;
            adjustmentOptions.weightZeroObsF = ...
                obj.ui.adjustmentOptions.editFieldWeightZeroObsF.Value;
            adjustmentOptions.weightZeroObsFxFy = ...
                obj.ui.adjustmentOptions.editFieldWeightZeroObsFxFy.Value;
            adjustmentOptions.weightZeroObsFxy = ...
                obj.ui.adjustmentOptions.editFieldWeightZeroObsFxy.Value;
            adjustmentOptions.optionalConstraints = ...
                obj.ui.adjustmentOptions.dropdownOptionalConstraints.Value;
            adjustmentOptions.matchingMode = ...
                obj.ui.adjustmentOptions.dropdownMatchingMode.Value;
            adjustmentOptions.errorMetric = ...
                obj.ui.adjustmentOptions.dropdownErrorMetric.Value;
            adjustmentOptions.minLinearity = ...
                obj.ui.adjustmentOptions.editFieldMinLinearity.Value;
            adjustmentOptions.noIterations = ...
                obj.ui.adjustmentOptions.editFieldNoIterations.Value;
        end
        
        function plotOptions = get.plotOptions(obj)
            
            plotOptions.plotOriginalPointCloud = ...
                obj.ui.plotOptions.checkboxPlotOriginalPointCloud.Value;
            plotOptions.plotCorrespondences = ...
                obj.ui.plotOptions.checkboxPlotCorrespondences.Value;
            plotOptions.plotTranslationGrid = ...
                obj.ui.plotOptions.checkboxPlotTranslationGrid.Value;
            plotOptions.plotTranslationVectors = ...
                obj.ui.plotOptions.checkboxPlotTranslationVectors.Value;
            plotOptions.plotTranslationGridContours = ...
                obj.ui.plotOptions.dropdownTranslationGridContours.Value;
            plotOptions.dLevels = ...
                obj.ui.plotOptions.editFielddLevels.Value;
            plotOptions.showText = ...
                obj.ui.plotOptions.checkboxShowText.Value;
            
        end
        
    end
    
    methods (Static)
        
        function setFigureProperties(hFig)
            
            hFig.DockControls = 'off';
            hFig.ToolBar = 'none';
            hFig.MenuBar = 'none';
            hFig.NumberTitle = 'off';
            hFig.Color = 'k';
            
        end
        
    end
end