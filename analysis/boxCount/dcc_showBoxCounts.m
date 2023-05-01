function [hF,outdata]=dcc_showBoxCounts(dcc_data,xVar,opts)
% Grab important global variables
global dcc_imgdir

%% Sort the data by the parameter given
params=[dcc_data.Params];
xvals=[params.(xVar)];

[xvals,inds]=sort(xvals,'ascend');
dcc_data=dcc_data(inds);

%% Grab the gaussian fit outputs
for kk=1:length(dcc_data)
   for nn=1:size(dcc_data(kk).ROI,1)
        BC=dcc_data(kk).BoxCount(nn);         % Grab the box count
        Xc(kk,nn)=BC.Xc;Yc(kk,nn)=BC.Yc;        % X and Y center
        Xs(kk,nn)=BC.Xs;Ys(kk,nn)=BC.Ys;        % X and Y sigma   
        Zs(kk,nn)=BC.Ys;                          % ASSUME sZ=sY;                
        nbg(kk,nn)=BC.Nbkgd;                        % Background
        N(kk,nn)=BC.Ncounts;
   end        
end

%% Outdata

outdata=struct;
outdata.xVar=xVar;
outdata.X=xvals;
outdata.Ncounts=N;


%% Make Figure


% Create the name of the figure
[filepath,name,~]=fileparts(dcc_imgdir);

figDir=fullfile(dcc_imgdir,'figures');
if ~exist(figDir,'dir')
   mkdir(figDir); 
end

strs=strsplit(dcc_imgdir,filesep);
str=[strs{end-1} filesep strs{end}];

hF=figure('Name',[pad('DCC Box Count',20) str],...
    'units','pixels','color','w','Menubar','none','Resize','off',...
    'numbertitle','off');
hF.Position(1)=1;
hF.Position(2)=50;
hF.Position(3)=400;
hF.Position(4)=400;
clf
drawnow;


% Make axis
hax=axes;
set(hax,'box','on','linewidth',1,'fontsize',12,'units','pixels');
hold on
xlabel([xVar ' (' opts.xUnit ')'],'interpreter','none');
ylabel('box counts');

hax.Position(4)=hax.Position(4)-20;

co=get(gca,'colororder');

for nn=1:size(dcc_data(1).ROI,1)
   plot(xvals,N(:,nn),'o','color',co(nn,:),'linewidth',1,'markersize',8,...
       'markerfacecolor',co(nn,:),'markeredgecolor',co(nn,:)*.5);
end




% Image directory folder string
t=uicontrol('style','text','string',str,'units','pixels','backgroundcolor',...
    'w','horizontalalignment','left','fontsize',6);
t.Position(4)=t.Extent(4);
t.Position(3)=hF.Position(3);
t.Position(1:2)=[5 hF.Position(4)-t.Position(4)];

end

