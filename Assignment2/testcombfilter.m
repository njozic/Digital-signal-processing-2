% Date      :   2018-07-22
% Author    :   Niko Jozic
% Course    :   DSP2

close all; clear all; format compact;
clc; set(gcf,'color','w');

Fs = 360; % Hz sampling frequency

% % Notch filter
f0 = 50; %hz for the notch filter
Q = 20;
w0 =2*pi*f0/Fs;
dw =w0/Q;
r = 1-dw/2;
b = [1 -2*cos(w0) 1];
a = [1 -2*r*cos(w0) r^2];
subplot(1,2,1);
zplane(b,a);
factor = 4;
[fa,fb] = combfilter(a,b,factor);
subplot(1,2,2);
zplane(fb,fa);

%%
% Set up the Signal
F1 = 50;
F2 = 100;
Fs = 500*2*pi;
dt = 1/Fs;
T = 1/min([F1,F2]);
t = 0:dt:(3*T)-dt;
signal = sin(2*pi*F1*t)+0.75*sin(2*pi*F2*t);
noise = rand(1,length(signal))-0.5;

subplot(2,2,1);
plot(t,signal+noise);
hold on;
plot(t,signal);

% Frequency-Spectrum of clean Signal
f_spectrum = fft(signal);
N = floor(length(f_spectrum)/2);
f_spectrum_singlesided = f_spectrum(1:N);
f_spectrum_normalized = f_spectrum_singlesided/(N*2);
f_axis = (0:N-1)/N*Fs/2;

% Frequency-Spectrum of clean Signal
f_spectrum_noise = fft(signal+noise);
f_spectrum_noise_singlesided = f_spectrum_noise(1:N);
f_spectrum_noise_normalized = f_spectrum_noise_singlesided/(N*2);

subplot(2,2,2);
plot(f_axis, abs(f_spectrum_noise_normalized));
hold on
plot(f_axis, abs(f_spectrum_normalized));


% FIR-Design
f0 = 100; %hz for the notch filter
Q = 100;
w0 =2*pi*f0/Fs;
dw =w0/Q;
r = 1-dw/2;
b = [1 -2*cos(w0) 1];
a = [1 -2*r*cos(w0) r^2];



