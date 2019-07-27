%% Copyright (c) 2019, Sijia Zhao.  All rights reserved.

% Note: Search '% CHANGE BASED ON YOUR SETUP!' to find lines you must customise
% for your own setup.

% Note 2: Line 71-82 MUST be optimised.

clear;close all;clc
rng('shuffle');
dbstop if error;

Screen('Preference', 'SkipSyncTests', 1);
expsbj = input(' NAME of PARTICIPANT? [eg. S10] = ','s');
thisblock = input(' BLOCK INDEX? = ');

el = 0; % 1 = Eyelink on; 0 = Eyelink off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ISI = 3:0.1:3.5; % [second] Inter-soundonset-interval. The distance between the onset of the current trial and the next sound
Fs = 44100; % sampling rate for sound play
stimDur = 0.5; % [second] sound duration. this must be pre-set and identical across all sounds

path_in = './SoundFiles/';

condlist = {'tone_1000Hz','noise_white','ht_200Hz'};
ntrial_c = [60, 10, 10]; %number of trials per condition
ntrial = sum(ntrial_c);

signal_sounds = {}; % read and store all three sounds
for i = 1:numel(condlist)
    filename = [path_in condlist{i} '.wav'];
    [signal_sounds{i},~] = audioread(filename);
end

ExpCond.numTrial = ntrial;
ExpCond.ISI = ISI;
ExpCond.stimDur = stimDur;

% Common eyetracking set up
ExpCond.distSc_Sbj = 65; % Distance from subject to monitor [cm] % CHANGE BASED ON YOUR SETUP!
ExpCond.ScWidth = 53.4; % Screen width [cm] % CHANGE BASED ON YOUR SETUP!
ExpCond.smpfreq = 1000; % Sampling rate of Eyelink [Hz] % CHANGE BASED ON YOUR SETUP!
ExpCond.linewidth = 7; % in pixels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set folders and filenames
ExpDataDrct = ['./Data/']; %this vector will be updated later (add date)
outfile = [expsbj,'_',thisblock];

% Eye-tracking data's filename (temporary)
switch el
    case 1
        Eyelinkuse = 'on';
    case 0
        Eyelinkuse = 'off';
end
ExpDrct =  './';
tmpname = '100'; %temporary name for eyetracking data

ExpDataDrct = [ExpDataDrct,'/'];
mkdir(ExpDataDrct);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute the stimuli indexs for each block
shuffleidx = [];
for k = 1:numel(condlist)
    shuffleidx = [shuffleidx, k*ones(1,ntrial_c(k))];
end
triallist = shuffleidx(randperm(ntrial));

%% Add a constraint: make sure two deviants (2 or 3) are not next to each other
% ## This part needs to be optimised.
minDeviantDistance = 1;
i_d = find(triallist~=1);
flag_consc = find(diff(i_d)<=minDeviantDistance);
while ~isempty(flag_consc)
    triallist = shuffleidx(randperm(ntrial));
    i_d = find(triallist~=1);
    flag_consc = find(diff(i_d) <= minDeviantDistance);
    disp('Reshuffle...');
end
% ## This part needs to be optimised.

%% Initialize PsychPortAudio & Create Buffer
diary([ExpDataDrct,outfile,'_audiolog.asc']);

InitializePsychSound(1);
nsoundcard = 9; % Soundcard location % CHANGE BASED ON YOUR SETUP!
padevice = PsychPortAudio('Open',nsoundcard,[],0,Fs); 
PsychPortAudio('RunMode',padevice,1);

%   Read wavname, extract stimuli information, and put audio to buffer
%   (prepare the sound)
BufferHandles = zeros(1,ntrial);
for k = 1:ntrial
    tmpwav = signal_sounds{triallist(k)};
    BufferHandles(k) = PsychPortAudio('CreateBuffer', padevice, repmat(tmpwav,1,2)');
end
clear tmpwav;

load([ExpDrct, 'Tone1000.mat']);
BufferHandles(ntrial+1) = PsychPortAudio('CreateBuffer', padevice, repmat(mywav,2,1));

% Archive the output latency for RT calculation
PsychPortAudio('FillBuffer',padevice,BufferHandles(ntrial+1));
PsychPortAudio('Start',padevice, 1, 0, 1);
diary off;

%% load audiolog (output latency)
filename = [ExpDataDrct,outfile,'_audiolog.asc'];
identifier = '%s %s %s %s %s %s %s %s %s %s %s %s';
fid = fopen(filename);
tmp = textscan(fid, identifier);
fclose(fid);
for k=1:length(tmp{11})
    if strcmp(tmp{11}{k},'latency')==1
        if strcmpi(tmp{10}{k},'output')==1
            Oindex = k;
            break
        end
    end
end
ExpCond.audlag = str2double(tmp{12}{Oindex}); % unit:[msec]
clear Oindex tmp

%% Eyelink Setting
dummymode = 0;
KbName('UnifyKeyNames');
Screen('Preference', 'VisualDebuglevel', 2);
screens=Screen('Screens');

% screenNumber = 1;
screenNumber = max(screens);
[window,ExpCond.rect]=Screen('OpenWindow',screenNumber);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EyeLink Calibration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Eyelinkuse,'on')==1
    if ~dummymode, HideCursor; end
    commandwindow;
    fprintf('EyelinkToolbox Example\n\n\t');
    eyl=EyelinkInitDefaults(window);
    ListenChar(2);
    if ~EyelinkInit(dummymode, 1)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end
    [v,vs]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
    %     Eyelink('Openfile',[EyelinkName,'.edf']);
    Eyelink('Openfile',[tmpname,'.edf']);
    EyelinkDoTrackerSetup(eyl);
    EyelinkDoDriftCorrection(eyl);
    Eyelink('StartRecording');
    WaitSecs(0.1);
    Eyelink('Message', 'SYNCTIME');
end
%%%%%%%%%%%%%%%%%%%%%% EyeLink Calibration End %%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up Screens

white = WhiteIndex(window);
black = BlackIndex(window);
gray = (white+black)/2;
inc = white-gray;
bgColor = [gray gray gray]*3/2;
red = [black white white];
fixSize = [0 0 25 25];
fixColor = 10;
FBcolor = [180 180 180];

VA1deg.cm = 2*pi*ExpCond.distSc_Sbj/360;  % visual angle 1 deg [unit:cm]
VA05deg.cm = 2*pi*ExpCond.distSc_Sbj/360/2;  % visual angle 0.5 deg [unit:cm]
px_in_cm = ExpCond.ScWidth/ExpCond.rect(3); % one pixel on the specified screen [unit:cm]
VA1deg.px = floor(VA1deg.cm/px_in_cm); % visual angle 1 deg [unit:pixel]
VA05deg.px = floor(VA05deg.cm/px_in_cm); % visual angle 0.5 deg [unit:pixel]

% positions of the fixation point
centerpx = [ExpCond.rect(3)/2 ExpCond.rect(4)/2];       % position of the center H,V (in pixel)
fxpointH = [centerpx(1) centerpx(2) centerpx(1) centerpx(2)]+[-1 0 1 0]*floor(VA1deg.px/2);
fxpointV = [centerpx(1) centerpx(2) centerpx(1) centerpx(2)]+[0 -1 0 1]*floor(VA1deg.px/2);

textSize = 16;
text='Press SPACE KEY to start the experiment';
Screen('FillRect', window, bgColor);
Screen(window,'TextFont','Arial');
Screen(window,'TextSize',textSize);
x=(ExpCond.rect(3)-textSize*18)/2;
y=(ExpCond.rect(4)+textSize*0.75)/2;
Screen(window,'DrawText',text,x,y,[black black black]);
Screen('Flip', window);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
done = 0;
while 1
    [ keyIsDown, ~, keyCode ] = KbCheck;
    if keyIsDown && done==0
        if keyCode(KbName('Space'))
            Screen('FillRect', window, bgColor);
            Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
            Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
            Screen('Flip', window);
            disp('START!');
            WaitSecs(1.5)
            done=1;
            break
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Experiment Part

Screen('FillRect', window, bgColor);
Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
Screen('Flip', window);

tmptime = GetSecs;

breakp = 0;

%% Resting state pupil diameter
if strcmp(Eyelinkuse,'on')==1
    
    feedback4fixation = 0;
    
    Eyelink('StartRecording'); % start recording (to the file)
    error = Eyelink('checkrecording'); % Check recording status, stop display if error
    
    % check for endsaccade events
    fixcenter = 0;
    while fixcenter==0
        if Eyelink('isconnected') == eyl.dummyconnected % in dummy mode use mousecoordinates
            [x,y] = GetMouse(window);
            evt.type = eyl.ENDSACC;
            evt.genx = x;
            evt.geny = y;
            evtype = eyl.ENDSACC;
        else % check for events
            evtype = Eyelink('getnextdatatype');
        end
        
        if evtype == eyl.ENDSACC % if the subject finished a saccade check if it fell on an object
            if Eyelink('isconnected') == eyl.connected % if we're really measuring eye-movements
                evt = Eyelink('getfloatdata', evtype); % get data
            end
            
            % check if saccade landed on fixation cross
            if 1 == IsInRect(evt.genx,evt.geny, [centerpx(1)-100,centerpx(2)-100,centerpx(1)+100,centerpx(2)+100])
                
                fixcenter = 1;
                if feedback4fixation
                    Screen('FillRect', window, bgColor);
                    Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                    Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                    Screen('Flip', window);
                end
                
            else % if not fixating, toggle red fixation !
                
                if feedback4fixation
                    Screen('FillRect', window, bgColor);
                    Screen('DrawLine', window, [black white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                    Screen('DrawLine', window, [black white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                    Screen('Flip', window);
                end
                
            end
            WaitSecs(.1);
        end % saccade?
    end
    
    Screen('FillRect', window, bgColor);
    Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
    Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
    Screen('Flip', window);
    
    WaitSecs(2);
end % el

%% Wait for resting state
disp(['Block:',thisblock,' Resting state starts (15s)']);
disp('***');
if strcmp(Eyelinkuse,'on') == 1
    Eyelink('Message', ['Resting: Resting_state_for_15s']);
end
WaitSecs(15);


%% Check if you want to terminate the experiment
[ keyIsDown, ~, keyCode ] = KbCheck;
if keyCode(KbName('Escape'))
    breakp = 1;
    break;
end

%% Main experiment starts!
for k = 1:ntrial
       
    disp(['Block:',thisblock,' Trial:',num2str(k),' Condition: ', condlist{triallist(k)}]);
    disp('***');
    if strcmp(Eyelinkuse,'on')==1
        Eyelink('Message', ['Trial:',num2str(k),' ',condlist{triallist(k)}]);
    end
    
    %% Play sound
    PsychPortAudio('FillBuffer',padevice,BufferHandles(k));
    PsychPortAudio('Start', padevice, 1, 0, 1); %Start audio playback, return onset timestamp.

    %% Wait for ISI
    WaitSecs(ISI(randperm(length(ISI),1))); %wait for ISI
    
    %% Check if you want to terminate the experiment
    [ keyIsDown, ~, keyCode ] = KbCheck;
    if keyCode(KbName('Escape'))
        breakp = 1;
        break
    end
end
totaltime = GetSecs - tmptime;

ListenChar(0);
for k=1:ntrial
    PsychPortAudio('DeleteBuffer',BufferHandles(k));
end
PsychPortAudio('Close');

if breakp==0
    text='FINISHED!';
elseif breakp==1
    text='ABORTED!';
end
Screen('FillRect', window, bgColor);
Screen(window,'TextFont','Arial');
Screen(window,'TextSize',textSize);
x=(ExpCond.rect(3)-textSize*8)/2;
y=(ExpCond.rect(4)+textSize*0.75)/2;
Screen(window,'DrawText',text,x,y,[black black black]);
Screen('Flip', window);
WaitSecs(1.5);

if strcmp(Eyelinkuse,'on')==1
    
    EyelinkName=[ExpDataDrct outfile];
    
    Eyelink('Stoprecording');
    Eyelink('ReceiveFile',tmpname); % copy the file from eyetracker PC to Stim PC
    Eyelink('CloseFile');
    Eyelink('Shutdown');
    if breakp==0
        command = ['edf2asc ',tmpname,'.edf -ns'];
        status = dos(command);
        command = ['rename ',tmpname,'.asc ',tmpname,'_event.asc '];
        status = dos(command);
        command = ['edf2asc ',tmpname,'.edf -ne'];
        status = dos(command);
        command = ['rename ',tmpname,'.asc ',tmpname,'_sample.asc '];
        status = dos(command);
        movefile([tmpname '.edf'],[EyelinkName '.edf']);
        movefile([tmpname '_sample.asc'],[EyelinkName '_sample.asc']);
        movefile([tmpname '_event.asc'],[EyelinkName '_event.asc']);
    end
end

filename = [ExpDataDrct,'result_',outfile,'.mat']; %changed by Sijia
if breakp==0 %&& ifpractice==0 %&& Sblock~=0
    save(filename,'stim','ExpCond');
    disp('----- EXPERIMENT FINISHIED -----')
    disp(['- TOTAL TIME: ',num2str(totaltime)])
elseif breakp==1
    disp('----- EXPERIMENT ABORTED -----')
    disp(['- TOTAL TIME: ',num2str(totaltime)])
end
Screen('CloseAll');
