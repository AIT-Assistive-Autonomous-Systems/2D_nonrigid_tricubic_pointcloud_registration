classdef correspondenceDigitizerGUI < handle
    
    properties
        
        pc1Filename;
        pc2Filename;
        
        pc1;
        pc2;
        
        fig;
        ax;
        
        hCorr = [];
    end
    
    methods
        
        function obj = correspondenceDigitizerGUI(pc1Filename, pc2Filename)
            
            obj.pc1Filename = pc1Filename;
            obj.pc2Filename = pc2Filename;
            
            logging('Reading point clouds ...');
            obj.pc1 = ptCloud('Filename', pc1Filename);
            obj.pc2 = ptCloud('Filename', pc2Filename);
            
            if ~isfield(obj.pc1.A, 'corrId')
                logging('Initialize correspondence attribute for point cloud 1 ...');
                obj.pc1.A.corrId = -1*ones(obj.pc1.noPoints, 1);
            end
            if ~isfield(obj.pc2.A, 'corrId')
                logging('Initialize correspondence attribute for point cloud 2 ...');
                obj.pc2.A.corrId = -1*ones(obj.pc2.noPoints, 1);
            end
            
            logging('Create figure ...');
            obj.fig = uifigure;
            obj.fig.Name = "correspondenceDigitizer";
            obj.fig.Position = [100 100 1000 1000];
            gl = uigridlayout(obj.fig,[2 2]);
            gl.RowHeight = {'1x', 30};
            gl.ColumnWidth = {'1x', '1x'};
            obj.ax = uiaxes(gl);
            obj.ax.Layout.Row = 1;
            obj.ax.Layout.Column = [1 2];
            buttonNew = uibutton(gl, ...
                'Text', 'Add correspondence', ...
                'ButtonPushedFcn', @obj.buttonNewCorrespondenceCallback);
            buttonNew.Layout.Row = 2;
            buttonNew.Layout.Column = 1;
            buttonNew = uibutton(gl, ...
                'Text', 'Save point clouds', ...
                'ButtonPushedFcn', @obj.buttonSavePointCloudsCallback);
            buttonNew.Layout.Row = 2;
            buttonNew.Layout.Column = 2;
            
            logging('Plotting ...');
            plot(obj.ax, obj.pc1.x, obj.pc1.y, 'r.');
            hold(obj.ax, 'on');
            plot(obj.ax, obj.pc2.x, obj.pc2.y, 'b.');
            axis(obj.ax, 'equal');
            grid(obj.ax, 'on')
            obj.plotCorrespondences;
            
            logging('Ready!');
            
        end
        
        function plotCorrespondences(obj)
            
            % Reset
            if ~isempty(obj.hCorr)
                delete(obj.hCorr);
                obj.hCorr = [];
            end
            
            % Plot
            [commonCorrIds, pc1IntersectIdx, pc2IntersectIdx] = intersect(obj.pc1.A.corrId, obj.pc2.A.corrId);
            
            idxToDel = commonCorrIds < 0;
            pc1IntersectIdx(idxToDel) = [];
            pc2IntersectIdx(idxToDel) = [];
            
            obj.hCorr = plot(obj.ax, [obj.pc1.x(pc1IntersectIdx) obj.pc2.x(pc2IntersectIdx)]', ...
                [obj.pc1.y(pc1IntersectIdx) obj.pc2.y(pc2IntersectIdx)]', 'k-', 'LineWidth', 4, ...
                'ButtonDownFcn', @obj.correspondenceCallback);
        end
        
        function addCorrespondence(obj, pc1Idx, pc2Idx)
            
            maxCorrIdPc1 = max(obj.pc1.A.corrId);
            maxCorrIdPc2 = max(obj.pc2.A.corrId);
            assert(maxCorrIdPc1 == maxCorrIdPc2);
            
            newCorrId = maxCorrIdPc1 + 1;
            
            obj.pc1.A.corrId(pc1Idx) = newCorrId;
            obj.pc2.A.corrId(pc2Idx) = newCorrId;
            
        end
        
        function buttonNewCorrespondenceCallback(obj, src, event)
            
            title(obj.ax, 'First select red point, then blue point');
            g = gline(obj.fig);
            g.ButtonDownFcn = @obj.glineCallback;
            
        end
        
        function buttonSavePointCloudsCallback(obj, src, event)
            
            logging('Saving point clouds ...');
            obj.pc1.export(obj.pc1Filename);
            obj.pc2.export(obj.pc2Filename);
            
        end
        
        function glineCallback(obj, src, event)
            
            pc1IdxNew = knnsearch([obj.pc1.x, obj.pc1.y], [src.XData(1), src.YData(1)]);
            pc2IdxNew = knnsearch([obj.pc2.x, obj.pc2.y], [src.XData(2), src.YData(2)]);
            obj.addCorrespondence(pc1IdxNew, pc2IdxNew);
            obj.plotCorrespondences;
            
            delete(src);
            
            title(obj.ax, '');
            
        end
        
        function correspondenceCallback(obj, src, event)
            
            if event.Button == 2 % middle mouse button
                idxPc1 = find((src.XData(1) == obj.pc1.x) & (src.YData(1) == obj.pc1.y));
                idxPc2 = find((src.XData(2) == obj.pc2.x) & (src.YData(2) == obj.pc2.y));
                obj.pc1.A.corrId(idxPc1) = -1;
                obj.pc2.A.corrId(idxPc2) = -1;
                delete(src);
            end
            
        end
        
    end
    
end