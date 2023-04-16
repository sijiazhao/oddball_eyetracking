function signal = framp(n,signal,fs)
% This script adds a n ms ramp-up and ramp-down to the
% stimulus. The Sampling frequency is hard-coded as 44,000 Hz.
% Copyright (c) 2019, Sijia Zhao.  All rights reserved.
% Contact: sijia.zhao.10@ucl.ac.uk

if nargin <3
    fs = 44100;
end

signal = reshape(signal,1,length(signal));

l = length(signal);
%time = len/fs; %length in seconds

%computing how many points represent sz ms
points = n*1/1000*fs;
points=round(points);

%fitting the points with a cosine function
freq = fs/(2*points);
sd = 1/fs;
n = 1:points;
t = n*sd;
ramp1 = ((1+(cos(2*pi*freq*t + pi)))/2).^2;
ramp2 = ((1+(cos(2*pi*freq*t )))/2).^2;

%creating the filter
ramp = [ramp1 ones(1,l-length(ramp1) - length(ramp2)) ramp2];
signal = ramp.*signal;
end
