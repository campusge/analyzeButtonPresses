function [gapOverlap, meanGapOverlap, stdGapOverlap, durA, durB, numSwitches] = summarizeData(TS, filename, plot_yn, startTime)

%keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Summarize gaps and overlaps %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Note that this summarizes LEFT and RIGHT mouse presses %%%%%%%%%
%%% It does not distinguish between GRATING 1 and 2, %%%%%%%%%%%%%%%
%%% as these gratings may change direction during the experiment.%%%
%%% GRATING 1 and 2 are compared in DERIVEVARS.m %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% timeSeries column 2 is a column of 1's and 0's for pressing left-button. Therefore, we
% can compare each cell to the previous cell to look for a switch between 0 
% and 1 (off and on).
switchA = (TS(1:end-1,2) + TS(2:end,2)); % cell == 1 is one frame before switch
indA = find(switchA == 1); % # of indices should be == # of gapOverlap
timesA = TS(indA+1); % time when button pressed/released; '+ 1' because ind is one frame before switch
if mod(length(timesA),2) == 1 % if button A(left) was still pressed in last frame, add timestamp of last frame to timesA (for Aoff)
    timesA(length(timesA)+1,1) =  max(TS(:,1));
end

switchB = (TS(1:end-1,3) + TS(2:end,3)); % cell == 1 is one frame before switch
indB = find(switchB == 1); % # of indices should be == # of gapOverlap
timesB = TS(indB+1); % time when button pressed/released; '+ 1' because ind is one frame before switch
if mod(length(timesB),2) == 1 % if button B was still pressed in last frame, add timestamp of last frame to timesA (for Boff)
    timesB(length(timesB)+1,1) =  max(TS(:,1));
end

% split into 2 columns depending on whether button is pressed or released
timesA_split(:,1) = timesA(1:2:end); % Aon
timesA_split(:,2) = timesA(2:2:end); % Aoff
timesB_split(:,1) = timesB(1:2:end); % Bon
timesB_split(:,2) = timesB(2:2:end); % Boff

% add 3rd column to label button press as A(left) (+1) vs B(right) (-1)
timesA_split = cat(2, timesA_split, ones( size(timesA_split,1), 1) ); 
timesB_split = cat(2, timesB_split, ones( size(timesB_split,1), 1)*-1 ); 

% Sort button press order by time 
timesCat = cat(1,timesA_split, timesB_split);
[~, d2] = sort(timesCat(:,1));
timesSort = timesCat(d2,:);
numSwitches = size(timesSort,1) - 1; % -1 because # of switches is one less than # of presses

if numSwitches > 0
    % measure gaps and overlaps
    for i = 1: numSwitches 
        gapOverlap(i,1) = timesSort(i+1,1) - timesSort(i,2); % next press minus previous button release
        gapOverlap(i,2) = timesSort(i+1,3) - timesSort(i,3); % gap between same button? if = +/-2 there is a button switch, if = 0 gap between same button

    end

    %disp('gapOverlap var: positive value = gap, negative value = overlap');
    meanGapOverlap = mean(gapOverlap(:,1));
    stdGapOverlap = std(gapOverlap(:,1));
else
    gapOverlap = [0,0];
    meanGapOverlap = 0;
    stdGapOverlap = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Summarize dominance durations %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

durA = timesA_split(:,2) - timesA_split(:,1);
durB = timesB_split(:,2) - timesB_split(:,1);

% account for possibility that button A(left) or B(right) were never pressed
if isempty(durA)
    durA = 0;
elseif isempty(durB)
    durB = 0;
end

%%%%%%%%%%%%%%%%%%%%%%
%%% Visualize data %%%
%%%%%%%%%%%%%%%%%%%%%%

if plot_yn==1
   
    %%% Plot of right and left button presses %%%
    Tmax = max(TS(:,1));
    
    % constants for plotting
    colorA=[1.0 0.0 0.0];  % to use in case plot_yn=1
    colorB=[0.0 1.0 0.0];
    YvalsA=[0.80 0.90 0 1];
    YvalsB=[0.75 0.85 0 1];
    
    h=figure();
    h1 = subplot(3,1,1);             % plot of 'raw' TC
    plotTC(h1,timesA_split(:,1:2),startTime, Tmax,YvalsA,colorA)
    hold on
    plotTC(h1,timesB_split(:,1:2),startTime, Tmax,YvalsB,colorB)
    
    str = sprintf('Filename is "%s" and # of presses = %d', strrep(filename, '_', ' '), size(timesCat,1)); %need to take out underscores or formats text as subscript in title
    title(str)
    
    %%% Histogram of dominance durations %%%
    
    binw = 5; % 5 secs % to spot outliers and keep interval constant
    
    [histA, histB, bins] = histogramPrep(durA, durB, binw);
    
    if plot_yn==1
        h2 = subplot(3,1,2);
        %figure
        shift=0.1*binw*ones(size(bins));
        bar(bins-shift,histA,0.1*binw,'EdgeColor',colorA,'FaceColor',colorA)
        hold on
        bar(bins+shift,histB,0.1*binw,'EdgeColor',colorB,'FaceColor',colorB)
        str = sprintf('Dominance durations for left and right button presses;\n Bin width %.2f s and bin shift +/- %.2f ', binw, shift(1));
        title(str)
    end
    
    %%% Histogram of gaps and overlaps
            
    tmpmin = min(gapOverlap(:,1));
    tmpmax = max(gapOverlap(:,1));

    if tmpmax == 0 || tmpmin == tmpmax % if no overlaps in event series, or if min == max, 
        tmpmax = 0.6; % set arbitrary value for tmax 
    end % this will be used as the max x-axis val in the hist

    binw2 = (abs(tmpmin)+tmpmax)/6;

    bins2 = tmpmin: binw2: tmpmax;
    if bins2(end) < tmpmax
        bins2(end + 1) = bins2(end) + binw2;
    end

    hist = histc(gapOverlap, bins2);
    h3 = subplot(3,1,3);
    %figure
    bar(bins2, hist, 'EdgeColor', colorA, 'FaceColor', colorA)
    str = sprintf('Gaps(+) and overlaps(-);\n Bin width %.2f s and and no bin shift\n Mean gap/overlap = %.3f s', binw2, meanGapOverlap);
    title(str)
        
end

%keyboard
