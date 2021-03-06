function [vecAoff, vecBoff, ES] = addLastRelease(vecAon, vecAoff, vecBon, vecBoff, ES, timeMaxTS)

%keyboard

len_ES = length(ES(:,1)); % length of Event Series

% Button A
if (length(vecAon)-length(vecAoff))==1 %end of trial occurred during Aon
    vecAoff(length(vecAoff)+1, 1) = len_ES + 1;   % add new index to vecAoff
    % add new row to ES
    ES(len_ES + 1, 1) = len_ES + 1; % add new index to time course column 1
    ES(len_ES + 1, 2) = timeMaxTS; % set last 'press' in column 2 to last frame of time series
    ES(len_ES + 1, 3) = 2; % set event label in column 3 to Aoff
else
    if (length(vecAon)~=length(vecAoff)) %if end of trial was during Aoff,
        fprintf('Warning: Aon and Aoff should be of equal length\n')            
    end
end

if min(vecAoff-vecAon)<0
      fprintf('Warning: each AOff event must be after an AOn event\n')  
      diff = vecAoff-vecAon
      disp('difference between vecAon and vecAoff')
end

% Button B
if (length(vecBon)-length(vecBoff))==1
    vecBoff(length(vecBoff)+1, 1)= len_ES + 1; % add new index to vecBoff
    % add new row to ES
    ES(len_ES + 1, 1) = len_ES + 1; % add new index to time course column 1
    ES(len_ES + 1, 2) = timeMaxTS; % set last 'press' in column 2 to last frame of time series
    ES(len_ES + 1, 3) = -2; % set event label in column 3 to Boff
else
    if (length(vecBon)~=length(vecBoff))
        fprintf('Warning: Bon and Boff should be of equal length\n')
    end
end

if min(vecBoff-vecBon)<0
      fprintf('Warning: each BOff event must be after an BOn event\n')
      diff = vecBoff-vecBon
      disp('difference between vecBon and vecBoff')
end