% analyze eyetrace data
clear all
% choose protocol
%
% analyze_protocol = [1];%Que
% analyze_protocol = [2];%Azrael
analyze_protocol = [3];%Zebulon
% analyze_protocol = [4];% Purusuit


if analyze_protocol == [1]
    aa1 = dlmread('QueEye_Rot_Vet.dat','',1,1);dim=size(aa1)  % load data
    aa2 = dlmread('QueEye_Rot_Vis.dat','',1,1);dim=size(aa2)  % load data
    aa3 = dlmread('QueEye_Tra_Vet.dat','',1,1);dim=size(aa3)  % load data
    aa4 = dlmread('QueEye_Tra_Vis.dat','',1,1);dim=size(aa4)  % load data
%     [names] = textread('Eye_rot_ves.dat','%s',2)
%     filename=names(2);
   
elseif analyze_protocol == [2]
    aa1 = dlmread('AzraelEye_Rot_Vet.dat','',1,1);dim=size(aa1)  % load data
    aa2 = dlmread('AzraelEye_Rot_Vis.dat','',1,1);dim=size(aa2)  % load data
    aa3 = dlmread('AzraelEye_Tra_Vet.dat','',1,1);dim=size(aa3)  % load data
    aa4 = dlmread('AzraelEye_Tra_Vis.dat','',1,1);dim=size(aa4)  % load data
% %     aa = dlmread('Eye_rot_ves.dat','',1,1);  % load data
   
elseif analyze_protocol == [3]
%     aa3 = dlmread('ZebulonEye_Tra_vet.dat','',1,1);dim=size(aa3)  % load data
%     aa4 = dlmread('ZebulonEye_Tra_vis.dat','',1,1);dim=size(aa4)  % load data
    aa1 = dlmread('ZebulonEye_Rot_vet.dat','',1,1);dim=size(aa1)  % load data
    aa2 = dlmread('ZebulonEye_Rot_vis.dat','',1,1);dim=size(aa2)  % load data
%     aa = dlmread('Eye_rot_ves.dat','',1,1);  % load data
    
else
    aa = dlmread('Que_Pursuit_pursuit.dat','',1,1);  % load data 
%     aa = dlmread('Eye_rot_ves.dat','',1,1);  % load data
  
end

    title1 = ' Up    /';
    title2 = 'Down   /';
    title3 = 'Left   /';
    title4 = 'Right  /';
    
% mean for repeats cells...%Azuel no need
% aa3=aa3(:,1:22402);%Que 
% aa3=aa3(:,1:19202);%Zebulon or for Zebulon do not need

%%%%%%%%%%%%%%%%%%%%%% Select conditions !! %%%%%%%%%%%%%%%%
aa=aa1;p_title = 'Rot Vest';%Rot_Vet
% aa=aa2;p_title = 'Rot Visu';%Rot_Vis
% aa=aa3;p_title = 'Tra Vest';%Tra_Vet
% aa=aa4;p_title = 'Tra Visu';%Tra_Vis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

repeat = aa(:,1); % 1st column is repeatition, else are the raw eye trace
dim = size(aa)

% % definition for sum all cells (>300), {i}
%         res_x_up_sum(1,1:400) = 0;
%         res_y_up_sum(1,1:400) = 0;
%         res_x_down_sum(1,1:400) = 0;
%         res_y_down_sum(1,1:400)  = 0;
%         res_x_left_sum(1,1:400)  = 0;
%         res_y_left_sum(1,1:400)  = 0;
%         res_x_right_sum(1,1:400)  = 0;
%         res_y_right_sum(1,1:400)  = 0;
%         
%         vel_x_up_sum(1,1:399) = 0;
% %         vel_x_up_sum2(1,1:400) = 0;
%         vel_y_up_sum(1,1:399) = 0;
%         vel_x_down_sum(1,1:399) = 0;
%         vel_y_down_sum(1,1:399) = 0;
%         vel_x_left_sum(1,1:399) = 0;
%         vel_y_left_sum(1,1:399) = 0;
%         vel_x_right_sum(1,1:399) = 0;
%         vel_y_right_sum(1,1:399) = 0;
%         
%           vel_x_up_sum2(1,1:400) = 0;
% %         vel_x_up_sum2(1,1:400) = 0;
%         vel_y_up_sum2(1,1:400) = 0;
%         vel_x_down_sum2(1,1:400) = 0;
%         vel_y_down_sum2(1,1:400) = 0;
%         vel_x_left_sum2(1,1:400) = 0;
%         vel_y_left_sum2(1,1:400) = 0;
%         vel_x_right_sum2(1,1:400) = 0;
%         vel_y_right_sum2(1,1:400) = 0;
        
% reconstruct into matrixs
% 2 files on 1 figure

for i = 1 : dim(1)  % How many cells?
   
        res_x_up(i,:) = aa(i, 2:401);
        res_y_up(i,:) = aa(i, 402:801);
        res_x_down(i,:)= aa(i, 802:1201);
        res_y_down(i,:)= aa(i, 1202:1601);
        res_x_left(i,:) = aa(i, 1602:2001);
        res_y_left(i,:) = aa(i, 2002:2401);
        res_x_right(i,:) = aa(i, 2402:2801);
        res_y_right(i,:) = aa(i, 2802:3201);
        
        
        % Convert to velosity
        vel_x_up(i,:) = diff(res_x_up(i,:))*1000/5;
%         vel_x_up2{i}(j,:) = fderiv(res_x_up{i}(j,:),15,200);
        vel_y_up(i,:) = diff(res_y_up(i,:))*200;
        vel_x_down(i,:) = diff(res_x_down(i,:))*200;
        vel_y_down(i,:) = diff(res_y_down(i,:))*200;
        vel_x_left(i,:) = diff(res_x_left(i,:))*200;
        vel_y_left(i,:) = diff(res_y_left(i,:))*200;
        vel_x_right(i,:) = diff(res_x_right(i,:))*200;
        vel_y_right(i,:) = diff(res_y_right(i,:))*200;
        
               % Convert to velosity 2
        vel_x_up2(i,:) = fderiv(res_x_up(i,:),15,200);
%         vel_x_up2{i}(j,:) = fderiv(res_x_up{i}(j,:),15,200);
        vel_y_up2(i,:) = fderiv(res_y_up(i,:),15,200);
        vel_x_down2(i,:) = fderiv(res_x_down(i,:),15,200);
        vel_y_down2(i,:) = fderiv(res_y_down(i,:),15,200);
        vel_x_left2(i,:) = fderiv(res_x_left(i,:),15,200);
        vel_y_left2(i,:) = fderiv(res_y_left(i,:),15,200);
        vel_x_right2(i,:) = fderiv(res_x_right(i,:),15,200);
        vel_y_right2(i,:) = fderiv(res_y_right(i,:),15,200);
      

%         res_x_up_sum = res_x_up(i,:)+res_x_up_sum;
%         res_y_up_sum =  res_y_up(i,:)+res_y_up_sum;
%         res_x_down_sum = res_x_down(i,:)+res_x_down_sum;
%         res_y_down_sum = res_y_down(i,:)+res_y_down_sum ;
%         res_x_left_sum = res_x_left(i,:)+res_x_left_sum ;
%         res_y_left_sum = res_y_left(i,:)+res_y_left_sum;
%         res_x_right_sum = res_x_right(i,:)+res_x_right_sum ;
%         res_y_right_sum =  res_y_right(i,:)+res_y_right_sum;
%         
%         vel_x_up_sum = vel_x_up(i,:)+vel_x_up_sum;
%         vel_y_up_sum = vel_y_up(i,:)+vel_y_up_sum;
%         vel_x_down_sum = vel_x_down(i,:)+vel_x_down_sum;
%         vel_y_down_sum = vel_y_down(i,:)+vel_y_down_sum;
%         vel_x_left_sum = vel_x_left(i,:)+vel_x_left_sum;
%         vel_y_left_sum = vel_y_left(i,:)+vel_y_left_sum;
%         vel_x_right_sum = vel_x_right(i,:)+vel_x_right_sum;
%         vel_y_right_sum = vel_y_right(i,:)+vel_y_right_sum;
%         
%          vel_x_up_sum2 = vel_x_up2(i,:)+vel_x_up_sum2;
%         vel_y_up_sum2 = vel_y_up2(i,:)+vel_y_up_sum2;
%         vel_x_down_sum2 = vel_x_down2(i,:)+vel_x_down_sum2;
%         vel_y_down_sum2 = vel_y_down2(i,:)+vel_y_down_sum2;
%         vel_x_left_sum2 = vel_x_left2(i,:)+vel_x_left_sum2;
%         vel_y_left_sum2 = vel_y_left2(i,:)+vel_y_left_sum2;
%         vel_x_right_sum2 = vel_x_right2(i,:)+vel_x_right_sum2;
%         vel_y_right_sum2 = vel_y_right2(i,:)+vel_y_right_sum2;
end         
%         res_x_up_cellmean = res_x_up_sum/dim(1);% dim(1)= how many cells are there?
%         res_y_up_cellmean =  res_y_up_sum/dim(1);
%         res_x_down_cellmean = res_x_down_sum/dim(1);
%         res_y_down_cellmean = res_y_down_sum/dim(1) ;
%         res_x_left_cellmean = res_x_left_sum/dim(1) ;
%         res_y_left_cellmean = res_y_left_sum/dim(1);
%         res_x_right_cellmean = res_x_right_sum/dim(1) ;
%         res_y_right_cellmean =  res_y_right_sum/dim(1);
%         
%         vel_x_up_cellmean = vel_x_up_sum/dim(1);
% %         vel_x_up_cellmean2 = vel_x_up_sum2/dim(1);
%         vel_y_up_cellmean = vel_y_up_sum/dim(1);
%         vel_x_down_cellmean = vel_x_down_sum/dim(1);
%         vel_y_down_cellmean = vel_y_down_sum/dim(1);
%         vel_x_left_cellmean = vel_x_left_sum/dim(1);
%         vel_y_left_cellmean = vel_y_left_sum/dim(1);
%         vel_x_right_cellmean = vel_x_right_sum/dim(1);
%         vel_y_right_cellmean = vel_y_right_sum/dim(1);
%         
%         vel_x_up_cellmean2 = vel_x_up_sum2/dim(1);
% %         vel_x_up_cellmean2 = vel_x_up_sum2/dim(1);
%         vel_y_up_cellmean2 = vel_y_up_sum2/dim(1);
%         vel_x_down_cellmean2 = vel_x_down_sum2/dim(1);
%         vel_y_down_cellmean2 = vel_y_down_sum2/dim(1);
%         vel_x_left_cellmean2 = vel_x_left_sum2/dim(1);
%         vel_y_left_cellmean2 = vel_y_left_sum2/dim(1);
%         vel_x_right_cellmean2 = vel_x_right_sum2/dim(1);
%         vel_y_right_cellmean2 = vel_y_right_sum2/dim(1);


% % Furthermore, mean and get each direction's eye movement depth (use only
% % midline 1sec)>>>>>1-400 coloum  (0-2sec) ===>> take 100-300 (0.5-1.5sec)
% for i=1:2
%   m_res_x_up(i) = mean(res_x_up_cellmean(201-(100*i):199+(100*i)));
%   m_res_y_up(i) = mean(res_y_up_cellmean(201-(100*i):199+(100*i)));
%   m_res_x_down(i) = mean(res_x_down_cellmean(201-(100*i):199+(100*i)));
%   m_res_y_down(i) = mean(res_y_down_cellmean(201-(100*i):199+(100*i)));
%   m_res_x_left(i) = mean(res_x_left_cellmean(201-(100*i):199+(100*i)));
%   m_res_y_left(i) = mean(res_y_left_cellmean(201-(100*i):199+(100*i)));
%   m_res_x_right(i) = mean(res_x_right_cellmean(201-(100*i):199+(100*i)));
%   m_res_y_right(i) = mean(res_y_right_cellmean(201-(100*i):199+(100*i)));
%   
%   m_vel_x_up(i) = mean(vel_x_up_cellmean(201-(100*i):199+(100*i)));
% %   mean(vel_x_up_cellmean2(100:300))
%   m_vel_y_up(i) = mean(vel_y_up_cellmean(201-(100*i):199+(100*i)));
%   m_vel_x_down(i) = mean(vel_x_down_cellmean(201-(100*i):199+(100*i)));
%   m_vel_y_down(i) = mean(vel_y_down_cellmean(201-(100*i):199+(100*i)));
%   m_vel_x_left(i) = mean(vel_x_left_cellmean(201-(100*i):199+(100*i)));
%   m_vel_y_left(i) = mean(vel_y_left_cellmean(201-(100*i):199+(100*i)));
%   m_vel_x_right(i) = mean(vel_x_right_cellmean(201-(100*i):199+(100*i)));
%   m_vel_y_right(i) = mean(vel_y_right_cellmean(201-(100*i):199+(100*i)));
% end
       
% figure(4)
% plot(vel_x_up_cellmean2,'b.');
%     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-0.1, 0.1]);
%     ylabel('(deg)');        
        
%%%%%%%%%%%%%%%%plot data%%%%%%%%%%%%%%%%%%%%%%
x=1:400;
numfig=round(dim(1)/2);
for m=1:numfig
figure(m+1);
% set(gca,'Position', [5,5 1000,680], 'Name', 'Envelope');    

i=m*2-1;

  subplot(4,2,1);

% [AX,H1,H2] = plotyy(x, res_y_down(i,:)',x, vel_y_down2(i,:)');
% set(H1,'Color','b')
% set(H2,'color','k')
% set(get(AX(1),'Ylabel'),'String','(deg)')
% set(get(AX(2),'Ylabel'),'String','(deg/sec)')
% title(['Eye Position /  ',title2, p_title]);

hl1=line(x, res_y_down(i,:),'Color','b');
ax1=gca;
set(ax1, 'XColor','k','YColor','b','Ylim',[-0.5 0.5])
% set(ax1, 'XTickLabel', [])
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
set(get(ax1,'Ylabel'),'String','(deg)')
ax2=axes('Position', get(ax1,'Position'), 'Color', 'none', 'XColor', 'k', 'YColor', 'k', 'Ylim', [-2 2]);
set(ax2, 'YAxisLocation', 'right')
set(ax2, 'XAxisLocation', 'top', 'XTickLabel', [])
set(get(ax2,'Ylabel'),'String','(deg/sec)')
hl2=line(x, vel_y_down2(i,:),'Color','k','Parent',ax2);

 
    title(['Eye Position /  ',title2, p_title]);
 
 

    text (10,1,['Cell No.', num2str(i)]);
    
  subplot(4,2,3);
    plot(res_y_down(i,:)','b.');
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.25, 0.25]);
    ylabel('(deg)');
    title(['Eye Position /  ',title2, p_title]);
 
    
    
  subplot(4,2,5);
    plot(res_x_left(i,:)','r.');
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.25, 0.25]);
    ylabel('(deg)');
    title(['Eye Position /  ',title3, p_title]);
  
    
    
  subplot(4,2,7);
    plot(res_x_right(i,:)','r.');
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.25, 0.25]);
    ylabel('(deg)');
    title(['Eye Position /  ',title4, p_title]);

i=[];
i=m*2;

  subplot(4,2,2);
    plot(res_y_up(i,:)','b.');
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.25, 0.25]);
    ylabel('(deg)');
    title(['Eye Position /  ',title1, p_title]);

     text (10,0.7,['Cell No.', num2str(i)]);
    
  subplot(4,2,4);
    plot(res_y_down(i,:)','b.');
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.25, 0.25]);
    ylabel('(deg)');
    title(['Eye Position /  ',title2, p_title]);
   
 
    
    
  subplot(4,2,6);
    plot(res_x_left(i,:)','r.');
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.25, 0.25]);
    ylabel('(deg)');
    title(['Eye Position /  ',title3, p_title]);
  
    
    
  subplot(4,2,8);
    plot(res_x_right(i,:)','r.');
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.25, 0.25]);
    ylabel('(deg)');
    title(['Eye Position /  ',title4, p_title]);

end       


% %%%%%%%%%%%%%%%plot data%%%%%%%%%%%%%%%%%%%%%%
% figure(2)
% 
% subplot(4,1,1)%Up=y
% plot(res_y_up_cellmean,'b.');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-0.25, 0.25]);
%     ylabel('(deg)');
%     title(['Eye Position /  ',title1, p_title]);
% 
% %     plot(res_y_up_cellmean,'b.');
% %     hold off;
% 
% 
% subplot(4,1,2)%Down=y
% plot(res_y_down_cellmean,'b.');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-0.25, 0.25]);
%     ylabel('(deg)');
%     title(['Eye Position /  ',title2, p_title]);
% 
% %     plot(res_y_down_cellmean,'b.');
% %     hold off;
% 
% subplot(4,1,3)%left=x
% plot(res_x_left_cellmean,'r.');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-0.25, 0.25]);
%     ylabel('(deg)');
%     title(['Eye Position /  ',title3, p_title]);
% 
% %     plot(res_y_left_cellmean,'b.');
% %     hold off;
%     
% subplot(4,1,4)%right=x
% plot(res_x_right_cellmean,'r.');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-0.25, 0.25]);
%     ylabel('(deg)');
%     title(['Eye Position /  ',title4, p_title]);
% 
% %     plot(res_y_right_cellmean,'b.');
% %     hold off;
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure(3)
% 
% subplot(4,1,1)%up=y
% plot(vel_y_up_cellmean,'b');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-2, 2]);
%     ylabel('(deg/sec)');
%     title(['Velocity /  ',title1, p_title]);
% 
% %     plot(vel_y_up_cellmean,'b');
% %     hold off;
% 
% 
% subplot(4,1,2)%doun=y
% plot(vel_y_down_cellmean,'b');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-2, 2]);
%     ylabel('(deg/sec)');
%     title(['Velocity /  ',title2, p_title]);
% 
% %     plot(vel_y_down_cellmean,'b');
% %     hold off;
% 
% subplot(4,1,3)%left=x
% plot(vel_x_left_cellmean,'r');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-2, 2]);
%     ylabel('(deg/sec)');
%     title(['Velocity /  ',title3, p_title]);
% 
% %     plot(vel_y_left_cellmean,'b');
% %     hold off;
%     
% subplot(4,1,4)%right=x
% plot(vel_x_right_cellmean,'r');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-2, 2]);
%     ylabel('(deg/sec)');
%     title(['Velocity /  ',title4, p_title]);
% 
% %     plot(vel_y_right_cellmean,'b');
% %     hold off;
% 
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure(4)
% 
% subplot(4,1,1)%up=y
% plot(vel_y_up_cellmean2,'b');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-2, 2]);
%     ylabel('(deg/sec)');
%     title(['Velocity /  ',title1, p_title]);
% 
% %     plot(vel_y_up_cellmean2,'b');
% %     hold off;
% 
% 
% subplot(4,1,2)%down=y
% plot(vel_y_down_cellmean2,'b');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-2, 2]);
%     ylabel('(deg/sec)');
%     title(['Velocity /  ',title2, p_title]);
% 
% %     plot(vel_y_down_cellmean2,'b');
% %     hold off;
% 
% subplot(4,1,3)%left=x
% plot(vel_x_left_cellmean2,'r');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-2, 2]);
%     ylabel('(deg/sec)');
%     title(['Velocity /  ',title3, p_title]);
% 
% %     plot(vel_y_left_cellmean2,'b');
% %     hold off;
%     
% subplot(4,1,4)%right=x
% plot(vel_x_right_cellmean2,'r');
% %     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-2, 2]);
%     ylabel('(deg/sec)');
%     title(['Velocity /  ',title4, p_title]);
% 
% %     plot(vel_y_right_cellmean2,'b');
% %     hold off;
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % middle 1 sec 101-299
% % all 2 sec 1 - 399
% %
% 
% 
% for i=1:2
%     if i==1
%   p_up_101_299 = [res_y_up_cellmean(201-(100*i):199+(100*i))];
%   p_down_101_299 = [res_y_down_cellmean(201-(100*i):199+(100*i))];
%   p_left_101_299 = [res_x_left_cellmean(201-(100*i):199+(100*i))];
%   p_right_101_299 = [res_x_right_cellmean(201-(100*i):199+(100*i))];
%   
%   v1_up_101_299 = [vel_y_up_cellmean(201-(100*i):199+(100*i))];
%   v1_down_101_299 = [vel_y_down_cellmean(201-(100*i):199+(100*i))];
%   v1_left_101_299 = [vel_x_left_cellmean(201-(100*i):199+(100*i))];
%   v1_right_101_299 = [vel_x_right_cellmean(201-(100*i):199+(100*i))];
%   
%   v2_up_101_299 = [vel_y_up_cellmean2(201-(100*i):199+(100*i))];
%   v2_down_101_299 = [vel_y_down_cellmean2(201-(100*i):199+(100*i))];
%   v2_left_101_299 = [vel_x_left_cellmean2(201-(100*i):199+(100*i))];
%   v2_right_101_299 = [vel_x_right_cellmean2(201-(100*i):199+(100*i))];
% 
% 
%     elseif i==2
%   p_up_1_399 = [res_y_up_cellmean(201-(100*i):199+(100*i))];
%   p_down_1_399 = [res_y_down_cellmean(201-(100*i):199+(100*i))];
%   p_left_1_399 = [res_x_left_cellmean(201-(100*i):199+(100*i))];
%   p_right_1_399 = [res_x_right_cellmean(201-(100*i):199+(100*i))];
%   
%   v1_up_1_399 = [vel_y_up_cellmean(201-(100*i):199+(100*i))];
%   v1_down_1_399 = [vel_y_down_cellmean(201-(100*i):199+(100*i))];
%   v1_left_1_399 = [vel_x_left_cellmean(201-(100*i):199+(100*i))];
%   v1_right_1_399 = [vel_x_right_cellmean(201-(100*i):199+(100*i))];
%   
%   v2_up_1_399 = [vel_y_up_cellmean2(201-(100*i):199+(100*i))];
%   v2_down_1_399 = [vel_y_down_cellmean2(201-(100*i):199+(100*i))];
%   v2_left_1_399 = [vel_x_left_cellmean2(201-(100*i):199+(100*i))];
%   v2_right_1_399 = [vel_x_right_cellmean2(201-(100*i):199+(100*i))];        
% 
%     end
%     
% end
% % 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5        output files  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% p_up_1=mean(p_up_101_299);
% p_down_1=mean(p_down_101_299);
% p_left_1=mean(p_left_101_299);
% p_right_1=mean(p_right_101_299);
% 
% v1_up_1=mean(v1_up_101_299);
% v1_down_1=mean(v1_down_101_299);
% v1_left_1=mean(v1_left_101_299);
% v1_right_1=mean(v1_right_101_299);
% 
% v2_up_1=mean(v2_up_101_299);
% v2_down_1=mean(v2_down_101_299);
% v2_left_1=mean(v2_left_101_299);
% v2_right_1=mean(v2_right_101_299);
% 
%     space=[0];
% 
% p_up_2=mean(p_up_1_399);
% p_down_2=mean(p_down_1_399);
% p_left_2=mean(p_left_1_399);
% p_right_2=mean(p_right_1_399);
% 
% v1_up_2=mean(v1_up_1_399);
% v1_down_2=mean(v1_down_1_399);
% v1_left_2=mean(v1_left_1_399);
% v1_right_2=mean(v1_right_1_399);
% 
% v2_up_2=mean(v2_up_1_399);
% v2_down_2=mean(v2_down_1_399);
% v2_left_2=mean(v2_left_1_399);
% v2_right_2=mean(v2_right_1_399);   
%     
% middle_mean=[p_up_1 p_down_1 p_left_1 p_right_1 space v1_up_1 v1_down_1 v1_left_1 v1_right_1 space v2_up_1 v2_down_1 v2_left_1 v2_right_1];
% whole_mean=[p_up_2 p_down_2 p_left_2 p_right_2 space v1_up_2 v1_down_2 v1_left_2 v1_right_2 space v2_up_2 v2_down_2 v2_left_2 v2_right_2];
% 
% %%%%%%%%%%%%%%%%%%%% STD %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sp_up_1=std(p_up_101_299);
% sp_down_1=std(p_down_101_299);
% sp_left_1=std(p_left_101_299);
% sp_right_1=std(p_right_101_299);
% 
% sv1_up_1=std(v1_up_101_299);
% sv1_down_1=std(v1_down_101_299);
% sv1_left_1=std(v1_left_101_299);
% sv1_right_1=std(v1_right_101_299);
% 
% sv2_up_1=std(v2_up_101_299);
% sv2_down_1=std(v2_down_101_299);
% sv2_left_1=std(v2_left_101_299);
% sv2_right_1=std(v2_right_101_299);
% 
% %     space=[0];
% 
% sp_up_2=std(p_up_1_399);
% sp_down_2=std(p_down_1_399);
% sp_left_2=std(p_left_1_399);
% sp_right_2=std(p_right_1_399);
% 
% sv1_up_2=std(v1_up_1_399);
% sv1_down_2=std(v1_down_1_399);
% sv1_left_2=std(v1_left_1_399);
% sv1_right_2=std(v1_right_1_399);
% 
% sv2_up_2=std(v2_up_1_399);
% sv2_down_2=std(v2_down_1_399);
% sv2_left_2=std(v2_left_1_399);
% sv2_right_2=std(v2_right_1_399);   
%     
% middle_std=[sp_up_1 sp_down_1 sp_left_1 sp_right_1 space sv1_up_1 sv1_down_1 sv1_left_1 sv1_right_1 space sv2_up_1 sv2_down_1 sv2_left_1 sv2_right_1];
% whole_std=[sp_up_2 sp_down_2 sp_left_2 sp_right_2 space sv1_up_2 sv1_down_2 sv1_left_2 sv1_right_2 space sv2_up_2 sv2_down_2 sv2_left_2 sv2_right_2];
% 
% 
%     summary=[middle_mean;middle_std;whole_mean;whole_std]
%     
%     
%     
%     
% %     csvwrite('summary_101_299.dat',summary_101_299);
%     
