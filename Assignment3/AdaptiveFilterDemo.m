%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %  File: AdaptiveFilterDemo.m
 %
 %  Description:
 %  	Adaptive LMS demo which adds random noise to an internet radio stream
 %      (Windows based systems only - Windows MMS Streaming technology).
 %
 %  Features:
 %      Option to vary noise level
 %      Option to select between MATLAB Adaptive LMS filtering and own
 %      implementation
 %  
 %  File dependencies:
 %  	myAdaptiveFilt.m
 %
 %  Author: Peter Ott
 %  Date: 18-April-2015
 %  Version: 1.4
 %  
 %  Version History:
 %      18-April-2016 Version 1.4
 %          - Change from deprecated adaptfilt.lms to modern dsp.LMSFilter object
 %
 %      23-March-2015 Version 1.3
 %          - Refactoring of variable 'url' to 'file'
 %          - Added info that MMS streaming is deprecated without further
 %            notice
 %          - Added DSP System Toolbox check
 %
 %      24-March-2014 Version 1.2
 %          - Set 'OutputDataType' as 'int16' for AudioFileReader object.
 %            Fixes problems, where audio file defaults output to 'double'.
 %          - Get sample rate for AudioPlayer directly from audio source.
 %          - Check existence of variables in catch section.
 %            Fixes exceptions, where variables are not yet instantiated.
 %
 %      26-May-2013 Version 1.1
 %          - GUI redesign
 %          - Option 'None' added
 %          - Delay option added
 %
 %      22-April-2013 Version 1.0
 %          - Initial release
 %
 %  Known issues:
 %      Script doesn't work for MATLAB versions below R2010b
 %      MMS streaming deprecated for MATLAB versions above R2012b
 %
 %  Courses:
 %
 %  	Digital Signal Processing 2 Lab
 %  	Master's Degree Program
 %  	Information Technology and Systems Management
 %  	Salzburg University of Applied Sciences
 %  	http://www.fh-salzburg.ac.at/its
 %
 %  	Digital Signal Processing 2 Lab
 %  	Master's Degree Program
 %  	Applied Image and Signal Processing
 %  	Salzburg University of Applied Sciences
 %  	http://www.fh-salzburg.ac.at/ais
 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clean up workspace
clear;

% File path
file = 'File.mp3';

% DEPRECATED
% Seems like MMS streams are no longer supported in MATLAB after 2012b.
% MMS streaming still available in Simulink function block.
%file = 'mms://apasf.apa.at/OE3_Live_Audio';

% Define whether to use reference MATLAB implementation or own
% 0 -> None
% 1 -> Own adaptive LMS
% 2 -> MATLAB adaptive LMS
optSelection = 0;

% Define sampling frequency
fs = 44100;
% Approximation step width for adaptive filter
alpha = 0.1;
% Number of FIR coefficients
taps = 128;
% Define buffer size
frameWidth = 2048;
% Define noise level (Max: 32767/Min: 0)
noiseLevel = 5000;
% Define delay (Max: 256/Min: 0)
delay = 0;
delayedNoise = zeros(frameWidth,1);

% Check for DSP System Toolbox
toolboxes = ver;
if any(strcmp('DSP System Toolbox', {toolboxes.Name})) == 0
    error('MATLAB "DSP System Toolbox" required')
    exit
end

% Initial coefficients
b = zeros(taps+1,1);

% Create adaptive filter
hlms = dsp.LMSFilter(taps);
% Assign step size to MATLAB filter
hlms.StepSize = alpha;

% Create GUI
wnd = figure(1);
set(wnd,'Color',[0.95 0.95 0.95]);

% Destructor
set(wnd,'DeleteFcn','execute = 0;');
% Set menu bar invisible -> Not used
set(wnd,'MenuBar', 'None');
% Set figure number title invisible
set(wnd,'numbertitle','off');
% Set window name
set(wnd,'Name', mfilename);

% Create static label for noise level
uicontrol(...
    'Style','text',...
    'String','Noise Level',...
    'Units', 'normalized',...
    'FontUnits', 'normalized',...
    'FontSize',0.8,...
    'Position', [0.25 0.85 0.5 0.1]);

% Create dynamic label for noise level
lblNoiseLevel = uicontrol(...
            'Style','text',...
            'String',[num2str(20*log10(double(noiseLevel)/32767)) 'dB'],...
            'Units', 'normalized',...
            'FontUnits', 'normalized',...
            'FontSize',0.6,...
            'Position', [0.25 0.75 0.5 0.1]);

% Create slider for noise level input        
sldrNoiseLevel = uicontrol(...
                    'Style','slider',...
                    'String','Noise Level',...
                    'Units', 'normalized',...
                    'Position', [0.25 0.65 0.5 0.1],...
                    'Min',1,...
                    'Max',9000,...
                    'Value', noiseLevel,...
                    'Callback','noiseLevel = int16(get(sldrNoiseLevel,''Value''));set(lblNoiseLevel,''String'',[num2str(20*log10(double(noiseLevel)/32767)) ''dB'']);');
                
% Create static label for delay option
uicontrol(...
    'Style','text',...
    'String',{'Noise in mixed signal' 'delayed by'},...
    'Units', 'normalized',...
    'FontUnits', 'normalized',...
    'FontSize',0.3,...
    'Position', [0.25 0.4 0.5 0.2]);

% Create dynamic label for delay option
lblDelay = uicontrol(...
            'Style','text',...
            'String',[num2str(delay) ' Samples @ ' num2str(fs/1000) 'kHz'],...
            'Units', 'normalized',...
            'FontUnits', 'normalized',...
            'FontSize',0.4,...
            'Position', [0.25 0.35 0.5 0.1]);

% Create delay selection group
rbDelayGroup = uibuttongroup(...
                'Visible','off',...
                'Position',[0.25 0.25 0.5 0.1],...
                'SelectionChangeFcn','distance = get(get(rbDelayGroup,''SelectedObject''),''UserData'');delay=round(distance/343*fs);set(lblDelay,''String'',[num2str(delay) '' Samples @ '' num2str(fs/1000) ''kHz'']);');

% Create 'none' selection
rbNoDelay = uicontrol(...
                'Style','radiobutton',...
                'String','None',...
                'Units', 'normalized',...
                'Position',[0.2 0.3 0.2 0.5],...
                'Parent',rbDelayGroup,...
                'HandleVisibility','off',...
                'UserData',0);
            
% Create '1m' delay selection
rbDelay1m = uicontrol(...
                'Style','radiobutton',...
                'String','1m',...
                'Units', 'normalized',...
                'Position',[0.45 0.3 0.2 0.5],...
                'Parent',rbDelayGroup,...
                'HandleVisibility','off',...
                'UserData',1);
            
% Create '2m' delay selection
rbDelay2m = uicontrol(...
                'Style','radiobutton',...
                'String','2m',...
                'Units', 'normalized',...
                'Position',[0.7 0.3 0.2 0.5],...
                'Parent',rbDelayGroup,...
                'HandleVisibility','off',...
                'UserData',2);

set(rbDelayGroup,'SelectedObject',rbNoDelay);
set(rbDelayGroup,'Visible','on');

% Create LMS selection group
rbGroup = uibuttongroup('Visible','off','Position',[0 0 1 0.2]);

% Create None selection
rbNone = uicontrol(...
                'Style','radiobutton',...
                'String','None',...
                'Units', 'normalized',...
                'Position',[0.2 0.6 0.9 0.2],...
                'Parent',rbGroup,...
                'HandleVisibility','off',...
                'UserData',0);

% Create static label for option 'None'
uicontrol(...
    'Style','text',...
    'String',{'Left: Mixed Signal' 'Right: Noise'},...
    'HorizontalAlignment','Left',...
    'Units', 'normalized',...
    'Position', [0.2 0.1 0.2 0.4],...
    'Parent',rbGroup);

% Create MATLAB LMS selection
rbMatlabLMS = uicontrol(...
                    'Style','radiobutton',...
                    'String','MATLAB LMS',...
                    'Units', 'normalized',...
                    'Position',[0.45 0.6 0.9 0.2],...
                    'Parent',rbGroup,...
                    'HandleVisibility','off',...
                    'UserData',1);
                
% Create static label for option 'MATLAB LMS'
uicontrol(...
    'Style','text',...
    'String',{'Left: Mixed Signal' 'Right: LMS filtered'},...
    'HorizontalAlignment','Left',...
    'Units', 'normalized',...
    'Position', [0.45 0.1 0.2 0.4],...
    'Parent',rbGroup);

% Create Own LMS selection
rbMyLMS = uicontrol(...
                'Style','radiobutton',...
                'String','Own LMS',...
                'Units', 'normalized',...
                'Position',[0.7 0.6 0.9 0.2],...
                'Parent',rbGroup,...
                'HandleVisibility','off',...
                'UserData',2);
            
 % Create static label for option 'Own LMS'
uicontrol(...
    'Style','text',...
    'String',{'Left: Mixed Signal' 'Right: LMS filtered'},...
    'HorizontalAlignment','Left',...
    'Units', 'normalized',...
    'Position', [0.7 0.1 0.2 0.4],...
    'Parent',rbGroup);

% Set callback function for LMS selection
set(rbGroup,'SelectionChangeFcn','optSelection=get(get(rbGroup,''SelectedObject''),''UserData'');');

% Default to 'none' option
rbSelected = rbNone;

set(rbGroup,'SelectedObject',rbSelected);
set(rbGroup,'Visible','on');

% Small pause to draw GUI
pause(0.001);

% Start filtering
execute = 1;

try
    % Create audio source
    hSrc = dsp.AudioFileReader(file,'OutputDataType','int16');
    hSrc.SamplesPerFrame = frameWidth;
    
    % Create audio sink
    hSnk = dsp.AudioPlayer('SampleRate', hSrc.SampleRate);
    
    % Run till file ends or user aborts stream
    while ~isDone(hSrc) && execute
        
        % Small pause to capture GUI inputs
        pause(0.001);
        
        % Get current audio buffer step
        data = step(hSrc);
        % Convert buffer
        data = double(data(:,1));

        % Generate noise
        noise = randi([-noiseLevel noiseLevel],[frameWidth 1]);
        
        % Delay noise samples
        if delay > 0
            % Get oldest samples and copy them to the buffer
            delayedNoise(1:delay) = delayedNoise(end-delay+1:end);
        end
        % Copy new values to buffer
        delayedNoise(delay+1:delay+frameWidth) = noise;
        
        % Add noise to signal
        mixedSignal = data + delayedNoise(1:frameWidth);
        
        % Assign mixed signal to left channel
        dataOut(:,1) = mixedSignal;

        % Create moving average filter
        ma = [1, -0.8, 0.4 , -0.2];
        % Smooth noise peaks in order to simulate
        % captured noise by a microphone
        noise = filter(ma,1,noise);

        % Switch filtering option
        switch optSelection
            case 0
                % Assign captured noise signal
                dataOut(:,2) = noise;
            case 1
                % Filter with MATLAB adaptive LMS
                [ylms,elms] = step(hlms,noise./32767,mixedSignal./32767);
                
                % Rescale the signal amplitudes
                ylms = ylms.*32767;

                % Assign LMS filtered signal to right channel
                dataOut(:,2) = mixedSignal-ylms;
            case 2
                % Filter with own implementation
                [ylms,elms,b] = myAdaptiveFilt(b,alpha,noise./32767,mixedSignal./32767);
                
                % Rescale the signal amplitudes
                ylms = ylms.*32767;

                % Assign LMS filtered signal to right channel
                dataOut(:,2) = mixedSignal-ylms;
        end

        % Push audio buffer step into sink
        step(hSnk, int16(dataOut));
    end

    % Release audio source and sink
    release(hSrc);
    release(hSnk);

    try
    % Try to close the window
    close(wnd);
    catch
    end
    
catch ex
    ex.message
    
    % Release objects in the event of an exception
    if exist('hSrc','var')
        release(hSrc);
    end
    if exist('hSnk','var')
        release(hSnk);
    end

    %rethrow(ex);
end