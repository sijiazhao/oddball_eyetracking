%% Generate sound: pure tone
% Copyright (c) 2019, Sijia Zhao.  All rights reserved.
% Contact: sijia.zhao.10@ucl.ac.uk

clear;

Fs = 44100;
stimDur = 0.5;
freq = 500;

%create a tone of frequency f
sd = 1/Fs;
n = 1:Fs*stimDur;
t = n*sd;
signal = sin(2*pi*freq*t);

signal = signal/max(abs(signal));
signal = signal*0.8;

signal = framp(30,signal,Fs); % add 30ms ramp-up and ramp-down to the stimulus

filename = ['tone_' num2str(freq) 'Hz.wav'];
audiowrite(filename,signal,Fs)



