%% Script to analyze button press data
% Created by Erin, Feb 10, 2015
% Modified from NR analyzeTC.m function


%%%%%%%%%%%%%%%%%%%%%
%% Clear workspace %%
%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all



%%%%%%%%%%%%%%%
%% CONSTANTS %%
%%%%%%%%%%%%%%%

AnalysisType = 1; %if single file analysis = 1; if batch analysis = 2; if simulation = 3

FR = 120; % frame rate

plot_yn = 1; % if want to see summary plots (1 if yes, 0 if no)



%%%%%%%%%%%%%%
%% GET DATA %%
%%%%%%%%%%%%%%

if AnalysisType == 1
    %%%%%%%%%%%%%%%%%%%
    %%% Select data %%%
    %%%%%%%%%%%%%%%%%%%
    
    numFiles = 1;
    
    [filename, pathname] = uigetfile('C:\Users\Erin\Box Sync\UPF\PlaidProj\Data\raw\2013 ButtonPress dat files\*.dat', 'Pick a .dat data file');
    rawData = importdata(strcat(pathname, filename));
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Save raw data to mat file %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % See if data already saved to mat file %
    load('C:\Users\Erin\Box Sync\UPF\PlaidProj\Data\processed\keyPressData\keyData.mat');
    L = length(keyData.subjects);
    
    for i = 1 : L
        fileRepeat(i,1) =  strcmp(keyData.subjects(1,i).name, filename);
    end
    
    % Save raw data to mat file %
    if sum(fileRepeat) < 1
        keyData.subjects(1, L + 1).name = filename;
        keyData.subjects(1, L + 1).data = rawData;
        save('C:\Users\Erin\Box Sync\UPF\PlaidProj\Data\processed\keyPressData\keyData.mat','keyData');
    end
    
elseif AnalysisType == 2
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Get raw data mat file %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    load('C:\Users\Erin\Box Sync\UPF\PlaidProj\Data\processed\keyPressData\keyData.mat');
    
    numFiles = length(keyData.subjects);
    
elseif AnalysisType == 3
      
    %%%%%%%%%%%%%%%%%%%%%
    %%% Simulate data %%%
    %%%%%%%%%%%%%%%%%%%%%
    
    numFiles = 2;

    simData.tc(1,1).data = simTC_wJitter(3500,500,4800,800,600,150,20); % generate a simulated time course
    simData.tc(1,1).data(:,2) = simData.tc(1,1).data(:,2)/1000; % convert time course (col 2) to seconds
    simData.tc(1,1).name = 'Simulation 1'; 
    
    simData.tc(1,2).data = simTC_wJitter(3000,500,4000,1600,200,150,20);
    simData.tc(1,2).data(:,2) = simData.tc(1,2).data(:,2)/1000;
    simData.tc(1,2).name = 'Simulation 2';
end



%%%%%%%%%%%%%%%%%%%%
%% SUMMARIZE DATA %%
%%%%%%%%%%%%%%%%%%%%

for i = 1 : numFiles
    
    if AnalysisType == 1
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Do nothing %%%%%%%%%%%%%%%%%%%%%%%%
        %%% Data already selected and ready %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    elseif AnalysisType == 2      
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Select raw data from mat file %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        clear rawData; clear gapOverlap_pre; clear gapOverlap_post; % clear data from prev loop
        clear durA_pre; clear durA_post; clear durB_pre; clear durB_post; clear timeSeriesTC1;
        rawData = keyData.subjects(1,i).data;
        filename = keyData.subjects(i).name;
        
    elseif AnalysisType == 3
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Select simulated data from structure %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        clear rawData; clear gapOverlap_post % clear data from prev loop
        clear durA_post; clear durB_post; clear timeSeriesTC1;
        rawData = simData.tc(1,i).data;
        filename = simData.tc(1,i).name;
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Generate press time series %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    timeSeriesTC1 = genTimeSeries(rawData,FR); 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Summarize and visualize time series pre-clean-up %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Summarize gap and overlap data with plots %
    [gapOverlap_pre, meanGapOverlap_pre, stdGapOverlap_pre, durA_pre, durB_pre] = summarizeData(timeSeriesTC1, filename, plot_yn);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Clean-up gaps and overlaps %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    timeSeriesTC1 = cleanUpTS(timeSeriesTC1); % TO-DO; only cleans up overlaps so far
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Summarize and visualize time series POST-clean-up %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [gapOverlap_post, meanGapOverlap_post, stdGapOverlap_post, durA_post, durB_post] = summarizeData(timeSeriesTC1, filename, plot_yn);
    
    pause % to view histogram and plot for each subject
    
    if AnalysisType == 2
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Save result data to mat file %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %save key press RESULTS to .mat file %
        keyRes.subjects(1,i).name = filename; %save filename
        keyRes.subjects(1,i).data = timeSeriesTC1; % save time series
        keyRes.subjects(1,i).gap = gapOverlap_post; %save gaps/overlaps values
        keyRes.subjects(1,i).results(1) = meanGapOverlap_post; %save single val results in results bin
        keyRes.subjects(1,i).results(2) = stdGapOverlap_post;
        save('C:\Users\Erin\Box Sync\UPF\PlaidProj\Data\processed\keyPressData\keyRes.mat','keyRes');
        
    elseif AnalysisType == 3
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Add result data to structure %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        simRes.run(1,i).name = filename; %add filename
        simRes.run(1,i).data = timeSeriesTC1;
        simRes.run(1,i).gap = gapOverlap_post; %add gaps/overlaps values
        simRes.run(1,i).results(1) = meanGapOverlap_post; %add single val results in results bin
        simRes.run(1,i).results(2) = stdGapOverlap_post;
    end
    
end


%%%%%%%%%%%%%%%%%%
%% ANALYZE DATA %%
%%%%%%%%%%%%%%%%%%

%% Evaluate group data if real data

if AnalysisType == 2
    
    load('C:\Users\Erin\Box Sync\UPF\PlaidProj\Data\processed\keyPressData\keyRes.mat','keyRes');
    
    for i = 1 : length(keyData.subjects)
        groupMeanGap(i,1) = keyRes.subjects(1,i).results(1);
        groupMeanStd(i,1) = keyRes.subjects(1,i).results(2);
    end
    
    
    figure
    hist(groupMeanGap)
    str = sprintf('Mean gap time between press for %d subjects with mean gap %.2f \n (a negative # would indicate overlap)', length(groupMeanGap), mean(groupMeanGap));
    title(str)
    figure
    hist(groupMeanStd)
    str2 = sprintf('Standard deviation for gap time for %d subjects with mean SD %.2f', length(groupMeanStd), mean(groupMeanStd));
    title(str2)
    
    %~ 120 ms gap is the mean, ~ 50 is 1 SD : anything > 220 ms is an 'outlier'
end

%% Evaluate data if simulated

if AnalysisType == 3
    

    %%%%%%%%%%%%%%%%%%%%%%%
    %%% Autocorrelation %%%
    %%%%%%%%%%%%%%%%%%%%%%%
    
    % Autocorrelation (return best lag(sec) and best normalized r coeff)
    [lagTC1, rTC1] = autocorrelation(simRes.run(1,1).data(:,2), FR, simRes.run(1,1).name);

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Cross- correlation %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%
       
    % cross-correlation analysis (return best lag(sec), best norm r-coeff,
    % r-coeff at 0 sec lag (xcorr), r-coeff at 0 sec lag (corrcoef)
    [lagA, rA, rA0_1, rA0_2] = crossCorrelation(simRes.run(1,1).data(:,2), simRes.run(1,2).data(:,2), FR, 'press A');
    [lagB, rB, rB0_1, rB0_2] = crossCorrelation(simRes.run(1,1).data(:,3), simRes.run(1,2).data(:,3), FR, 'press B');
      
  
end