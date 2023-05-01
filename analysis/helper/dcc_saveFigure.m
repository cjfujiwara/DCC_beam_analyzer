function dcc_saveFigure(dcc_data,hF,filename)
global dcc_imgdir

ext='.png';
save_qual='-r120';


% The directory where the figures are saved
figDir=fullfile(dcc_imgdir,'figures');
if ~exist(figDir,'dir')
   mkdir(figDir); 
end

% Create the name of the figure
[filepath,name,~]=fileparts(dcc_imgdir);


% Make the figure name with the location
saveLocation=fullfile(figDir,[filename ext]);
% saveLocation='C:

% Save the figure and the png
fprintf([datestr(now,13) ' Saving figure handle to ']);
fprintf([filename ext ' ... ']);
set(0,'CurrentFigure', hF);
set(hF,'PaperPositionMode','auto');
print('-dpng',save_qual,saveLocation);
disp('Saved!');

% savefig(the_figure,saveLocation);
end

