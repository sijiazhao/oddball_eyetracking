clear; close all;

path_in = './Laugh_original/';
files = dir([path_in '*.wav']);
path_out = './Laugh_chopped/'; mkdir(path_out);

dur = 0.5;
st = [10.02,1.8];
for s = 1:numel(files)
    
    filename = [path_in files(s).name];
    [x,sr] = audioread(filename);
    
    figure(1);clf;
    subplot(2,1,1);
    timeaxis = [1:length(x)]/sr;
    plot(timeaxis,x);
    
    starttime = st(s);
    if st(s)>0
        endtime = starttime+dur;
        x = x(round(starttime*sr):round(endtime*sr));
    else
        x = x(1:round(dur*sr));
    end
    
    subplot(2,1,2);
    x = x/max(x)*0.8;
    timeaxis = [1:length(x)]/sr;
    plot(timeaxis,x);
    
    filename = [path_out files(s).name];
    audiowrite(filename,x,sr);
end

disp(['..Total of ' num2str(numel(files)) ' sounds.']);


