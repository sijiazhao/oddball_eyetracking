# oddball
MATLAB code for auditory oddball task with eyetracking.
This is just a super simple example for how to play sound and record eyetracking using Psychtoolbox (http://psychtoolbox.org/) in MATLAB.

SPECIAL NOTE: The sounds in the folder 'SoundFiles' have not been RMS equalised!!!
SPECIAL NOTE 2: There might be **many bugs!** 

## Stimuli
In one block, deviant sounds were presented against standard sounds. The standard sound is a 500-Hz pure tone, and there are two deviant types: white noise and harmonic tones (f0=200 Hz; 30 harmonics). All sounds are 500 ms long and with 30-ms cosine onset and offset ramps. (THEY SHOULD ALSO BE RMS EQUALISED.) In total, each deviant type was presented 10 times, for 20 deviant trials in total, and the standard type presented 60 times, resulting in an overall deviant probability of 25%. The inter-sound-onset interval is randomised between 3-3.5 second.
## Procedure
After calibration, subjects should be instructed to fixate their pupils on a fixation cross and listen to the sounds through headphones.
Before the presentation of the first sound, there is a 15-second long resting state recording.
