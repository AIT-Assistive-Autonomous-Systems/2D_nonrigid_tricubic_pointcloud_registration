classdef correspondences

    properties (SetAccess=private, GetAccess=public)

        pcFix
        pcMov

        pcFixIdx
        pcMovIdx

    end

    properties (Dependent)

        noCorr

    end

    methods

        function obj = correspondences(pcFix, pcMov, pcFixIdx, pcMovIdx)

            assert(numel(pcFixIdx) == numel(pcMovIdx));

            obj.pcFix = pcFix;
            obj.pcMov = pcMov;

            obj.pcFixIdx = pcFixIdx;
            obj.pcMovIdx = pcMovIdx;

        end

        function obj = addCorrespondence(obj, pcFixIdx, pcMovIdx)

            obj.pcFixIdx = [obj.pcFixIdx; pcFixIdx];
            obj.pcMovIdx = [obj.pcMovIdx; pcMovIdx];

        end

        function plot(obj, options)

            arguments
                obj
                options.Color = [0.466 0.674 0.188];
            end

            xFix = obj.pcFix.x(obj.pcFixIdx);
            yFix = obj.pcFix.y(obj.pcFixIdx);
            xMov = obj.pcMov.xT(obj.pcMovIdx);
            yMov = obj.pcMov.yT(obj.pcMovIdx);

            plot([xFix'; xMov'], [yFix'; yMov'], '-', Color=options.Color);

        end

        function noCorr = get.noCorr(obj)

            noCorr = numel(obj.pcFixIdx);

        end

    end

end