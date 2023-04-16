clear; close all;

path_in =  './Sounds_beforeRMS/';
files = dir([path_in '*.wav']);

path_out = './Sounds_RMSed/';
if exist(path_out) == 7, rmdir(path_out,'s'); end
mkdir(path_out);

x_rms=[];
xnew_rms=[];

for s = 1:numel(files)
    filename = [path_in files(s).name];
    [x,~] = audioread(filename);
    x_rms(s) = rms(x);
end

target_rms = 0.1; %% Hard coded! Please make sure this value is ok
for s = 1:length(files)
    filename = [path_in files(s).name];
    [sound,fs] = audioread(filename);
    rmsV = rms(sound);
    diff = target_rms-rmsV;
    sound = sound*target_rms/rms(sound);
    %check that there is no clipping
    if (max(abs(sound))>1)
        error ( ['clipping!!!!' files(s).name] )
    end
    filename = [path_out,'RMSeq_',files(s).name];
    audiowrite(filename, sound, fs);
end

for s = 1:numel(files)
    filename = [path_out,'RMSeq_',files(s).name];
    [x,~] = audioread(filename);
    xnew_rms(s) = rms(x);
end

figure(1);clf;
for s = 1:numel(files)
    filename = [path_out,'RMSeq_',files(s).name];
    [x,fs] = audioread(filename);
    subplot(numel(files),1,s);
    timeaxis = [1:length(x)]/fs;
    plot(timeaxis,x);
    title(strrep(files(s).name,'_',' '));
end

