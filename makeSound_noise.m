clear;
Fs = 44100;
stimDur = 0.5;

n = stimDur*Fs;
signal = wgn(n,1,0);
signal = reshape(signal,1,length(signal));

signal = signal/max(abs(signal));
signal = signal*0.8;

signal = framp(30,signal,Fs); % add 30ms ramp-up and ramp-down to the stimulus

filename = ['noise_white.wav'];
audiowrite(filename,signal,Fs);

