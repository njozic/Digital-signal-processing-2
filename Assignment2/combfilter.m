% Date      :   2018-07-22
% Author    :   Niko Jozic
% Course    :   DSP2

function [fa,fb] = combfilter(a,b,factor)

    fa = zeros(1,length(a)*factor);
    fb = zeros(1,length(b)*factor);
    
    for i=1:length(a)
        fa( ((i-1)*factor)+1) = a(i);
    end
    for i=1:length(b)
        fb( ((i-1)*factor)+1) = b(i);
    end
end