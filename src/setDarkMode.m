function setDarkMode(hAxes)

    if nargin < 1
        hAxes = gca;
    end

    hAxes.Color = 'k';
    hAxes.GridColorMode = 'manual';
    hAxes.GridColor = 'w';
    hAxes.GridAlpha = 0.30;
    hAxes.Box = 'on';
    hAxes.XColorMode = 'manual';
    hAxes.XColor = 'w';
    hAxes.YColorMode = 'manual';
    hAxes.YColor = 'w';
    hAxes.ZColorMode = 'manual';
    hAxes.ZColor = 'w';
    
    % Title
    hAxes.Title.Color = 'w';

    % Legend
    if ~isempty(hAxes.Legend)
        hAxes.Legend.Color = 'k';
        hAxes.Legend.TextColor = 'w';
    end
    
    % Colorbar
    if ~isempty(hAxes.Colorbar)
        hAxes.Colorbar.Color = 'w';
    end

end