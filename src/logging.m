function logging(msg)

    arguments
        msg {mustBeText}
    end
    
    stamp = [datestr(now,'yyyy-mm-dd HH:MM:SS.FFF') 's'];
    
    fprintf('[%s] %s\n', stamp, msg);
    
end