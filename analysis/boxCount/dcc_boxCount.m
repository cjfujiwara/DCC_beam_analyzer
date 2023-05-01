function dcc_data=dcc_boxCount(dcc_data,bgROI)

    fprintf('Performing box count analysis ...');    
    if nargin==1
        disp(' No background ROI provided, will assume background of zero.');
        bgROI=[];
    else
        disp([' Using background counts from ROI = [' ...
            num2str(bgROI) ']']);        
    end    
    

    for kk=1:length(dcc_data)

        BoxCount=struct;    
        for k=1:size(dcc_data(kk).ROI,1)
            ROI=dcc_data(kk).ROI(k,:);
            x=ROI(1):ROI(2);
            y=ROI(3):ROI(4);
           
            z=double(dcc_data(kk).Data(ROI(3):ROI(4),ROI(1):ROI(2)));
            nbg=0;
            
            if nargin==2
                zbg=double(dcc_data(kk).Data(bgROI(3):bgROI(4),bgROI(1):bgROI(2)));
                Nsum=sum(sum(zbg));
                nbg=Nsum/(size(zbg,1)*size(zbg,2)); % count density
            end    
            
            Nraw=sum(sum(z));
            Nbg=nbg*size(z,1)*size(z,2);  

            zNoBg=z-nbg;        
            Ncounts=sum(sum(zNoBg));   
            zY=sum(zNoBg,2)';
            zX=sum(zNoBg,1);
            
            zX(zX<0)=0;
            zY(zY<0)=0;

            % Calculate center of mass
            Xc=sum(zX.*x)/Ncounts;
            Yc=sum(zY.*y)/Ncounts; 

            % Calculate central second moment/variance and the standard
            % deviation
            X2=sum(zX.*(x-Xc).^2)/Ncounts; % x variance
            Xs=sqrt(X2); % standard deviation X
            Y2=sum(zY.*(y-Yc).^2)/Ncounts; % x variance
            Ys=sqrt(Y2); % standard deviation Y               

            BoxCount(k).Ncounts=Ncounts;    % Number of counts (w/ bkgd removed)
            BoxCount(k).Nraw=Nraw;          % Raw of number of counts
            BoxCount(k).Nbkgd=Nbg;          % Bakcground number of counts
            BoxCount(k).nbkgd=nbg;          % Background counts/px
            BoxCount(k).bgROI=bgROI;        % ROI for calculating bgkd
            BoxCount(k).Xc=Xc;              % X center of mass
            BoxCount(k).Yc=Yc;              % Y center of mass
            BoxCount(k).Xs=Xs;              % X standard deviation
            BoxCount(k).Ys=Ys;              % Y standard deviation
        end 
        
        dcc_data(kk).BoxCount=BoxCount;
    end
end
