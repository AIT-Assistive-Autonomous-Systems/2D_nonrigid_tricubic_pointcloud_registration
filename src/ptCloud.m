classdef ptCloud < matlab.mixin.Copyable

    properties (SetAccess=public, GetAccess=public)
        
        % Points
        x
        y
        act = logical([]);
        A % attributes
        
        % Translation grids
        xTranslationGrid
        yTranslationGrid
        
    end
    
    properties (Dependent)
        
        % Points transformed by translation grids
        xT
        yT
        
        xLim
        yLim
        noPoints
        
    end
    
    methods

        function obj = ptCloud(options)
            
            arguments
                options.Filename = '';
            end
            
            if ~isempty(options.Filename)
                
                assert(exist(options.Filename, 'file'));
                T = readtable(options.Filename);
                
                assert(ismember('x', T.Properties.VariableNames));
                assert(ismember('y', T.Properties.VariableNames));
                
                obj.addPoints(T.x, T.y, 0); % 0 as default class
                
                for i = 1:numel(T.Properties.VariableNames)
                    switch T.Properties.VariableNames{i}
                        case {'x' 'y'} % skip
                        otherwise
                            obj.A.(T.Properties.VariableNames{i}) = T{:,i};
                    end
                end
                
                return;
            end
            
        end
        
        function addPoints(obj, xNew, yNew, class)
            
            assert(numel(xNew) == numel(yNew));
            
            noNewPoints = numel(xNew);
            
            obj.x = [obj.x; xNew];
            obj.y = [obj.y; yNew];
            obj.act = [obj.act; true(noNewPoints,1)];
            
            if isempty(obj.A)
                
                obj.A.class = class*ones(noNewPoints,1);
                
            else
                
                ACopy = obj.A;
                
                attributeNames = fieldnames(ACopy);

                for i = 1:numel(attributeNames)
                    
                    if strcmp(attributeNames{i}, 'class')
                        
                        ACopy.class = [ACopy.class; class*ones(noNewPoints,1)];
                        
                    else
                        
                        ACopy.(attributeNames{i}) = [ACopy.(attributeNames{i}); NaN(noNewPoints,1)];
                        
                    end
                    
                end
                
                obj.A = ACopy;
                
            end
            
        end
        
        function estimateNormals(obj, options)
           
            arguments
                obj
                options.searchRadius = 1;
                options.minNoNeighbours = 2;
                options.maxNoNeighbours = 32;
            end
            
            obj.A.nx = nan(obj.noPoints,1);
            obj.A.ny = nan(obj.noPoints,1);
            obj.A.roughness = nan(obj.noPoints,1);
            obj.A.linearity = nan(obj.noPoints,1);
            obj.A.ratio = nan(obj.noPoints,1);
            obj.A.sum = nan(obj.noPoints,1);

            X = [obj.x obj.y];
            
            idxNN = rangesearch(X, X, options.searchRadius);

            for i = 1:obj.noPoints

                if numel(idxNN{i}) >= options.minNoNeighbours+1 % NN includes also query point!

                    if numel(idxNN{i}) > options.maxNoNeighbours+1
                        idxNN{i} = idxNN{i}(1:options.maxNoNeighbours+1); % keep NN and query point
                    end

                    XNN = X(idxNN{i},:);
                    C = cov(XNN);

                    [P, lambda] = pcacov(C);
                    obj.A.nx(i) = P(1,2);
                    obj.A.ny(i) = P(2,2);
                    obj.A.roughness(i) = sqrt(lambda(2));
                    obj.A.linearity(i) = (lambda(1)-lambda(2))/lambda(1);
                    obj.A.ratio(i) = lambda(2)/lambda(1);
                    obj.A.sum(i) = sum(lambda);

                end

            end
            
        end
        
        function initializeTranslationGrids(obj, cellSize, options)
            
            arguments
                obj
                cellSize (1,1) double
                options.Buffer = 0;
            end
            
            % Todo Round origin to cellSize
            gridOrigin = [obj.xLim(1)-options.Buffer obj.yLim(1)-options.Buffer];
            
            noRows = ceil((obj.yLim(2)+options.Buffer-gridOrigin(2))/cellSize);
            noCols = ceil((obj.xLim(2)+options.Buffer-gridOrigin(1))/cellSize);
            
            obj.xTranslationGrid = translationGrid(gridOrigin, noRows, noCols, cellSize);
            obj.yTranslationGrid = translationGrid(gridOrigin, noRows, noCols, cellSize);
            
        end
        
        function addPointsForTranslationVectors(obj, options)
            
            arguments
                obj
                options.dxy = 1;
                options.Class = -1;
            end
            
            xNew = obj.xTranslationGrid.xLim(1):options.dxy:obj.xTranslationGrid.xLim(2);
            yNew = obj.xTranslationGrid.yLim(1):options.dxy:obj.xTranslationGrid.yLim(2);
            
            [XNew, YNew] = meshgrid(xNew, yNew);
            
            obj.addPoints(XNew(:), YNew(:), options.Class);
            
        end
        
        function plot(obj, options)
            
            arguments
                obj
                options.PlotTransformedCoordinates = false;
                options.Marker = '.';
                options.MarkerSize = 5;
                options.Color = 'w';
                options.DarkMode = true;
            end
               
            assert(sum(obj.act)>0);
            
            if options.PlotTransformedCoordinates
                xPlot = obj.xT(obj.act);
                yPlot = obj.yT(obj.act);
            else
                xPlot = obj.x(obj.act);
                yPlot = obj.y(obj.act);
            end
            
            if length(options.Color) > 1
                if strcmp(options.Color(1:2), 'A.') % plot attribute
                    attributeName = options.Color(3:end);
                    assert(isfield(obj.A, attributeName));
                    A = obj.A.(attributeName);
                    A = A(obj.act);
                    scatter(xPlot, yPlot, options.MarkerSize^2, A, '.');
                    colorbar('Color', 'w');
                    setAxesAndFigureProperties;
                    return;
                end
            end
            
            plot(xPlot, yPlot, options.Marker, 'MarkerSize', options.MarkerSize, ...
                'Color', options.Color);
            setAxesAndFigureProperties;
                
            function setAxesAndFigureProperties
                axis equal;
                set(gcf, 'Color', 'k');
                if options.DarkMode
                    setDarkMode(gca);
                end
            end
            
        end
        
        function plotNormals(obj, options)
            
            arguments
                obj
                options.Scale = 1;
                options.Color = 'm';
            end
            
            assert(isfield(obj.A, 'nx'));
            assert(isfield(obj.A, 'ny'));
            
            quiver(obj.x, obj.y, obj.A.nx, obj.A.ny, options.Scale, 'Color', options.Color, ...
                'AutoScale', 'off');
            
        end
        
        function export(obj, filename)
            
            X = table(obj.x, obj.y);
            X.Properties.VariableNames = {'x' 'y'};
            
            if isstruct(obj.A)
                A = struct2table(obj.A);
                T = [X A];
            else
                T = X;
            end
            
            writetable(T, filename);
            
        end
        
        function xT = get.xT(obj)
            
            [rowRef, colRef, dxn, dyn] = obj.xTranslationGrid.getGridReference(obj.x, obj.y);
            
            f = translationGrid.getValuesOfCellCorners(obj.xTranslationGrid.F, rowRef, colRef);
            fx = translationGrid.getValuesOfCellCorners(obj.xTranslationGrid.Fx, rowRef, colRef);
            fy = translationGrid.getValuesOfCellCorners(obj.xTranslationGrid.Fy, rowRef, colRef);
            fxy = translationGrid.getValuesOfCellCorners(obj.xTranslationGrid.Fxy, rowRef, colRef);
            
            tx = translationGrid.getValue(f, fx, fy, fxy, dxn, dyn);
            
            xT = obj.x + tx;
            
        end
        
        function yT = get.yT(obj)
            
            [rowRef, colRef, dxn, dyn] = obj.yTranslationGrid.getGridReference(obj.x, obj.y);
            
            f = translationGrid.getValuesOfCellCorners(obj.yTranslationGrid.F, rowRef, colRef);
            fx = translationGrid.getValuesOfCellCorners(obj.yTranslationGrid.Fx, rowRef, colRef);
            fy = translationGrid.getValuesOfCellCorners(obj.yTranslationGrid.Fy, rowRef, colRef);
            fxy = translationGrid.getValuesOfCellCorners(obj.yTranslationGrid.Fxy, rowRef, colRef);
            
            ty = translationGrid.getValue(f, fx, fy, fxy, dxn, dyn);
            
            yT = obj.y + ty;
            
        end
        
        function xLim = get.xLim(obj)
            
            xLim = [min(obj.x) max(obj.x)];
            
        end
        
        function yLim = get.yLim(obj)
            
            yLim = [min(obj.y) max(obj.y)];
            
        end
        
        function noPoints = get.noPoints(obj)

            assert(numel(obj.x) == numel(obj.y));
            
            noPoints = numel(obj.x);
            
        end
        
        function set.act(obj, act)
            
            assert(islogical(act));
            assert(size(act,1) == obj.noPoints);
            assert(size(act,2) == 1);
            
            obj.act = act;
            
        end
        
        function set.A(obj, A)
            
            assert(isstruct(A) | isempty(A));
            
            if ~isempty(A)

                attributeNames = fieldnames(A);

                for i = 1:numel(attributeNames)

                    assert(size(A.(attributeNames{i}),1) == obj.noPoints);
                    assert(size(A.(attributeNames{i}),2) == 1);
                    
                end

            end

            obj.A = A;

        end
        
    end
    
end

