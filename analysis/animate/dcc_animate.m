function dcc_animate(dcc_data,xVar,opts)

clim=opts.CLim;
global dcc_imgdir

% Default is to snap to minimum ROI
aROI=[min(dcc_data(1).ROI(:,1)) max(dcc_data(1).ROI(:,2)) ...
    min(dcc_data(1).ROI(:,3)) max(dcc_data(1).ROI(:,4))];

%% Animation Settings
startDelay=opts.StartDelay;   % First picture hold time
midDelay=opts.MidDelay;   % Middle pictures hold time
endDelay=opts.EndDelay;     % End picture hold time

strs=strsplit(dcc_imgdir,filesep);
str=[strs{end-1} filesep strs{end}];
%% Make Filename
filename='animate';

% Create the name of the figure
[filepath,name,~]=fileparts(dcc_imgdir);

figDir=fullfile(dcc_imgdir,'figures');
if ~exist(figDir,'dir')
   mkdir(figDir); 
end

% Make the figure name with the location
filename=fullfile(figDir,[filename '.gif']);

%% Calculate Figure sizes
% grab initial data
Z=dcc_data(1).Data;
Y=1:size(Z,1);
X=1:size(Z,2);

% long dimennion of figure
L1=500;


if size(Z,1)>size(Z,2) 
   W=L1;
   H=L1*size(Z,1)/size(Z,2);
else
   H=L1;
   W=L1*size(Z,2)/size(Z,1);
end

%% Initialize Graphics

hF=figure('Name',[str ' : DCC Animate Cloud'],...
    'units','pixels','color','w','Menubar','none','Resize','off',...
    'WindowStyle','modal');
hF.Position(1)=10;
hF.Position(2)=5;
hF.Position(3)=W;
hF.Position(4)=H;
drawnow;

% Image directory folder string
t=uicontrol('style','text','string',str,'units','pixels','backgroundcolor',...
    'w','horizontalalignment','left');
t.Position(4)=t.Extent(4);
t.Position(3)=hF.Position(3);
t.Position(1:2)=[5 hF.Position(4)-t.Position(4)];

% Axes for data
hAxImg=subplot(5,5,[1 2 3 4 6 7 8 9 11 12 13 14 16 17 18 19]);
set(hAxImg,'Box','on','XGrid','on',...
    'YGrid','on','YDir','reverse','XAxisLocation','bottom',...
    'units','normalized');
drawnow;
% Text label for folder name
tt=text(0,.98,str,'units','normalized','fontsize',8,'color','r',...
    'interpreter','none','verticalalignment','cap',...
    'fontweight','bold','margin',1,'backgroundcolor',[1 1 1 .5]);
% Text label for variable name
t=text(5,5,'hi','units','pixels','fontsize',14,'color','r',...
    'interpreter','none','verticalalignment','bottom',...
    'fontweight','bold');
colormap(parula)
hold on
hImg=imagesc(X,Y,Z);
axis equal tight
caxis(clim);
co=get(gca,'colororder');

xlim(aROI(1:2));
ylim(aROI(3:4));


plot(get(gca,'XLim'),[1 1]*opts.YCut,'r--');
plot([1 1]*opts.XCut,get(gca,'YLim'),'r--');

hold on
cc=colorbar;

set(gca,'units','pixels','box','on','linewidth',2);


% Add ROI boxes
for kk=1:size(dcc_data(1).ROI,1)
    ROI=dcc_data(1).ROI(kk,:);    
 
    x0=ROI(1);
    y0=ROI(3);
    H=ROI(4)-ROI(3);
    W=ROI(2)-ROI(1);
    pROI=rectangle('position',[x0 y0 W H],'edgecolor',co(kk,:),'linewidth',2);
end
drawnow;

% Y Cut
axy=subplot(5,5,[5 10 15 20]);
% axy.Units
% axy.Position(4)=hAxImg.Position(4)/2;
set(axy,'box','on','linewidth',1,'xgrid','on','ygrid','on',...
    'ydir','reverse');
py=plot(0,0,'k-');

% X Cut
axx=subplot(5,5,[21 22 23 24]);
set(axx,'box','on','linewidth',1,'xgrid','on','ygrid','on',...
    'ydir','normal');
px=plot(0,0,'k-');



%% Average data

% Get the x variable
params=[dcc_data.Params];
xvals=[params.(xVar)];

direction=opts.Order;

if isequal(direction,'ascend')
    [~,inds]=sort(xvals,'ascend');
else
    [~,inds]=sort(xvals,'descend');
end

dcc_data=dcc_data(inds);

params=[dcc_data.Params];
xvals=[params.(xVar)];

% Find and sor the unique values
uxvals=unique(xvals);

if isequal(direction,'ascend')
    uxvals=sort(uxvals,'ascend');
else
    uxvals=sort(uxvals,'descend');
end

params=[dcc_data.Params];
xvals=[params.(xVar)];


Zs=zeros(size(dcc_data(1).Data,1),size(dcc_data(1).Data,2),length(uxvals));

for kk=1:length(uxvals) % Iterate over unique x values
    
    % Find the indeces which have this unique value
    inds=find(uxvals(kk)==[params.(xVar)]);
    
    for ii=1:length(inds)
        ind=inds(ii);
        Z=double(dcc_data(ind).Data);
        Zs(:,:,kk)=Zs(:,:,kk)+Z;        
    end        
    Zs(:,:,kk)=Zs(:,:,kk)/length(inds);   
end



%% Animate

for kk=1:length(uxvals)   % Iterate over all unique xvalues
    
    %%%% Update the graphics
    t.String=[xVar ' = ' num2str(uxvals(kk))];          % Variable string
    

    set(hImg,'XData',X,'YData',Y,'CData',Zs(:,:,kk));  % Image data
    set(py,'XData',Zs(:,opts.XCut,kk),'YData',ROI(3):ROI(4));
    set(px,'YData',Zs(opts.YCut,:,kk),'XData',ROI(1):ROI(2));

%     set(gca,'XDir','normal','YDir','Reverse');
    
    drawnow % update graphcis
    
    
    % Write the image data
    frame = getframe(hF);
    im = frame2im(frame);
    [A,map] = rgb2ind(im,256);           

    if kk == 1
        imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',startDelay);
    else
        if kk==length(uxvals)
            imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',endDelay);
        else
            imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',midDelay);
        end
    end

end
close;
    
end

