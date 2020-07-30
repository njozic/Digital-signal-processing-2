%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %  Date      :   2018-07-22
 %  Author    :   Niko Jozic
 %  Course    :   DSP2
 %
 %  File: myAdaptiveFilt.m
 %
 %  Input parameters:
 %  	b      Filter coefficients
 %      alpha  Adaptive filter step size
 %      x      Input signal (Noise)
 %      t      Target signal (Mixed signal)
 %
 %  Output parameters:
 %      y      Adaptive output signal
 %      e      Error signal
 %      new_b  Updated filter coefficients
 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [y, e, new_b] = myAdaptiveFilt(b,alpha,x,t)

    y = zeros(numel(x),1);
    e = zeros(numel(x),1);
    num_b = numel(b);
    lbvec = zeros(num_b,1);
    delay = 0.5*numel(xcorr(x,t)+1)-find(xcorr(x,t) == max(xcorr(x,t)),1);
    t = (0:numel(t)-1)/441000;
    x(1:delay) = [];
    
    for m=1:numel(x)
        
        lbvec(1) = x(m);
        
        for n=1:num_b
            y(m) = y(m) + b(n) * lbvec(n);
        end
        
        e(m) = y(m) - t(m);     

        for n=num_b:-1:1
        b(n) = b(n) + alpha*2*e(m)*lbvec(n);
            if(n~=1)
                x(n) = lbvec(n-1);
            end
        end
        
    end
     
    % Return updated filter coefficients to caller
    new_b = b;
end


