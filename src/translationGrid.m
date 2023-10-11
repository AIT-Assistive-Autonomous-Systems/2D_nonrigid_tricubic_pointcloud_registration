classdef translationGrid

    properties

        F
        Fx
        Fy
        Fxy

        gridOrigin
        cellSize

        % +-----+-----+-----+-----+
        % |     |     |     |     |
        % |5,1  |5,2  |5,3  |5,4  |
        % +-----+-----+-----+-----+
        % |     |     |     |     |
        % |4,1  |4,2  |4,3  |4,4  |
        % +-----+-----+-----+-----+
        % |     |     |     |     |
        % |3,1  |3,2  |3,3  |3,4  |
        % +-----+-----+-----+-----+
        % |     |     |     |     |
        % |2,1  |2,2  |2,3  |2,4  |
        % +-----+-----+-----+-----+
        % |     |     |     |     |
        % |1,1  |1,2  |1,3  |1,4  |
        % o-----+-----+-----+-----+
        %
        % o   ... obj.gridOrigin (= lower left corner of grid)
        % x,x ... indices of matrices, e.g. obj.F

    end

    properties (Dependent)

        noCols
        noRows

        X
        Y

        % Extents of grid boundaries
        xLim
        yLim

    end

    methods

        function obj = translationGrid(gridOrigin, noRows, noCols, cellSize)

            obj.F = zeros(noRows, noCols);
            obj.Fx = zeros(noRows, noCols);
            obj.Fy = zeros(noRows, noCols);
            obj.Fxy = zeros(noRows, noCols);

            obj.gridOrigin = gridOrigin;
            obj.cellSize = cellSize;

        end

        function [rowRef, colRef, dxn, dyn] = getGridReference(obj, x, y)

            % Todo Error if outside of xLim/yLim

            arguments
                obj
                x (:,1)
                y (:,1)
            end

            % +----------+
            % |   (x/y)  |
            % |   +      |
            % |          |
            % |          |
            % +----------+
            % reference point is lower left corner

            xGrid = x-obj.gridOrigin(1);
            yGrid = y-obj.gridOrigin(2);

            rowRef = ceil(yGrid/obj.cellSize);
            colRef = ceil(xGrid/obj.cellSize);

            % Special handling for points exactly on lower/left boundary of grid
            rowRef(y == obj.yLim(1)) = 1;
            colRef(x == obj.xLim(1)) = 1;

            % Cell coordinates
            dx = xGrid - (colRef-1)*obj.cellSize;
            dy = yGrid - (rowRef-1)*obj.cellSize;

            % Normalized cell coordinates, i.e. from 0 to 1
            dxn = dx/obj.cellSize;
            dyn = dy/obj.cellSize;

        end

        function plot(obj, options)

            arguments
                obj
                options.Color = 'r';
                options.MarkerSize = 10;
            end

            plot3(obj.X(:), obj.Y(:), obj.F(:), '.', Color=options.Color, ...
                MarkerSize=options.MarkerSize);

        end

        function contour(obj, options)

            arguments
                obj
                options.dLevels = 0.2;
                options.ShowText = false;
                options.DarkMode = true;
            end

            if ~(all(obj.F(:) == 0) && all(obj.Fx(:) == 0) && ...
                    all(obj.Fy(:) == 0) && all(obj.Fxy(:) == 0))

                dxy = obj.cellSize/10;

                xQuery = obj.xLim(1):dxy:obj.xLim(2);
                yQuery = obj.yLim(1):dxy:obj.yLim(2);
                [XQuery, YQuery] = meshgrid(xQuery, yQuery);

                [rowRef, colRef, dxn, dyn] = obj.getGridReference(XQuery(:), YQuery(:));

                f = obj.getValuesOfCellCorners(obj.F, rowRef, colRef);
                fx = obj.getValuesOfCellCorners(obj.Fx, rowRef, colRef);
                fy = obj.getValuesOfCellCorners(obj.Fy, rowRef, colRef);
                fxy = obj.getValuesOfCellCorners(obj.Fxy, rowRef, colRef);

                ZQuery = obj.getValue(f, fx, fy, fxy, dxn, dyn);

                ZQuery = reshape(ZQuery, numel(yQuery), numel(xQuery));

                s = pcolor(XQuery, YQuery, ZQuery);
                s.FaceColor = 'interp';
                s.EdgeColor = 'none';
                hold on;

                maxAbsLevel = 100;
                levelList = sort([0:options.dLevels:maxAbsLevel ...
                    -options.dLevels:-options.dLevels:-maxAbsLevel]);

                levelList(levelList==0) = []; % remove level = 0

                [M, c] = contour(XQuery, YQuery, ZQuery, levelList, 'Color', 0.8*ones(1,3));
                if options.ShowText
                    c.Color='w';
                    clabel(M, c, Color='w', FontSize=8);
                end
                colorbar(Color='w');
                colormap(translationpal);
                currentMaxAbsCAxis = max(abs(caxis));
                caxis(currentMaxAbsCAxis*[-1 1]);

            end

            axis equal;

            if options.DarkMode
                setDarkMode(gca);
            end

        end

        function ZQuery = surf(obj, options)

            arguments
                obj
                options.DarkMode = true;
                options.EdgeColor = [0 0 0];
            end

            % Todo Make subdivision number (here: 10) a parameter
            dxy = obj.cellSize/10;
            xQuery = obj.xLim(1):dxy:obj.xLim(2);
            yQuery = obj.yLim(1):dxy:obj.yLim(2);
            [XQuery, YQuery] = meshgrid(xQuery, yQuery);

            [rowRef, colRef, dxn, dyn] = obj.getGridReference(XQuery(:), YQuery(:));

            f = obj.getValuesOfCellCorners(obj.F, rowRef, colRef);
            fx = obj.getValuesOfCellCorners(obj.Fx, rowRef, colRef);
            fy = obj.getValuesOfCellCorners(obj.Fy, rowRef, colRef);
            fxy = obj.getValuesOfCellCorners(obj.Fxy, rowRef, colRef);

            ZQuery = obj.getValue(f, fx, fy, fxy, dxn, dyn);

            ZQuery = reshape(ZQuery, numel(yQuery), numel(xQuery));

            s = surf(XQuery, YQuery, ZQuery);
            s.EdgeColor = options.EdgeColor;

            colormap(translationpal);
            currentMaxAbsCAxis = max(abs(caxis));
            caxis(currentMaxAbsCAxis*[-1 1]);

            % axis equal;
            % Set axis equal only in x y plane
            daspect([max(daspect)*[1 1] 1]) % https://groups.google.com/g/comp.soft-sys.matlab/c/Ue7yqDdkd0M
            rotate3d;
            view(2);
            colorbar;
            if options.DarkMode
                setDarkMode(gca);
            end

        end

        function plotGrid(obj, options)

            arguments
                obj
                options.GridColor = [0.494 0.184 0.556];
                options.BackgroundColor = 'k';
                options.GridZVal = 10;
                options.LineWidth = 0.5;
            end

            hold on;

            % Plot vertical lines
            xLines = obj.gridOrigin(1) + (0:obj.noCols-1) .* obj.cellSize;
            yLinesMin = repmat(obj.yLim(1), 1, obj.noCols);
            yLinesMax = repmat(obj.yLim(2), 1, obj.noCols);
            zLines = repmat(options.GridZVal, 1, obj.noCols);
            plot3([xLines; xLines], [yLinesMin; yLinesMax], [zLines; zLines], '-', ...
                Color=options.GridColor, LineWidth=options.LineWidth);

            % Plot horizontal lines
            xLinesMin = repmat(obj.xLim(1), 1, obj.noRows);
            xLinesMax = repmat(obj.xLim(2), 1, obj.noRows);
            yLines = obj.gridOrigin(2) + (0:obj.noRows-1) .* obj.cellSize;
            zLines = repmat(options.GridZVal, 1, obj.noRows);
            plot3([xLinesMin; xLinesMax], [yLines; yLines], [zLines; zLines], '-', ...
                Color=options.GridColor, LineWidth=options.LineWidth);

            % Plot rectangle as background
            rectangle('Position', ...
            [obj.xLim(1) ...
            obj.yLim(1) ...
            obj.xLim(2) - obj.xLim(1) ...
            obj.yLim(2) - obj.yLim(1)], ...
            'FaceColor', options.BackgroundColor);

        end

        function noRows = get.noRows(obj)

            noRows = size(obj.F,1);

        end

        function noCols = get.noCols(obj)

            noCols = size(obj.F,2);

        end

        function X = get.X(obj)

            x = obj.gridOrigin(1):obj.cellSize:obj.gridOrigin(1)+obj.cellSize*(obj.noCols-1);
            X = repmat(x,obj.noRows,1);

        end

        function Y = get.Y(obj)

            y = transpose(obj.gridOrigin(2):obj.cellSize:obj.gridOrigin(2)+obj.cellSize*(obj.noRows-1));
            Y = repmat(y,1,obj.noCols);

        end

        function xLim = get.xLim(obj)

            xLim = [obj.gridOrigin(1) obj.gridOrigin(1)+(obj.noCols-1)*obj.cellSize];

        end

        function yLim = get.yLim(obj)

            yLim = [obj.gridOrigin(2) obj.gridOrigin(2)+(obj.noRows-1)*obj.cellSize];

        end

    end

    methods (Static)

        function f = getValue(f, fx, fy, fxy, dxn, dyn)

            arguments
                f (4,1,:)
                fx (4,1,:)
                fy (4,1,:)
                fxy (4,1,:)
                dxn (1,1,:)
                dyn (1,1,:)
            end

            noPoints = size(f,3);

            invA = [ 1     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
                     0     0     0     0     1     0     0     0     0     0     0     0     0     0     0     0
                    -3     3     0     0    -2    -1     0     0     0     0     0     0     0     0     0     0
                     2    -2     0     0     1     1     0     0     0     0     0     0     0     0     0     0
                     0     0     0     0     0     0     0     0     1     0     0     0     0     0     0     0
                     0     0     0     0     0     0     0     0     0     0     0     0     1     0     0     0
                     0     0     0     0     0     0     0     0    -3     3     0     0    -2    -1     0     0
                     0     0     0     0     0     0     0     0     2    -2     0     0     1     1     0     0
                    -3     0     3     0     0     0     0     0    -2     0    -1     0     0     0     0     0
                     0     0     0     0    -3     0     3     0     0     0     0     0    -2     0    -1     0
                     9    -9    -9     9     6     3    -6    -3     6    -6     3    -3     4     2     2     1
                    -6     6     6    -6    -3    -3     3     3    -4     4    -2     2    -2    -2    -1    -1
                     2     0    -2     0     0     0     0     0     1     0     1     0     0     0     0     0
                     0     0     0     0     2     0    -2     0     0     0     0     0     1     0     1     0
                    -6     6     6    -6    -4    -2     4     2    -3     3    -3     3    -2    -1    -2    -1
                     4    -4    -4     4     2     2    -2    -2     2    -2     2    -2     1     1     1     1];

             x = [f
                  fx
                  fy
                  fxy];

             if isa(x, 'double')
                 c = pagemtimes(invA, x);
             elseif isa(x, 'optim.problemdef.OptimizationExpression')
                 x = reshape(x, 16, noPoints);
                 c = invA*x;
                 c = reshape(c, 16, 1, noPoints);

                 % Slow alternative
                 % c = optimexpr(16,1,noPoints);
                 % for i = 1:noPoints
                 %     c(:,:,i) = invA*x(:,:,i);
                 % end
             end

             f1 = [ones(1,1,noPoints) dxn dxn.^2 dxn.^3];
             f2 = [c(1,1,:) c(5,1,:) c(9,1,:)  c(13,1,:)
                   c(2,1,:) c(6,1,:) c(10,1,:) c(14,1,:)
                   c(3,1,:) c(7,1,:) c(11,1,:) c(15,1,:)
                   c(4,1,:) c(8,1,:) c(12,1,:) c(16,1,:)];
             f3 = [ones(1,1,noPoints)
                   dyn
                   dyn.^2
                   dyn.^3];
             if isa(x, 'double')
                 f = pagemtimes(pagemtimes(f1, f2), f3);
                 f = permute(f, [3 2 1]);
             elseif isa(x, 'optim.problemdef.OptimizationExpression')
                 f12 = [ones(1,1,noPoints).*c(1,1,:) + ...
                        dxn.*c(2,1,:) + ...
                        dxn.^2.*c(3,1,:) + ...
                        dxn.^3.*c(4,1,:) ...
                        ones(1,1,noPoints).*c(5,1,:) + ...
                        dxn.*c(6,1,:) + ...
                        dxn.^2.*c(7,1,:) + ...
                        dxn.^3.*c(8,1,:) ...
                        ones(1,1,noPoints).*c(9,1,:) + ...
                        dxn.*c(10,1,:) + ...
                        dxn.^2.*c(11,1,:) + ...
                        dxn.^3.*c(12,1,:) ...
                        ones(1,1,noPoints).*c(13,1,:) + ...
                        dxn.*c(14,1,:) + ...
                        dxn.^2.*c(15,1,:) + ...
                        dxn.^3.*c(16,1,:)];

                 f = f12(1,1,:).*f3(1,1,:) + ...
                     f12(1,2,:).*f3(2,1,:) + ...
                     f12(1,3,:).*f3(3,1,:) + ...
                     f12(1,4,:).*f3(4,1,:);

                 f = reshape(f, noPoints, 1, 1);

                 % Slow alternative
                 % f = optimexpr(1,1,noPoints);
                 % for i = 1:noPoints
                 %     f(:,:,i) = f1(:,:,i)*f2(:,:,i)*f3(:,:,i);
                 % end
                 % f = reshape(f, noPoints, 1, 1);
             end

        end

        function a = getValuesOfCellCorners(A, rowRef, colRef)

            arguments
                A % matrix
                rowRef (:,1)
                colRef (:,1)
            end

            % a is tensor of size 4-by-1-by-n, where n = numel(rowRef)
            % Order of rows is:
            % row 1: lower left
            % row 2: lower right
            % row 3: upper left
            % row 4: upper right

            a = A(sub2ind(size(A), ...
                 [rowRef rowRef rowRef+1 rowRef+1], ...
                 [colRef colRef+1 colRef colRef+1]));

            if isa(a, 'double')
                a = permute(a, [2 3 1]);
            elseif isa(a, 'optim.problemdef.OptimizationExpression')
                a = reshape(a', 4, 1, size(a,1));
            end

        end

    end

end

