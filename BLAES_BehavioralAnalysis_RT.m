function BLAES_BehavioralAnalysis()

%% Load data
% practice images:          001-004 
% practice images response: 005-008 
% study images:             101-720
% study images response:    801-1420
% stimulation:              1501-1502
% fixation:                 1601-1786
% ISI (not used):           1801
% instructions:             1901-1905
% sync pulse:               1906        

clear;
close all;

addpath(genpath(fullfile(cd,'BCI2000Tools')))

subjID         = 'UIC202205';
imageset       = 'imageset1';

NoKeys     = [67 86];
YesKeys   = [78 66];
ResponseKeys   = [NoKeys, YesKeys]; % 67 sure no, 86 maybe no, 66 maybe yes, 78 sure yes
% if NoKeys == 1
%     response = 'new';
% else
%     response = 'old';
%end
% if size(ResponseKeys,2) == 2 %giving me # of the columns of the resp key matrix
%     SureResponseString = '_Sure';
% else
%     SureResponseString = '';
% end

SureKeys = [67,78];
MaybeKeys = [86,66];
% 
% if SureKeys == 1
%     confidence = 'sure';
% else
%     confidence = 'not_sure';
% end

LoadStoredData = 1;
figsize        = [100 100 1200 800];

% create directory to save results
%mkdir(fullfile(cd, 'figures', subjID, imageset))
      
%% Get relevant .dat files
d = dir(fullfile(cd,'*.dat')); %this way you should have your .dat files in the same directory as this script

%Don't include any .dat files with training data
removefile = [];
iter = 1;
for file = 1:size(d,1)
    if strfind(d(file).name,'Training')
        removefile(iter) = file;
        iter = iter + 1;
    end
end
d(removefile) = [];
clear removefile


%% Extract behavioral data
if LoadStoredData && exist(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Test_Data','.mat')))
    load(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Test_Data','.mat')))
else
    iter2 = 1;
all_sessions = cell(0,0);
    for file = 1:size(d,1)
        
        [~, states, param] = load_bcidat(fullfile(d(file).folder,d(file).name));
        pause(1);
%states.KeyDown(states.KeyDown ~= 0) will give us the key presses (non
%zeros)
%size(states.KeyDown(states.KeyDown ~= 0)) - how many button pressed in
%this session (session size is 60)
        
        seq         = param.Sequence.NumericValue;
        seqResponse = seq;
        KD          = states.KeyDown;
        StimCode    = states.StimulusCode;
        KD          = double(KD);
        StimCode    = double(StimCode);
        
        %% clean up sequence
        % select only image stimuli
        seq(seq<101) = [];
        seq(seq>800) = [];
        
        seqResponse(seqResponse<801)  = [];
        seqResponse(seqResponse>1500) = [];
        
        % ResponseStimCodeIdx also includes the no-response phase before they are allowed to respond
        ResponseStimCodeIdx = {};
        for i = 1:size(seq,1)
            ResponseStimCodeIdx{i} = [find(StimCode==seq(i)); find(StimCode==seqResponse(i))];
        end
        
        %% clean up KeyDown
        % isolate keydown responses
        
        % find key down events during the no response or response phases and organize so we do not miss any responses
        
        % also take the second response if they respond during the no response phase and have to respond again
        KD_cell = [];
        first_KD_list = [];
        for i = 1:size(seq,1)
            KD_cell{i} = KD(ResponseStimCodeIdx{i}); %KD(ResponseStimCodeIdx{i}) tells us
            %the index array of the reponse time period and in here we can find the actual key press.
            %extact time stamp index of the first key press
            %find(KD_cell{1,1}) includes time stamp index for both image on
            %the screen and the time stamp index for the response time period
            %You need to take the first of this value and then divide it by
            %2000 which is our sampling rate
            %in KD_cell has all the times a keypress could have occurred
            %and the first cell in KD_cell corresponds to the time stamp
            %for the first presentation of the image, just not with the
            %same index, but that's OK, no need to do any subtraction.
            RT_time_stamp = find(KD_cell{1,i});
            if size(RT_time_stamp,1)> 1
                first_KD = RT_time_stamp(1,1);
            elseif size(RT_time_stamp,1) == 0 
                first_KD = nan;
            else 
                first_KD = RT_time_stamp;
            end
            first_KD_list = [first_KD_list,first_KD];

            KD_cell{i}(KD_cell{i}==0) = [];
            if length(KD_cell{i}) > 1
                KD_cell{i} = KD_cell{i}(end);
            end
        end
       RT = first_KD_list*(1/2000);
        % swap out for a double version of KD
        clear KD
        for i = 1:size(KD_cell,2)
            KD(i) = KD_cell{i};
        end
        clear KD_cell

        %find(states.KeyDown ~= 0) gives us the time stamp index of when a
        %button press occured
        
        % Remove any key presses that were not the response keys
        % This shouldn't ever do anything because I always take the second key down event, which should also meet
        % the EarlyOffsetExpression and advance to the fixation cross
        BadKD = [];
        iter = 1;
        for i = 1:length(KD)
%             if KD(i) ~= ResponseKeys(1) && KD(i) ~= ResponseKeys(2) && KD(i) ~= ResponseKeys(3) && KD(i) ~= ResponseKeys(4)
            if ~any(ismember(ResponseKeys,KD(i)))
                BadKD(iter) = i;
                iter = iter + 1;
            end
        end
        
        KD(BadKD) = 0;

       
        %% Compile data into single matrix
       if file == 1
           offset = 1;
        collectData{1,1} = 'Session Number';
        collectData{1,2} = 'Image Filename';
        collectData{1,3} = 'Identity';
        collectData{1,4} = 'Sequence';
        collectData{1,5} = 'Stimulation (0 = no, 1 = yes)';
        collectData{1,6} = 'Resp Condition';
        collectData{1,7} = 'Keydown';
        collectData{1,8} = 'RT';
        collectData{1,9} = 'Response';
        collectData{1,10} = "Confidence";
       else 
           offset = 0;
       end

        for i = 1:length(seq)
            collectData{i+offset,1} = d(file).name;                           % session number
            collectData{i+offset,2} = param.Stimuli.Value{6,seq(i)};          % filename
            collectData{i+offset,3} = param.Stimuli.Value{9,seq(i)};          % identity
            collectData{i+offset,4} = seq(i);                                 % Sequence
            collectData{i+offset,5} = str2num(param.Stimuli.Value{8,seq(i)}); % Stimulation
            collectData{i+offset,6} = param.Stimuli.Value{10,seq(i)};         % response condition/novelty
            collectData{i+offset,7} = KD(i);                                  % KeyDown
                     if KD(i) == 67
             response = 'new';
             confidence = 'sure';
        elseif KD(i) == 86
             response = 'new';
             confidence = "not_sure";
        elseif KD(i) == 78
             response = 'old';
             confidence = "sure";
        elseif KD(i) == 66
             response = 'old';
             confidence = "not_sure";
        else
            response = "";
            confidence = "";
        end
            collectData{i+offset,8} = RT(i);                               % RT       
            collectData{i+offset,9} = response;                            % Response
            collectData{i+offset,10} = confidence;                         % Confidence
        end

       all_sessions = vertcat(all_sessions, collectData);
       clear collectData
         %save(fullfile(cd,strcat(subjID,'_Test_Data_',imageset, d(file).name,'.mat')),'collectData')
    end
    
    save(fullfile(cd,strcat(subjID,'_Test_Data_',imageset,'all','.mat')),'all_sessions');
    writecell(all_sessions, fullfile(cd,strcat(subjID,'_Test_Data_',imageset,'all','.csv')),'Delimiter', ',');
end
