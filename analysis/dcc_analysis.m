% DCC_analysis.m
% This is an imaging analysis script. It analyzes image taken from the
% Thorlabs camera using our home made MATLAB code. I

disp(repmat('-',1,60));disp([mfilename '.m']);disp(repmat('-',1,60)); 

% Add all subdirectories for this m file
curpath = fileparts(mfilename('fullpath'));
addpath(curpath);addpath(genpath(curpath))    



%% Close all non GUI figures
% Close all figures without the GUI tag.
figs=get(groot,'Children');
disp(' ');
disp('Closing all non GUI figures.');
for kk=1:length(figs)
   if ~isequal(figs(kk).Tag,'GUI')
       disp(['Closing figure ' num2str(figs(kk).Number) ' ' figs(kk).Name]);
      close(figs(kk)) 
   end
end
disp(' ');

%% Analysis Variable
% This section of code chooses the variable to plot against for aggregate
% plots.  The chosen variable MUST match a variable provided in the params
% field of the .mat file. The unit has no tangibile affect and only affects
% display properties.

dcc_xVar='DMD_power_val';

% Should the analysis attempt to automatically find the unit?
dcc_autoUnit=1;

% If ixon_autoUnit=0, this will be used.
dcc_overrideUnit='ms';


%% Analysis Flags

% Box Count
doBoxCount=1;           % Box count analysis

doAnimate=1;

dcc_doSave=1;
%% Select image directory

global dcc_imgdir
% Choose the directory where the images to analyze are stored
disp([datestr(now,13) ' Choose an image analysis folder...']);
dialog_title='Choose the root dire ctory of the images';
dcc_imgdir=uigetdir(dcc_getImageDir(datevec(now)),dialog_title);
if isequal(dcc_imgdir,0)
    disp('Canceling.');
    return 
end

%% Load the data
clear dcc_data
disp(['Loading data from ' dcc_imgdir]);
files=dir([dcc_imgdir filesep '*.mat']);
files={files.name};

for kk=1:length(files)
    str=fullfile(dcc_imgdir,files{kk});
    [a,b,c]=fileparts(str);      
    disp(['     (' num2str(kk) ')' files{kk}]);    
    data=load(str);     
    data=data.data;  

    % Display image properties
    try
        disp(['     Image Name     : ' data.Name]);
        disp(['     Execution Time : ' datestr(data.Date)]);
        disp(['     ' dcc_xVar ' : ' num2str(data.Params.(dcc_xVar))]);
        disp(' ');
    end    
    
    if isequal(dcc_xVar,'ExecutionDate')
        data.Params.(dcc_xVar)=datenum(data.Params.(dcc_xVar))*24*60*60;
    end  
    dcc_data(kk)=data;    
end
disp(' ');

if isequal(dcc_xVar,'ExecutionDate')
   p=[dcc_data.Params] ;
   tmin=min([p.ExecutionDate]);
   for kk=1:length(dcc_data)
      dcc_data(kk).Params.ExecutionDate= ...
          dcc_data(kk).Params.ExecutionDate-tmin;
   end     
end

% Grab the unit information
if dcc_autoUnit && isfield(dcc_data(1),'Units') 
    dcc_unit=dcc_data(1).Units.(dcc_xVar);
else
    dcc_unit=dcc_overrideUnit;
end

if isequal(dcc_xVar,'ExecutionDate')
   dcc_unit='s'; 
end

% Sort the data by your given parameter
disp(['Sorting dccdata by the given ''' dcc_xVar '''']);
x=zeros(length(dcc_data),1);
for kk=1:length(dcc_data)
    if isfield(dcc_data(kk).Params,dcc_xVar)
        x(kk)=dcc_data(kk).Params.(dcc_xVar);
    else
        warning(['atomdata(' num2str(kk) ') has no ''' dcc_xVar '''']);
    end
end

% Sort it
[~, inds]=sort(x);
dcc_data=dcc_data(inds);

%% ROI
ROI=[1 1280 1 1024];
% Assign the ROI
[dcc_data.ROI]=deal(ROI);

%% Box Count

bgROI=[50 100 50 500];
boxPopts=struct;
boxPopts.xUnit=dcc_unit;
if doBoxCount
    dcc_data=dcc_boxCount(dcc_data,bgROI);
    
    [dcc_hF_numberbox,dcc_Ndatabox]=dcc_showBoxCounts(dcc_data,dcc_xVar,boxPopts); 
    if dcc_doSave;dcc_saveFigure(dcc_data,dcc_hF_numberbox,'dcc_box_number');end
    
end

%% Animate

if doAnimate
    dcc_animate_opts=struct;
    dcc_animate_opts.CLim=[0 150];    
%   dcc_animate_opts.CLim='auto';    
    dcc_animate_opts.XCut=635;
    dcc_animate_opts.YCut=505;
    dcc_animate_opts.StartDelay=3;   % Time to hold on first picture
    dcc_animate_opts.MidDelay=1;    % Time to hold in middle picutres
    dcc_animate_opts.EndDelay=2;     % Time to hold final picture
    dcc_animate_opts.doAverage=1;    % Average over duplicates?
    dcc_animate_opts.xUnit=dcc_unit;
    dcc_animate_opts.Order='ascend';   
    
   dcc_animate(dcc_data,dcc_xVar,dcc_animate_opts) 
end

    
    
    