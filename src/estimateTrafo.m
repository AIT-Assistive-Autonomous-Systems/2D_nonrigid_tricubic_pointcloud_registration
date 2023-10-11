classdef estimateTrafo < handle
    
    properties (SetAccess=private, GetAccess=public)
        
        pcFix
        pcMov
        
        corr
        noCorr % grid with no of correspondences around each cell corner
        
    end
    
    methods
        
        function obj = estimateTrafo(pcFix, pcMov)
            
            arguments
                pcFix {mustBeA(pcFix, 'ptCloud')}
                pcMov {mustBeA(pcMov, 'ptCloud')}
            end
            
            obj.pcFix = pcFix;
            obj.pcMov = pcMov;
            
        end
        
        function selectPoints(obj, options)
            
            arguments
                obj
                options.ExcludePointsWithoutNormals (1,1) logical = true;
                options.MinLinearity (1,1) double = 0.97; % set to -1 to skip this filter
                options.ExcludeClasses (1,:) double = [];
            end
            
            % Select points with normals
            if options.ExcludePointsWithoutNormals
                obj.pcFix.act(isnan(obj.pcFix.A.nx)) = false;
                obj.pcMov.act(isnan(obj.pcMov.A.nx)) = false;
            end
            
            % Linearity
            if options.MinLinearity ~= -1
                obj.pcFix.act(obj.pcFix.A.linearity < options.MinLinearity) = false;
                obj.pcMov.act(obj.pcMov.A.linearity < options.MinLinearity) = false;
            end
            
            % Exclude classes
            if ~isempty(options.ExcludeClasses)
                for i = 1:numel(options.ExcludeClasses)
                    obj.pcFix.act(obj.pcFix.A.class == options.ExcludeClasses(i)) = false;
                    obj.pcMov.act(obj.pcMov.A.class == options.ExcludeClasses(i)) = false;
                end
            end
            
        end
        
        function match(obj, options)
            
            arguments
                obj
                options.Mode {mustBeMember(options.Mode, ['NearestNeighbor', 'ById'])} = 'NearestNeighbor';
            end
            
            pcFixQueryPointsIdx = find(obj.pcFix.act);
            pcMovActivePointsIdx = find(obj.pcMov.act);
            
            switch options.Mode
                
                case 'NearestNeighbor'
                    
                    pcFixQueryPointsX = [obj.pcFix.x(obj.pcFix.act) obj.pcFix.y(obj.pcFix.act)];
                    pcMovActivePointsX = [obj.pcMov.xT(obj.pcMov.act) obj.pcMov.yT(obj.pcMov.act)];
                    
                    % Find the nearest neighbor in pcMovActivePointsX for each point in pcFixQueryPointsX
                    idxNN = knnsearch(pcMovActivePointsX, pcFixQueryPointsX);
                    
                    pcMovCorrespondingPointsIdx = pcMovActivePointsIdx(idxNN);
                    
                case 'ById'
                    
                    assert(isfield(obj.pcFix.A, 'corrId'))
                    assert(isfield(obj.pcMov.A, 'corrId'))
                    
                    pcFixQueryCorrId = obj.pcFix.A.corrId(obj.pcFix.act);
                    pcMovActiveCorrId = obj.pcMov.A.corrId(obj.pcMov.act);
                    
                    % Remove all points with invalid corrId, i.e. < 0
                    pcFixInvalidCorrId = pcFixQueryCorrId < 0;
                    pcMovInvalidCorrId = pcMovActiveCorrId < 0;
                    pcFixQueryPointsIdx(pcFixInvalidCorrId) = [];
                    pcMovActivePointsIdx(pcMovInvalidCorrId) = [];
                    pcFixQueryCorrId(pcFixInvalidCorrId) = [];
                    pcMovActiveCorrId(pcMovInvalidCorrId) = [];
                    
                    [~, pcFixIntersectIdx, pcMovIntersectIdx] = ...
                        intersect(pcFixQueryCorrId, pcMovActiveCorrId);
                    
                    pcFixQueryPointsIdx = pcFixQueryPointsIdx(pcFixIntersectIdx);
                    pcMovCorrespondingPointsIdx = pcMovActivePointsIdx(pcMovIntersectIdx);
                    
            end
            
            obj.corr = correspondences(obj.pcFix, obj.pcMov, ...
                pcFixQueryPointsIdx, pcMovCorrespondingPointsIdx);
            
        end
        
        function [vTv, vCorr, C] = adjustment(obj, options)
            
            arguments
                obj
                options.WeightZeroObsF = 0.1;
                options.WeightZeroObsFx = 0.1;
                options.WeightZeroObsFy = 0.1;
                options.WeightZeroObsFxy = 0.1;
                options.ErrorMetric {mustBeMember(options.ErrorMetric, ...
                    {'point-to-line' ...
                    'point-to-point'})} = 'point-to-line';
                options.OptionalConstraints {mustBeMember(options.OptionalConstraints, ...
                    {'none'
                    'x translation grid only'
                    'y translation grid only'
                    'x translation grid is constant'
                    'y translation grid is constant'
                    'x and y translation grids are constant'
                    'rotation only'
                    'rigid body transformation'
                    'affine transformation'})} = 'none';
            end
            
            problem = optimproblem;
            
            xTranslationGridF = optimvar('xTranslationGridF', size(obj.pcMov.xTranslationGrid.F));
            xTranslationGridFx = optimvar('xTranslationGridFx', size(obj.pcMov.xTranslationGrid.Fx));
            xTranslationGridFy = optimvar('xTranslationGridFy', size(obj.pcMov.xTranslationGrid.Fy));
            xTranslationGridFxy = optimvar('xTranslationGridFxy', size(obj.pcMov.xTranslationGrid.Fxy));
            
            yTranslationGridF = optimvar('yTranslationGridF', size(obj.pcMov.yTranslationGrid.F));
            yTranslationGridFx = optimvar('yTranslationGridFx', size(obj.pcMov.yTranslationGrid.Fx));
            yTranslationGridFy = optimvar('yTranslationGridFy', size(obj.pcMov.yTranslationGrid.Fy));
            yTranslationGridFxy = optimvar('yTranslationGridFxy', size(obj.pcMov.yTranslationGrid.Fxy));
            
            x0.xTranslationGridF = obj.pcMov.xTranslationGrid.F;
            x0.xTranslationGridFx = obj.pcMov.xTranslationGrid.Fx;
            x0.xTranslationGridFy = obj.pcMov.xTranslationGrid.Fy;
            x0.xTranslationGridFxy = obj.pcMov.xTranslationGrid.Fxy;
            
            x0.yTranslationGridF = obj.pcMov.yTranslationGrid.F;
            x0.yTranslationGridFx = obj.pcMov.yTranslationGrid.Fx;
            x0.yTranslationGridFy = obj.pcMov.yTranslationGrid.Fy;
            x0.yTranslationGridFxy = obj.pcMov.yTranslationGrid.Fxy;
            
            [rowRef, colRef, dxn, dyn] = obj.pcMov.xTranslationGrid.getGridReference(...
                obj.corr.pcMov.x(obj.corr.pcMovIdx), obj.corr.pcMov.y(obj.corr.pcMovIdx));
            
            tx = getTranslation(xTranslationGridF, xTranslationGridFx, xTranslationGridFy, ...
                xTranslationGridFxy, rowRef, colRef, dxn, dyn);
            ty = getTranslation(yTranslationGridF, yTranslationGridFx, yTranslationGridFy, ...
                yTranslationGridFxy, rowRef, colRef, dxn, dyn);
            
            dX = [obj.corr.pcFix.x(obj.corr.pcFixIdx)    obj.corr.pcFix.y(obj.corr.pcFixIdx)] - ...
                [obj.corr.pcMov.x(obj.corr.pcMovIdx)+tx obj.corr.pcMov.y(obj.corr.pcMovIdx)+ty];
            
            switch options.ErrorMetric
                
                case 'point-to-line'
                    
                    vCorr = dot(dX, ...
                        [obj.corr.pcFix.A.nx(obj.corr.pcFixIdx) obj.corr.pcFix.A.ny(obj.corr.pcFixIdx)], 2);
                    
                case 'point-to-point'
                    
                    vCorr = dX(:);
                    
            end
            
            vF = [xTranslationGridF - zeros(size(xTranslationGridF))
                yTranslationGridF - zeros(size(yTranslationGridF))];
            
            vFx = [xTranslationGridFx - zeros(size(xTranslationGridFx))
                yTranslationGridFx - zeros(size(yTranslationGridFx))];
            
            vFy = [xTranslationGridFy - zeros(size(xTranslationGridFy))
                yTranslationGridFy - zeros(size(yTranslationGridFy))];
            
            vFxy = [xTranslationGridFxy - zeros(size(xTranslationGridFxy))
                yTranslationGridFxy - zeros(size(yTranslationGridFxy))];
            
            v = [vCorr
                vF(:)*options.WeightZeroObsF
                vFx(:)*options.WeightZeroObsFx
                vFy(:)*options.WeightZeroObsFy
                vFxy(:)*options.WeightZeroObsFxy];
            
            problem.Objective = sum(v.^2);
            
            switch options.OptionalConstraints
                
                case 'x translation grid only'
                    
                    problem.Constraints.constraint01 = yTranslationGridF(:) == 0;
                    problem.Constraints.constraint02 = yTranslationGridFx(:) == 0;
                    problem.Constraints.constraint03 = yTranslationGridFy(:) == 0;
                    problem.Constraints.constraint04 = yTranslationGridFxy(:) == 0;
                    
                case 'y translation grid only'
                    
                    problem.Constraints.constraint01 = xTranslationGridF(:) == 0;
                    problem.Constraints.constraint02 = xTranslationGridFx(:) == 0;
                    problem.Constraints.constraint03 = xTranslationGridFy(:) == 0;
                    problem.Constraints.constraint04 = xTranslationGridFxy(:) == 0;
                    
                case 'x translation grid is constant'
                    
                    problem.Constraints.constraint01 = xTranslationGridF(:) == xTranslationGridF(1,1);
                    problem.Constraints.constraint02 = xTranslationGridFx(:) == 0;
                    problem.Constraints.constraint03 = xTranslationGridFy(:) == 0;
                    problem.Constraints.constraint04 = xTranslationGridFxy(:) == 0;
                    
                case 'y translation grid is constant'
                    
                    problem.Constraints.constraint01 = yTranslationGridF(:) == yTranslationGridF(1,1);
                    problem.Constraints.constraint02 = yTranslationGridFx(:) == 0;
                    problem.Constraints.constraint03 = yTranslationGridFy(:) == 0;
                    problem.Constraints.constraint04 = yTranslationGridFxy(:) == 0;
                    
                case 'x and y translation grids are constant'
                    
                    problem.Constraints.constraint01 = xTranslationGridF(:) == xTranslationGridF(1,1);
                    problem.Constraints.constraint02 = xTranslationGridFx(:) == 0;
                    problem.Constraints.constraint03 = xTranslationGridFy(:) == 0;
                    problem.Constraints.constraint04 = xTranslationGridFxy(:) == 0;
                    
                    problem.Constraints.constraint05 = yTranslationGridF(:) == yTranslationGridF(1,1);
                    problem.Constraints.constraint06 = yTranslationGridFx(:) == 0;
                    problem.Constraints.constraint07 = yTranslationGridFy(:) == 0;
                    problem.Constraints.constraint08 = yTranslationGridFxy(:) == 0;
                    
                case 'rotation only'
                    
                    alpha = optimvar('alpha');
                    
                    x0.alpha = 0;
                    
                    R = [cos(alpha)  -sin(alpha)
                        sin(alpha)   cos(alpha)];
                    
                    problem.Constraints.constraint01 = xTranslationGridF == ...
                        R(1,1).*obj.pcMov.xTranslationGrid.X + ...
                        R(1,2).*obj.pcMov.xTranslationGrid.Y - ...
                        obj.pcMov.xTranslationGrid.X;
                    problem.Constraints.constraint02 = xTranslationGridFx == R(1,1) - 1;
                    problem.Constraints.constraint03 = xTranslationGridFy == R(1,2);
                    problem.Constraints.constraint04 = xTranslationGridFxy == 0;
                    
                    problem.Constraints.constraint05 = yTranslationGridF == ...
                        R(2,1).*obj.pcMov.yTranslationGrid.X + ...
                        R(2,2).*obj.pcMov.yTranslationGrid.Y - ...
                        obj.pcMov.yTranslationGrid.Y;
                    problem.Constraints.constraint06 = yTranslationGridFx == R(2,1);
                    problem.Constraints.constraint07 = yTranslationGridFy == R(2,2) - 1;
                    problem.Constraints.constraint08 = yTranslationGridFxy == 0;
                    
                case 'rigid body transformation'
                    
                    c = optimvar('c', 2, 1);
                    alpha = optimvar('alpha');
                    
                    x0.c = zeros(2,1);
                    x0.alpha = 0;
                    
                    R = [cos(alpha)  -sin(alpha)
                        sin(alpha)   cos(alpha)];
                    
                    problem.Constraints.constraint01 = xTranslationGridF == c(1) + ...
                        R(1,1).*obj.pcMov.xTranslationGrid.X + ...
                        R(1,2).*obj.pcMov.xTranslationGrid.Y - ...
                        obj.pcMov.xTranslationGrid.X;
                    problem.Constraints.constraint02 = xTranslationGridFx == R(1,1) - 1;
                    problem.Constraints.constraint03 = xTranslationGridFy == R(1,2);
                    problem.Constraints.constraint04 = xTranslationGridFxy == 0;
                    
                    problem.Constraints.constraint05 = yTranslationGridF == c(2) + ...
                        R(2,1).*obj.pcMov.yTranslationGrid.X + ...
                        R(2,2).*obj.pcMov.yTranslationGrid.Y - ...
                        obj.pcMov.yTranslationGrid.Y;
                    problem.Constraints.constraint06 = yTranslationGridFx == R(2,1);
                    problem.Constraints.constraint07 = yTranslationGridFy == R(2,2) - 1;
                    problem.Constraints.constraint08 = yTranslationGridFxy == 0;
                    
                case 'affine transformation'
                    
                    c = optimvar('c', 2, 1);
                    A = optimvar('A', 2, 2);
                    
                    x0.c = zeros(2,1);
                    x0.A = eye(2);
                    
                    problem.Constraints.constraint01 = xTranslationGridF == c(1) + ...
                        A(1,1).*obj.pcMov.xTranslationGrid.X + ...
                        A(1,2).*obj.pcMov.xTranslationGrid.Y - ...
                        obj.pcMov.xTranslationGrid.X;
                    problem.Constraints.constraint02 = xTranslationGridFx == A(1,1) - 1;
                    problem.Constraints.constraint03 = xTranslationGridFy == A(1,2);
                    problem.Constraints.constraint04 = xTranslationGridFxy == 0;
                    
                    problem.Constraints.constraint05 = yTranslationGridF == c(2) + ...
                        A(2,1).*obj.pcMov.yTranslationGrid.X + ...
                        A(2,2).*obj.pcMov.yTranslationGrid.Y - ...
                        obj.pcMov.yTranslationGrid.Y;
                    problem.Constraints.constraint06 = yTranslationGridFx == A(2,1);
                    problem.Constraints.constraint07 = yTranslationGridFy == A(2,2) - 1;
                    problem.Constraints.constraint08 = yTranslationGridFxy == 0;
                    
            end
            
            [solution, vTv] = solve(problem, x0);
            
            % Compute condition number
            problemStruct = prob2struct(problem); % problemStruct.C is the design matrix
            C = condest(problemStruct.C'*problemStruct.C);
            
            vCorr = evaluate(vCorr, solution);
            
            fprintf('%20s = %.3f\n', 'vTv', vTv);
            fprintf('%20s = %.3f\n', 'vCorrTvCorr', vCorr'*vCorr);
            fprintf('%20s = %.3f\n', 'mean(vCorr)', mean(vCorr));
            fprintf('%20s = %.3f\n', 'std(vCorr)', std(vCorr));
            fprintf('%20s = %.1e\n', 'condition', C);
            
            % Update grids
            obj.pcMov.xTranslationGrid.F = solution.xTranslationGridF;
            obj.pcMov.xTranslationGrid.Fx = solution.xTranslationGridFx;
            obj.pcMov.xTranslationGrid.Fy = solution.xTranslationGridFy;
            obj.pcMov.xTranslationGrid.Fxy = solution.xTranslationGridFxy;
            obj.pcMov.yTranslationGrid.F = solution.yTranslationGridF;
            obj.pcMov.yTranslationGrid.Fx = solution.yTranslationGridFx;
            obj.pcMov.yTranslationGrid.Fy = solution.yTranslationGridFy;
            obj.pcMov.yTranslationGrid.Fxy = solution.yTranslationGridFxy;
            
            function t = getTranslation(F, Fx, Fy, Fxy, rowRef, colRef, dxn, dyn)
                
                f = translationGrid.getValuesOfCellCorners(F, rowRef, colRef);
                fx = translationGrid.getValuesOfCellCorners(Fx, rowRef, colRef);
                fy = translationGrid.getValuesOfCellCorners(Fy, rowRef, colRef);
                fxy = translationGrid.getValuesOfCellCorners(Fxy, rowRef, colRef);
                
                t = translationGrid.getValue(f, fx, fy, fxy, dxn, dyn);
                
            end
            
        end
        
        function plot(obj, options)
            
            arguments
                obj
                options.Title = '';
                options.MarkerSize = 20;
                options.MarkerColorPcFix = [0 0.447 0.741]; % from get(0, 'DefaultAxesColorOrder')
                options.MarkerColorPcMov = [0.929 0.694 0.125]; % from get(0, 'DefaultAxesColorOrder')
                options.PlotPcMovOriginal = true;
                options.MarkerColorPcMovOriginal = 0.3*[0.929 0.694 0.125]; % from get(0, 'DefaultAxesColorOrder')
                options.PlotCorrespondences = false;
                options.PlotTranslationGrid = true;
                options.ColorTranslationGrid = [0.494 0.184 0.556];
                options.BackgroundColorTranslationGrid = 'k';
                options.PlotTranslationVectors = false;
                options.ColorTranslationVectors = 'w';
                options.TranslationVectorsdxy (1,1) double = 1;
                options.ClassTranslationVectors (1,1) double = -1;
                options.plotTranslationGridContours {mustBeMember(options.plotTranslationGridContours, ['none', 'x', 'y'])} = '';
                options.dLevels = 0.2; % passed to translationGrid.contour
                options.ShowText = false; % passed to translationGrid.contour
                options.DarkMode = true;
            end
            
            cla;
            
            switch options.plotTranslationGridContours
                case 'x'
                    plotTranslationGridContours(obj.pcMov.xTranslationGrid);
                case 'y'
                    plotTranslationGridContours(obj.pcMov.yTranslationGrid);
            end
            
            function plotTranslationGridContours(grid)
                grid.contour(dLevels=options.dLevels, ShowText=options.ShowText);
            end
            
            % Grid
            if options.PlotTranslationGrid
                obj.pcMov.xTranslationGrid.plotGrid(GridColor=options.ColorTranslationGrid, ...
                    BackgroundColor=options.BackgroundColorTranslationGrid);
            end
            
            % Point clouds
            obj.pcFix.plot(PlotTransformedCoordinates=false, Color=options.MarkerColorPcFix, ...
                MarkerSize=options.MarkerSize, DarkMode=options.DarkMode);
            hold on;
            if options.PlotPcMovOriginal
                obj.pcMov.plot(PlotTransformedCoordinates=false, ...
                    Color=options.MarkerColorPcMovOriginal, ...
                    MarkerSize=options.MarkerSize, DarkMode=options.DarkMode);
            end
            obj.pcMov.plot(PlotTransformedCoordinates=true, ...
                Color=options.MarkerColorPcMov, ...
                MarkerSize=options.MarkerSize, DarkMode=options.DarkMode);
            
            if options.PlotCorrespondences
                obj.corr.plot;
            end
            
            if options.PlotTranslationVectors
                xTranslationVectorsSource = obj.pcMov.x(...
                    obj.pcMov.A.class == options.ClassTranslationVectors);
                yTranslationVectorsSource = obj.pcMov.y(...
                    obj.pcMov.A.class == options.ClassTranslationVectors);
                xTranslationVectorsTarget = obj.pcMov.xT(...
                    obj.pcMov.A.class == options.ClassTranslationVectors);
                yTranslationVectorsTarget = obj.pcMov.yT(...
                    obj.pcMov.A.class == options.ClassTranslationVectors);
                quiver(xTranslationVectorsSource, yTranslationVectorsSource, ...
                    xTranslationVectorsTarget - xTranslationVectorsSource, ...
                    yTranslationVectorsTarget - yTranslationVectorsSource, ...
                    Color=options.ColorTranslationVectors);
            end
            
            axis equal;
            grid off;
            box on;
            xlabel('x');
            ylabel('y');
            if options.DarkMode
                setDarkMode(gca);
            end
            
            xlim(obj.pcMov.xTranslationGrid.xLim);
            ylim(obj.pcMov.xTranslationGrid.yLim);
            
            if ~isempty(options.Title)
                title(options.Title, Color='w');
            end
            
        end
        
        function noCorr = get.noCorr(obj)
            
            XQuery = [obj.pcMov.xTranslationGrid.X(:) obj.pcMov.xTranslationGrid.Y(:)];
            XSearch = [obj.corr.pcMov.x(obj.corr.pcMovIdx)  obj.corr.pcMov.y(obj.corr.pcMovIdx)];
            
            idx = rangesearch(XSearch, XQuery, obj.pcMov.xTranslationGrid.cellSize/2, ...
                'Distance', 'chebychev');
            
            noCorr = reshape(cellfun(@numel, idx), obj.pcMov.xTranslationGrid.noRows, ...
                obj.pcMov.xTranslationGrid.noCols);
            
        end
        
    end
    
end