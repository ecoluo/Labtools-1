function SimulatedData()

warning off MATLAB:divideByZero;
warning off MATLAB:singularMatrix;

clear;clc
timestep=0.1;
x = ([0 45 90 135 180 225 270 315 360]*pi/180)'; % for fitting
t = 0:timestep:2.5; 

clear global rawdata xdata tdata
global rawdata xdata tdata

for i = 1:length(t)
    xdata(:, i) = x;    
end
for i = 1:length(x)
    tdata(i,:) = t;
end
xtdata = [xdata; tdata];

clear vect;vect=[13.8 92.4  0.1  2.3  1.099   0.199  0.4   0.2   2.1  0.8 1.9  0];

global model_use 
model_use=2;
spacetime_data = funccosnlin(vect,xtdata);
rawdata=spacetime_data;


FigureIndex=2; 
figure(FigureIndex);set(FigureIndex,'Position', [50,50 1200,600], 'Name', 'CurveFitting');orient landscape; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Adding some noise to samples drawn from the 3D curve.
Amp = max(max(spacetime_data)) - min(min(spacetime_data));
noisy_data=spacetime_data;% 
noisy_data = spacetime_data + .2*Amp*rand(size(spacetime_data));
% noisy_data(noisy_data<0)=0.001;

clear XAzi Ytime;[XAzi,Ytime] = meshgrid([0:45:360],[0:timestep:max(t)]);
figure(FigureIndex);axes('position',[0.05 0.77 0.17 0.15]);  
contourf(XAzi,Ytime,noisy_data');colorbar;    
set(gca, 'xtick', [] );set(gca, 'XTickMode','manual'); 
set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
set(gca, 'ytick',[0:0.5:max(t)]);
set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
xlabel('Azimuth, X (deg)');  ylabel('Time (sec)');
title('Noisy data');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global model_use
model_use=1;
[spacefit_Vel,vect_Vel,r_squared_Vel,CI_Vel] = MSF_Vel_fit(noisy_data,timestep,1);

figure(FigureIndex);axes('position',[0.05 0.53 0.17 0.15]);
contourf(XAzi,Ytime,spacefit_Vel',10);colorbar;    
set(gca, 'xtick', [] );set(gca, 'XTickMode','manual'); 
set(gca, 'xtick',[0:90:315]);set(gca, 'xticklabel','0|90|180|270');
set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
set(gca, 'ytick',[0:0.5:max(t)]);
set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
%xlabel('Azimuth, X (deg)');  
ylabel('Time (sec)');title('model: Vel  ');

error_surf = noisy_data - spacefit_Vel;
err_Vel = cosnlin_err(vect_Vel);
figure(FigureIndex);axes('position',[0.26 0.53 0.17 0.15]);%subplot('position', [0.1 0.7 0.22 0.22]);
contourf(XAzi,Ytime,error_surf'); colorbar;    
set(gca, 'xtick', [] );set(gca, 'XTickMode','manual'); 
set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
set(gca, 'ytick',[0:0.5:max(t)]);
set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% xlabel('Azimuth, X (deg)');  ylabel('Time (sec)');
axis off;
title({[ 'Err: ' num2str(err_Vel, '%0.2f') ]},  'FontSize', 10);

%Do the chi-square goodness of fit test
clear DataDiff;DataDiff=noisy_data-spacefit_Vel;
uncertainty=noisy_data;
clear sd_zero;sd_zero=find(uncertainty<0.1);uncertainty(sd_zero)=NaN;
dof_Vel=(size(noisy_data,1)-1)*(size(noisy_data,2)-1)-length(sd_zero)-length(vect_Vel);%degree of freedom
chi2_Vel=sum(nansum( (DataDiff.^2)./(uncertainty.^2)));
RChi2_Vel = chi2_Vel/dof_Vel;%Reduced Chi-Squared value
chi2P_Vel=1-chi2cdf(chi2_Vel,dof_Vel);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model_use=2;
[spacefit_VelAcc,vect_VelAcc,r_squared_VelAcc,CI_VelAcc] = MSF_VelAcc_fit(noisy_data, vect_Vel,timestep,1);
figure(FigureIndex);axes('position',[0.05 0.31 0.17 0.15]);
contourf(XAzi,Ytime,spacefit_VelAcc');colorbar;    
set(gca, 'xtick', [] );set(gca, 'XTickMode','manual'); 
set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
set(gca, 'ytick',[0:0.5:max(t)]);
set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
%xlabel('Azimuth, X (deg)');  
ylabel('Time (sec)');title('model: Vel + Acc ');

error_surf = noisy_data - spacefit_VelAcc;%current_err = cosnlin_err(vect_VelAcc);
err_VelAcc = cosnlin_err(vect_VelAcc);
figure(FigureIndex);axes('position',[0.26 0.31 0.17 0.15]);
contourf(XAzi,Ytime,error_surf'); colorbar;   
set(gca, 'xtick', [] );set(gca, 'XTickMode','manual'); 
set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
set(gca, 'ytick',[0:0.5:max(t)]);
set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% xlabel('Azimuth, X (deg)');  ylabel('Time (sec)');
axis off;
title({[ 'Err1: ' num2str(err_VelAcc, '%0.2f') ]},  'FontSize', 10);% axis off;

%Do the chi-square goodness of fit test
clear DataDiff;DataDiff=noisy_data-spacefit_VelAcc;
uncertainty=noisy_data;
clear sd_zero;sd_zero=find(uncertainty<0.1);uncertainty(sd_zero)=NaN;
dof_VelAcc=(size(noisy_data,1)-1)*(size(noisy_data,2)-1)-length(sd_zero)-length(vect_VelAcc);%degree of freedom
chi2_VelAcc=sum(nansum( (DataDiff.^2)./(uncertainty.^2)));
RChi2_VelAcc = chi2_VelAcc/dof_VelAcc;%Reduced Chi-Squared value
chi2P_VelAcc=1-chi2cdf(chi2_VelAcc,dof_VelAcc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model_use=3;
[spacefit_VelAccPos,vect_VelAccPos,r_squared_VelAccPos,CI_VelAccPos] = MSF_VelAccPos_fit(noisy_data, vect_VelAcc,timestep,1);
figure(FigureIndex);axes('position',[0.05 0.09 0.17 0.15]);%subplot('position', [0.1 0.7 0.22 0.22]);
contourf(XAzi,Ytime,spacefit_VelAccPos',10);colorbar;    
set(gca, 'xtick', [] );set(gca, 'XTickMode','manual'); 
set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
set(gca, 'ytick',[0:0.5:max(t)]);
set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
xlabel('Azimuth, X (deg)'); 
ylabel('Time (sec)');title('model: Vel + Acc + Pos');

error_surf = noisy_data - spacefit_VelAccPos;%current_err = cosnlin_err(vect_VelAccPos);
err_VelAccPos = cosnlin_err(vect_VelAccPos);
figure(FigureIndex);axes('position',[0.26 0.09 0.17 0.15]);
contourf(XAzi,Ytime,error_surf'); colorbar;   
set(gca, 'xtick', [] );set(gca, 'XTickMode','manual'); 
set(gca, 'xtick',[0:45:315]);set(gca, 'xticklabel','0|45|90|135|180|215|270|315');
set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
set(gca, 'ytick',[0:0.5:max(t)]);
set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
axis off; %xlabel('Azimuth, X (deg)');  ylabel('Time (sec)');
title({[ 'Err: ' num2str(err_VelAccPos, '%0.2f') ]},  'FontSize', 10);% axis off;

%Do the chi-square goodness of fit test
clear DataDiff;DataDiff=noisy_data-spacefit_VelAccPos;
uncertainty=noisy_data;
clear sd_zero;sd_zero=find(uncertainty<0.1);uncertainty(sd_zero)=NaN;
dof_VelAccPos=(size(spacetime_data,1)-1)*(size(spacetime_data,2)-1)-length(sd_zero)-length(vect_VelAccPos);%degree of freedom
chi2_VelAccPos=sum(nansum( (DataDiff.^2)./(uncertainty.^2)));
RChi2_VelAccPos = chi2_VelAccPos/dof_VelAccPos;%Reduced Chi-Squared value
chi2P_VelAccPos=1-chi2cdf(chi2_VelAccPos,dof_VelAccPos);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out=[];
out = 'CurveFitting:    R0 |  Amp  |  n  | muAzi |  muT  | sigmaT |  DC2  | wVel  |ThetaAcc|  wAcc | ThetaPos | wPos'; 
out = strvcat(out, sprintf('------------------------------------------------------------------------------------------------------------'));    
clear OutputValue;OutputValue=vect_Vel;
OutputValue(4)=OutputValue(4)*180/pi;
out=strvcat(out, sprintf('Vel Model:     %4.1f | %5.1f |%4.1f |%6.1f | %4.3f | %6.3f |%6.3f', OutputValue));

clear OutputValue;OutputValue=vect_VelAcc;
OutputValue(4)=OutputValue(4)*180/pi;
OutputValue(9)=OutputValue(9)*180/pi;
out=strvcat(out, sprintf('Vel+Acc Model: %4.1f | %5.1f |%4.1f |%6.1f | %4.3f | %6.3f |%6.3f |%6.3f | %6.1f  ', OutputValue));

clear OutputValue; OutputValue=vect_VelAccPos;
OutputValue(4)=OutputValue(4)*180/pi;
OutputValue(9)=OutputValue(9)*180/pi;
OutputValue(11)=OutputValue(11)*180/pi;
out=strvcat(out, sprintf('Vel+Acc+Pos  : %4.1f | %5.1f |%4.1f |%6.1f | %4.3f | %6.3f |%6.3f |%6.3f | %6.1f |%6.3f | %6.1f   |%6.3f', OutputValue)); 
figure(FigureIndex);axes('position',[0.26 0.74 0.25 0.25]); set(gca,'box','off','visible','off');
text(-0.08,1,out,'fontsize',8,'fontname','courier','horizontalalignment','left','verticalalignment','top');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ftest_1vs2=[(err_Vel-err_VelAcc)/(length(vect_VelAcc)-length(vect_Vel))]/[err_VelAcc/(size(spacetime_data,1)*size(spacetime_data,2)-length(vect_Vel))];
p_1vs2=1-fcdf(Ftest_1vs2,length(vect_VelAcc)-length(vect_Vel),size(spacetime_data,1)*size(spacetime_data,2)-length(vect_Vel));

Ftest_2vs3=[(err_VelAcc-err_VelAccPos)/(length(vect_VelAccPos)-length(vect_VelAcc))]/[err_VelAccPos/(size(spacetime_data,1)*size(spacetime_data,2)-length(vect_VelAcc))];
p_2vs3=1-fcdf(Ftest_2vs3,length(vect_VelAccPos)-length(vect_VelAcc),size(spacetime_data,1)*size(spacetime_data,2)-length(vect_VelAcc));

out=[];
out = 'Goodness of fitting:  r2 (Vel) | r2 (VelAcc)| r2 (VelAccPos) | Ftest(1vs2) | p(1vs2)  | Ftest(2vs3) | p(2vs3)'; 
out = strvcat(out, sprintf('--------------------------------------------------------------------------------------------------------'));    
clear OutputValue;OutputValue=[r_squared_Vel r_squared_VelAcc r_squared_VelAccPos Ftest_1vs2 p_1vs2 Ftest_2vs3 p_2vs3];
out=strvcat(out, sprintf('                        %6.3f |    %6.3f  |      %6.3f    |   %6.3f   |  %6.3f  |   %6.3f    |  %6.3f   ', OutputValue));
figure(FigureIndex);axes('position',[0.26 0.65 0.25 0.25]); set(gca,'box','off','visible','off');
text(-0.08,1,out,'fontsize',8,'fontname','courier','horizontalalignment','left','verticalalignment','top');

out=[];
out = 'Goodness of fitting: Chi2(Vel) | ChiP(Vel) | Chi2(VelAcc) | ChiP(VelAcc) | Chi2(VelAccPos)  | ChiP(VelAccPos) '; 
out = strvcat(out, sprintf('--------------------------------------------------------------------------------------------------------'));    
clear OutputValue;OutputValue=[chi2_Vel chi2P_Vel chi2_VelAcc chi2P_VelAcc chi2_VelAccPos chi2P_VelAccPos];
out=strvcat(out, sprintf('                    %8.3f  |   %6.3f  |   %8.3f   |   %6.3f     | %8.3f         |   %6.3f    ', OutputValue));
figure(FigureIndex);axes('position',[0.26 0.59 0.25 0.25]); set(gca,'box','off','visible','off');
text(-0.08,1,out,'fontsize',8,'fontname','courier','horizontalalignment','left','verticalalignment','top');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% order in which the directions are plotted
plot_col = [1 1 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8];
plot_row = [5 4 3 2 1 4 3 2 4 3 2 4 3 2 4 3 2 4 3 2 4 3 2 4 3 2];

x_start = [0, 0];
x_stop =  [2, 2];
y_marker=[0,1.1*max(max(spacetime_data))];

xscale = [0.8 0.77 0.65 0.52 0.5 0.52 0.65 0.77];   
yscale = [0.35 0.5 0.65 0.5 0.35 0.2 0.05 0.2];

%x_time=[1:size(PSTH_tempPlane,2)]*0.02-0.5;
%clear x_time;x_time=[1:size(spacetime_data,2)]*0.02;
clear x_time;x_time=t;

UniAzi=[0:45:315];
for i=1:8
    i
    axes('position',[xscale(i) yscale(i) 0.16 0.10]);
%     bar(x_time,PSTH_tempPlane(i,:));hold on;%bar(x_time, count_y{i,j,k});    hold on;
    
    plot(x_time,spacefit_Vel(i,:),'r','LineWidth',2);hold on;    
    plot(x_time,spacefit_VelAcc(i,:), 'g', 'LineWidth', 2);hold on;
    plot(x_time,spacefit_VelAccPos(i,:),'c','LineWidth',2);hold on;
    
     xlim([0,2.5]);    ylim([0,1.2*max(max(spacetime_data))]);
    
    set(gca, 'xtick', [] );set(gca, 'XTickMode','manual'); 
    set(gca, 'xtick',[0:0.5:2.5]);
    set( gca, 'xticklabel', '0|0.5|1|1.5|2|2.5');
    set( gca, 'yticklabel', ' ' );
    title({['azi = ' num2str(UniAzi(i))]}, 'FontSize', 8);
end  






