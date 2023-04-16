clear; close all;

path_in =  './Laugh_chopped/';
files = dir([path_in '*.wav']);

path_out = './Laugh_chopped_ramped/';
if exist(path_out) == 7, rmdir(path_out,'s'); end
mkdir(path_out);

fs = 44100;

for s = 1:numel(files)
    filename = [path_in files(s).name];
    [signal,~] = audioread(filename);
    
    signal = framp(30,signal,fs); % add 30ms ramp on both sides
    
    figure();
    plot(signal);
    
    filename = [path_out,'ramped_' files(s).name];
    audiowrite(filename, signal, fs);
end
