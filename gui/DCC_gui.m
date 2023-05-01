function DCC_gui

%%
guiname='DCC Live';
% Find any instances of the GUI and bring it to focus, this is tof avoid
% restarting the GUI which may leave the shutter open.
h = findall(0,'tag','GUI');
for kk=1:length(h)    
    if isequal(h(kk).Name,guiname)        
        warning(['DCC GUI instance detected.  Bringing into focus. ' ...
            ' If you want to start a new instance, close the original DCC GUI.']); 
       figure(h(kk));
       return;
    end    
end

% Add all subdirectories for this m file
mpath = fileparts(mfilename('fullpath'));
addpath(mpath);addpath(genpath(mpath))

%% Settings
% Camera Settings
texp=.5; % Epxosure time ms
px_clck=30; % Pixel clock speed.  Fster is beter, but can acuse datra loss

% Other settings
Nthreshold = 2E6; % Counts to trigger an analuysis acquisition

% Other internal variables
Nimg_sum=0;
Zimg=zeros(1024,1280);
data=struct;
doForce=0;
%% Libraries 
% Location of the DCC driver DLL
dllStr='C:\Program Files\Thorlabs\Scientific Imaging\DCx Camera Support\Develop\DotNet\uc480DotNet.dll';

% Load the DLL
NET.addAssembly(dllStr);


% Initialize the Camera
cam = uc480.Camera;
cam.Init(0);



%% Initialize Figures

% Main GUI figure
hf=figure;
hf.Color='w';
hf.CloseRequestFcn=@closeMain;
hf.Name=guiname;
hf.Tag='GUI';



%%%%%%%%%%%%%%%%%% Live feed
subplot(4,1,[1 2 3]);
hImg=imagesc(zeros(1024,1280));
colorbar
tFPS=text(2,2,'beep','units','pixels','verticalalignment','bottom','color','red','fontweight','bold');
tSettings=text(2,20,'beep','units','pixels','verticalalignment','bottom','color','red','fontweight','bold');

% Live PD counts
subplot(4,1,4)
pLive=plot(now,1);
xlabel('time (seconds)');
ylabel('counts');





%% Image Figure
hf2=figure;
hf2.Color='w';
hf2.CloseRequestFcn=@closeSecondary;
hf2.Name='DCC Image';
hf2.Tag='GUI';

% Image subplot
subplot(5,5,[1 2 3 4 6 7 8 9 11 12 13 14 16 17 18 19]);
hImg2=imagesc(Zimg);


tLbl=text(5,5,'beep','color','red','fontweight','bold','margin',1,...
    'backgroundcolor',[ 1 1 1 .5],'units','pixels',...
    'verticalalignment','bottom','interpreter','none','fontsize',8);

% X Cut plot
subplot(5,5,[21 22 23 24]);
pXCut=plot(1,1,'k-');
xlim([1 1280]);

% Y cut plot
subplot(5,5,[5 10 15 20]);
pYCut=plot(1,1,'k-');
set(gca,'YDir','reverse');
ylim([1 1024]);


ax_tmp=subplot(5,5,25);
pp=ax_tmp.Position;
delete(ax_tmp);

hpWrap=uipanel('units','normalized','BorderType','none','backgroundcolor','w');
hpWrap.Position=pp;

tSet=uitable('parent',hpWrap,'ColumnName',{'Xi','Yi'},'RowName',{});
tSet.ColumnWidth={30 30};
tSet.ColumnEditable=[true true];
tSet.ColumnFormat={'numeric','numeric'};
tSet.Units='pixels';
tSet.Data=[635 505];
tSet.Position(1:2)=[1 1];
tSet.Position(3:4)=tSet.Extent(3:4);
tSet.CellEditCallback=@chInd;


% Force button
ttstr='Force acquisition';
uicontrol('style','pushbutton','String','force','callback',@forceCB,...
    'backgroundcolor','w','tooltipstring',ttstr,...
    'Position',[1 2 50 20]);
    function forceCB(~,~)
        doForce=1;
    end

% Save button
ttstr='Select directory to save images.';
cdata=imresize(imread(fullfile(mpath,'icons','save.jpg')),[20 20]);
uicontrol('style','pushbutton','CData',cdata,'callback',@saveCB,...
    'backgroundcolor','w','position',[52 2 size(cdata,[1 2])],...
    'tooltipstring',ttstr);

    function saveCB(~,~)
        saveDir = uigetdir(getDayDir);
        if saveDir
            saveData(data,saveDir);
        end
    end

% Auto Save check box
ttstr=['poop'];
hcacq=uicontrol('style','checkbox','string','auto acquire?','fontsize',8,...
    'backgroundcolor','w','Position',[85 20 90 25],'value',0,...
    'ToolTipString',ttstr);


% Auto Save check box
ttstr=['Enable/Disable automatic saving to external directory. Does ' ...
    'not override saving to image history.'];
hcsave=uicontrol('style','checkbox','string','save images?','fontsize',8,...
    'backgroundcolor','w','Position',[85 0 90 25],'callback',@saveCheck,...
    'ToolTipString',ttstr);

% Save checkbox callback
    function saveCheck(src,~)
        if src.Value
            tSaveDir.Enable='on';
            bBrowse.Enable='on';
        else
            tSaveDir.Enable='off';
            bBrowse.Enable='off';
        end
    end
% Browse button
ttstr='Select directory to save images.';
cdata=imresize(imread(fullfile(mpath,'icons','browse.jpg')),[20 20]);
bBrowse=uicontrol('style','pushbutton','CData',cdata,'callback',@browseCB,...
    'enable','off','backgroundcolor','w','position',[180 2 size(cdata,[1 2])],...
    'tooltipstring',ttstr);

% String for current save directory
ttstr='The current save directory.';
tSaveDir=uicontrol('style','text','string','save directory','fontsize',8,...
    'backgroundcolor','w','units','pixels','horizontalalignment','left',...
    'enable','off','UserData','','Position',[205 0 hf2.Position(3)-135 20],...
    'tooltipstring',ttstr);



% Browse button callback
    function browseCB(~,~)
        str=getDayDir;
        str=uigetdir(str);
        
        if str
            tSaveDir.UserData=str; % Full directory to save
            str=strsplit(str,filesep);
            str=[str{end-1} filesep str{end}];
            tSaveDir.String=str; % display string
        else
            disp('no directory chosen!');
        end
    end

%% Initialize Camera

ta=now;
tb=now;
acq=false;

try
    % Get Camera Information
    [~,nfo]=cam.Information.GetSensorInfo;
    disp([' Sensor ID           : ' char(nfo.SensorID)]);
    disp([' Sensor Name         : ' char(nfo.SensorName)]);
    disp([' Pixel Size          : ' num2str(nfo.PixelSize)]);

    % Configure camera
    cam.Display.Mode.Set(uc480.Defines.DisplayMode.DiB);
    cam.PixelFormat.Set(uc480.Defines.ColorMode.Mono16);
    cam.Trigger.Set(uc480.Defines.TriggerMode.Software); 

    % Camera Gain
    cam.Gain.Hardware.Boost.SetEnable(false);
    cam.Gain.Hardware.Factor.SetMaster(0);
    cam.Gain.Hardware.Scaled.SetMaster(0);

    % Camera Gain
    [~,mgain_factor]=cam.Gain.Hardware.Factor.GetMaster;
    disp([' Master Gain Factor  : ' num2str(mgain_factor)]);         
    [~,mgain_scale]=cam.Gain.Hardware.Scaled.GetMaster;
    disp([' Master Gain Scale   : ' num2str(mgain_scale)]);  

    % Pixel CLock
    [~,PixelClockRange]=cam.Timing.PixelClock.GetRange;
     cam.Timing.PixelClock.Set(px_clck);
    [~,PixelClock_read]=cam.Timing.PixelClock.Get;    
    disp([' Pixel Clock Range   : [' num2str(PixelClockRange.Minimum) ', ' num2str(PixelClockRange.Maximum) '] MHz']);
    disp([' Pixel Clock         : ' num2str(PixelClock_read) ' MHz']);

    % Exposure Timing
    [~,ExpRange]=cam.Timing.Exposure.GetRange;
    cam.Timing.Exposure.Set(texp);
    [~,texp_read]=cam.Timing.Exposure.Get;        
    disp([' Exposure Time Range : [' num2str(ExpRange.Minimum) ', ' num2str(ExpRange.Maximum) '] ms']);
    disp([' Exposure Time       : ' num2str(texp_read) ' ms']);

    % Update Settings String
    tSettings.String=[num2str(PixelClock_read) ' MHz, ' num2str(texp_read) ' ms, ' num2str(mgain_scale) ' gain'];

    % Allocate memory for images
    [~,memID]=cam.Memory.Allocate(true);
    
    % Get image specs
    [~,Width,Height,Bits,~]=cam.Memory.Inquire(memID);
    
    % Make Timer
    liveTimer=timer('Name','liveTimer','executionmode','fixedspacing',...
        'period',0.001,'TimerFcn',@updateFcn);
    set(pLive,'XData',[],'YData',[]);
    t0=now;      
     start(liveTimer)
catch ME
    keyboard      
end


function updateFcn(~,~)
    try
        % Get Data        
        cam.Acquisition.Freeze(uc480.Defines.DeviceParameter.Wait);
        [~,tmp]=cam.Memory.CopyToArray(memID);  

        % Reshape the data        
        Zlive=reshape(uint8(tmp),[Bits/8,Width,Height]); 
        Zlive=Zlive(1,:,:);
        Zlive=permute(Zlive,[3 2 1]);         
        Nsum=sum(sum(Zlive));

        % Update live image
        hImg.CData=Zlive;    

        % Reset live plot if too many points
        if length(pLive.XData)>1000
            t0=now;
            set(pLive,'XData',0,'YData',sum(sum(Zlive)));
        else          
            set(pLive,'XData',[pLive.XData 60*60*24*(now-t0)],...
                'YData',[pLive.YData sum(sum(Zlive))]);              
        end
    
        % Does the current image meet the threshold for analysis?
        if ((Nsum>Nthreshold) && hcacq.Value) || doForce
           acq=true;
           % Keep track of the brightness image during the acquisition
           if Nsum>Nimg_sum
                Zimg=Zlive;
                Nimg_sum=Nsum;
           end
           doForce=0;
        else
            % Update when you are below threshold but after acquiring
            if acq
                data=updateAnalysis(Zimg);                 
                if hcsave.Value
                    saveData(data,tSaveDir.UserData)
                end
            end            
            Nimg_sum=0;   
            acq=false;
        end       
        drawnow;
        
        % Update frame rate
        tb=now;
        dt=(tb-ta)*24*60*60;
        tFPS.String=[num2str(round(1/dt,1)) ' fps, ' num2str(Nsum,'%.3e')];
        ta=tb;
    catch mE        
        warning('bad acquistion');
        warning(mE.message);
    end

end

    function data=updateAnalysis(Z)        
        t=now;
        str=['DCC_' datestr(t,'yyyy-mm-dd_HH-MM-SS')];
        
        data=struct;
        data.Name=str;
        data.Date=datestr(t);
        data.Data=Z;
        data.PixelClock=PixelClock_read;
        data.Gain=mgain_scale;
        data.ExposureTime=texp_read;   
        
        [data.Params,data.Units,data.Flags]=grabSequenceParams2;

        tLbl.String=str;
        
        
        
        hImg2.CData=Z;   
        set(pXCut,'XData',1:Width,'YData',Z(tSet.Data(1,2),:));
        set(pYCut,'XData',Z(:,tSet.Data(1,1)),'YData',1:Height);
        drawnow;               
    end

    % Close request function for the main GUI
    function closeMain(~,~)    
        if exist('liveTimer') && isequal(liveTimer.Running,'on')
            stop(liveTimer);
            closeMain;
        else    
            try
                delete(liveTimer);
            catch exception
                warning('Unable to delete timer.');
            end
            delete(hf);
            delete(hf2);
            cam.Exit;
        end
    end


    function chInd(src,evt)
      set(pXCut,'XData',1:Width,'YData',hImg2.CData(tSet.Data(1,2),:));
      set(pYCut,'XData',hImg2.CData(:,tSet.Data(1,1)),'YData',1:Height);
    end


end
% Close request function for the secnodary GUI

function closeSecondary(~,~)
   warning('Close this figure by closing the acquisition GUI.');
end

function saveData(data,saveDir)
    filename=[data.Name '.mat']; 
    if ~exist(saveDir,'dir')
       mkdir(saveDir);
    end      

    filename=fullfile(saveDir,filename);
    fprintf('%s',[filename ' ...']);
    save(filename,'data');
    disp(' done'); 
end
    
function s3=getDayDir
    t=now;
    
    d=['Y:\Data'];

    if ~exist(d,'dir')
        s3=pwd;
        return;
    end
    s1=datestr(t,'yyyy');s2=datestr(t,'yyyy.mm');s3=datestr(t,'mm.dd');
    s1=[d filesep s1];s2=[s1 filesep s2];s3=[s2 filesep s3];

    if ~exist(s1,'dir'); mkdir(s1); end
    if ~exist(s2,'dir'); mkdir(s2); end
    if ~exist(s3,'dir'); mkdir(s3); end
end

function [vals,units,flags]=grabSequenceParams2(src)
    if nargin~=1
        src='Y:\_communication\control2.mat';
    end    
    data=load(src);    
    disp(['Opening information from from ' src]);
    vals=data.vals;
    units=data.units;   
    flags=data.flags;
end
