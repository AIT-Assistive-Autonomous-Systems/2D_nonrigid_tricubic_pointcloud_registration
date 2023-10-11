classdef syntheticPtCloud < ptCloud

    methods

        function addRectangle(obj, xCenter, yCenter, width, height, sampling, class)

            xMin = xCenter - width/2;
            xMax = xCenter + width/2;
            yMin = yCenter - height/2;
            yMax = yCenter + height/2;

            xPts = transpose(xMin:sampling:xMax);
            yPts = transpose(yMin:sampling:yMax);

            xNew = [xPts
                    xMax*ones(numel(yPts),1)
                    fliplr(xPts)
                    xMin*ones(numel(yPts),1)];

            yNew = [yMax*ones(numel(xPts),1)
                    flipud(yPts)
                    yMin*ones(numel(xPts),1)
                    yPts];

            obj.addPoints(xNew, yNew, class);

        end
        
        function addLine(obj, xStart, yStart, xEnd, yEnd, sampling, class)

            length = norm([xEnd; yEnd] - [xStart; yStart]);
            dx = xEnd-xStart;
            dy = yEnd-yStart;
            alpha = atan2(dy, dx);

            % Line on x axis
            xNew = 0:sampling:length; % row vector
            yNew = zeros(1,numel(xNew)); % row vector
            XNew = [xNew; yNew];

            % Rotate
            R = [cos(alpha) -sin(alpha)
                 sin(alpha)  cos(alpha)];
            XNew = R * XNew;

            % Add shift
            XNew(1,:) = XNew(1,:) + xStart;
            XNew(2,:) = XNew(2,:) + yStart;

            obj.addPoints(XNew(1,:)', XNew(2,:)', class);
            
        end
        
        function addCircle(obj, xCenter, yCenter, radius, sampling, class)

            dAlpha = sampling/radius;

            alpha = transpose(0:dAlpha:2*pi);

            xNew = cos(alpha)*radius;
            yNew = sin(alpha)*radius;

            % Add shift
            xNew = xNew + xCenter;
            yNew = yNew + yCenter;

            obj.addPoints(xNew, yNew, class);
            
        end

        function addRaster(obj, xMin, xMax, yMin, yMax, sampling, class)

            x = xMin:sampling:xMax;
            y = yMin:sampling:yMax;

            [X, Y] = meshgrid(x, y);

            xNew = X(:);
            yNew = Y(:);

            obj.addPoints(xNew, yNew, class);

        end
        
        function transformByShift(obj, tx, ty)
            
            obj.x = obj.x + tx;
            obj.y = obj.y + ty;
            
        end
        
        function transformByRotation(obj, alpha, xRotationCenter, yRotationCenter)
            
            [obj.x, obj.y] = applyRotation(obj.x, obj.y, alpha, ...
                xRotationCenter, yRotationCenter);
            
            function [x, y] = applyRotation(x, y, alpha, xRotationCenter, yRotationCenter)
                
                R = [cos(alpha) -sin(alpha)
                     sin(alpha)  cos(alpha)];
                
                x = x-xRotationCenter;
                y = y-yRotationCenter;
                
                X = [x';y'];
                
                X = R*X;
                
                x = X(1,:)';
                y = X(2,:)';
                
                x = x+xRotationCenter;
                y = y+yRotationCenter;
                
            end
            
        end
        
        function [dx, dy] = transformBySinusFunction(obj, axis, period, amplitude)
            
            switch axis
                case 'x'
                    dx = sin(obj.y*2*pi/period)*amplitude;
                    dy = zeros(obj.noPoints,1);
                    obj.x = obj.x + dx;
                case 'y'
                    dx = zeros(obj.noPoints,1);
                    dy = sin(obj.x*2*pi/period)*amplitude;
                    obj.y = obj.y + dy;
            end
            
        end
        
    end
        
end

