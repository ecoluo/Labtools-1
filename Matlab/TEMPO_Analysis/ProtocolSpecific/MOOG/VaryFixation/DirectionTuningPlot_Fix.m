%-----------------------------------------------------------------------------------------------------------------------
%-- DirectionTuningPlot_Fix.m -- Plots response as a function of azimuth and elevation for MOOG 3D tuning expt
%--	GCD, 6/27/03
%-- Modified for Vary_Fixation protocol: Can now handle multiple stim types and multiple gaze angles.  CRF + Yong, 12/03
%-----------------------------------------------------------------------------------------------------------------------
function DirectionTuningPlot_Fix(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

time = clock;
disp('START TIME = ');
disp(time(4:6));

Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

%get the column of values for azimuth and elevation and stim_type
temp_azimuth = data.moog_params(AZIMUTH,:,MOOG);
temp_elevation = data.moog_params(ELEVATION,:,MOOG);
temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);
temp_amplitude = data.moog_params(AMPLITUDE,:,MOOG);
temp_fix_x    =  data.moog_params(FIX_X,:,MOOG);
temp_fix_y    =  data.moog_params(FIX_Y,:,MOOG);

%now, get the firing rates, spike times, and events for all the trials 
temp_spike_rates = data.spike_rates(SpikeChan, :);                                                                                                                             
temp_spike_data = data.spike_data(SpikeChan, :);
temp_event_data = data.event_data(SpikeChan, :);

% %--------------------------------------------------------------------------
% % Based on a reviewer comment, this will use a 100 ms analysis window (sliding in increments of 50 ms)
% % to re-compute DI at multiple intervals throughout the stimulus period.  (CRF, 9/2006)
% %--------------------------------------------------------------------------
% 
% for bin_num = 1:40  % the END of this loop is at the very end of the script
% bin_num
% clear temp_spike_rates
% for a = BegTrial:EndTrial
%     bin_incr = ((a-1)*5000 + 996 + (bin_num-1)*50 + 1);
%     if bin_num == 40
%         temp_spike_rates(a) = (sum(temp_spike_data( bin_incr : bin_incr + 50 ))) * 20;
%     else
%         temp_spike_rates(a) = (sum(temp_spike_data( bin_incr : bin_incr + 100 ))) * 10;
%     end
% end
% 
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------


%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (temp_azimuth == data.one_time_params(NULL_VALUE)) );

%now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
trials = 1:length(temp_azimuth);		% a vector of trial indices
bad_trials = find(temp_spike_rates > 3000);   % cut off 3k frequency which definately is not cell's firing response
if ( bad_trials ~= NaN)
   select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) & (trials~=bad_trials) );
else
   select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) ); 
end

azimuth = temp_azimuth(~null_trials & select_trials);
elevation = temp_elevation(~null_trials & select_trials);
stim_type = temp_stim_type(~null_trials & select_trials);
amplitude = temp_amplitude(~null_trials & select_trials);
fix_x     = temp_fix_x(~null_trials & select_trials);
fix_y     = temp_fix_y(~null_trials & select_trials);
spike_rates = temp_spike_rates(~null_trials & select_trials);

unique_azimuth  = munique(azimuth');
unique_elevation = munique(elevation');
unique_stim_type = munique(stim_type');
unique_amplitude = munique(amplitude');
unique_fix_x    =  munique(fix_x');
unique_fix_y    =  munique(fix_y');

if length(unique_fix_y) == 1
   condition_num = fix_x;
   temp_condition_num = temp_fix_x;
else
   condition_num = fix_y; 
   temp_condition_num = temp_fix_y;
end

unique_condition_num = munique(condition_num');

% Assign titles
for n=1: length(unique_stim_type)
    for k=1: length(unique_condition_num)
        if length(unique_stim_type) == 1
            if unique_stim_type == 1
                h_title_begin = 'Vestibular, ';
            else
                h_title_begin = 'Visual, ';
            end
        else
            if n == 1
                h_title_begin = 'Vestibular, ';
            else
                h_title_begin = 'Visual, ';
            end
        end
        h_title{(k+3*(n-1))} = [h_title_begin, num2str(unique_condition_num(k))];
    end
end

% number of vectors in each condition 
vector_num = length(unique_azimuth) * (length(unique_elevation)-2) + 2;


% % ADD CODE HERE FOR ANOVA (3D tuning significance test) - 01/11/06 by Katsu
% resp_mat_anova = [];
% for n=1: length(unique_stim_type)
%     q = 0;
%     for i=1:length(unique_azimuth)
%         for j=1:length(unique_elevation)
%             select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (stim_type==unique_stim_type(n)) & (condition_num==0) );
%             if (sum(select) > 0)
%                 q = q+1;
%                 resp_mat_anova{n}(:,q) = spike_rates(select)';
%             end
%         end
%     end
%     [p_anova, table, stats] = anova1(resp_mat_anova{n},[],'off');
%     P_anova(n) = p_anova;   % ***note: upper-case P = 3D, lower-case p = slice
%     anova_table{n} = table;
%     F_val(n) = anova_table{n}(2,5);
% end
% F_val = cell2mat(F_val);


% %---------------------------------------------------------------------------------------
% % TEMPORARY: output for ANOVAs
%
% if unique_stim_type == 1
%     stim_text = 'Vestibular';
% elseif unique_stim_type == 2
%     stim_text = 'Visual';
% else
%     stim_text = 'Vestibular'; % (both, but ves first)
% end
% 
% buff = sprintf('%s\t %4.2f\t %4.3f\t %s\t', FILE, F_val(1), P_anova(1), stim_text );
% outfile = [BASE_PATH 'ProtocolSpecific\MOOG\3Dtuning\DirectionTuningSum_Zebulon_CrisKatsu.dat'];
% printflag = 0;
% if (exist(outfile, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile, 'a');
% if (printflag)
%     fprintf(fid, 'FILE\t F_anova\t P_anova\t');
%     fprintf(fid, '\r\n');
% end
% fprintf(fid, '%s', buff);
% fprintf(fid, '\r\n');
% fclose(fid);
% 
% % And another line if two stim types
% if length(unique_stim_type) > 1
%     stim_text = 'Visual';
%     buff = sprintf('%s\t %4.2f\t %4.3f\t %s\t', FILE, F_val(2), P_anova(2), stim_text );
%     outfile = [BASE_PATH 'ProtocolSpecific\MOOG\3Dtuning\DirectionTuningSum_Zebulon_CrisKatsu.dat'];
% 	fid = fopen(outfile, 'a');
% 	fprintf(fid, '%s', buff);
% 	fprintf(fid, '\r\n');
% 	fclose(fid);
% end
% %---------------------------------------------------------------------------------------


resp_mat = [];  resp_mat_std = [];
for n=1:length(unique_stim_type)
    for i=1:length(unique_azimuth)
        for j=1:length(unique_elevation)
            for k=1:length(unique_condition_num)
                select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) & (stim_type==unique_stim_type(n)) );
                if (sum(select) > 0)                
                    resp_mat((k+3*(n-1)), j, i) = mean(spike_rates(select));
                    resp_mat_std((k+3*(n-1)), j, i) = std(spike_rates(select));    % calculate std between trials for later HTI usage                
                else
                    resp_mat((k+3*(n-1)), j, i) = 0;                
                    resp_mat_std((k+3*(n-1)), j, i) = 0;
                end
            end        
        end
    end
end

% creat a real 3-D based plot where the center correspond to forward and 
% both lateral edges correspond to backward
resp_mat_tran = [];
for n=1: length(unique_stim_type)
	for i=1:( length(unique_azimuth)+1 )        % add a azimuth 360 to make it circularlly continuously
        for j=1:length(unique_elevation)
            for k=1:length(unique_condition_num)
                if ( j == 1 | j == 5 )                          % fill NaN point with data
                    resp_mat_tran((k+3*(n-1)), j, i) = resp_mat((k+3*(n-1)), j, 1);   
                else
                    if (i < 8)
                        resp_mat_tran((k+3*(n-1)), j, i) = resp_mat((k+3*(n-1)), j, 8-i);
                    elseif (i==8)
                        resp_mat_tran((k+3*(n-1)), j, i) = resp_mat((k+3*(n-1)), j, 8);
                    else
                        resp_mat_tran((k+3*(n-1)), j, i) = resp_mat((k+3*(n-1)), j, 7);
                    end
                end
            end        
        end
	end
end

% calculate spontaneous firing rate -- CORRECTED (now only includes Begtrial:Endtrial)
temp_spike_rates_true = temp_spike_rates(BegTrial:EndTrial);
for k= 1:length(unique_condition_num)
    spon_resp(k) = mean( temp_spike_rates_true( find( null_trials(BegTrial:EndTrial)==1 & temp_condition_num(BegTrial:EndTrial)==unique_condition_num(k) ) ) );
end

trials_per_rep = 26 * length(unique_condition_num) * length(unique_stim_type) + length(unique_condition_num);
repetitions = floor( (EndTrial-(BegTrial-1)) / trials_per_rep);

% calculate min and max firing rate, standard deviation, HTI, Vectorsum
for n=1:length(unique_stim_type)
	for k=1: length(unique_condition_num) 
        Min_resp((k+3*(n-1))) = min( min( resp_mat_tran((k+3*(n-1)),:,:)) );
        Max_resp((k+3*(n-1))) = max( max( resp_mat_tran((k+3*(n-1)),:,:)) );
        resp_std((k+3*(n-1))) = sum( sum(resp_mat_std((k+3*(n-1)),:,:)) ) / vector_num;  % notice that do not use mean here, its 26 vectors intead of 40
        M=squeeze(resp_mat((k+3*(n-1)),:,:));     % notice that here HTI should use resp_temp without 0 value set manually
        HTI_temp((k+3*(n-1))) = HTI(M,spon_resp(k));
        N=squeeze(resp_mat((k+3*(n-1)),:,:));     % notice that here vectorsum should use resp_mat with 0 value set manually 
        [Azi, Ele, Amp] = vectorsum(N);
        Vec_sum{(k+3*(n-1))} = [Azi, Ele, Amp];
    end
end


proceed = 0;
%proceed = input('proceed with slice?');
if proceed == 1
%----------------------------------------------------------------------------------------------------
%----------------------------------------------------------------------------------------------------
% BEGIN horizontal plane slice code
%----------------------------------------------------------------------------------------------------
%----------------------------------------------------------------------------------------------------

resp_mat_slice = [];  resp_mat_std_slice = [];
for k = 1:length(unique_condition_num)
    for n = 1:length(unique_stim_type)
        for i = 1:length(unique_azimuth)
            select_slice = logical( (azimuth==unique_azimuth(i)) & (elevation==0) & (condition_num==unique_condition_num(k)) & (stim_type==unique_stim_type(n)) );
            if (sum(select_slice) > 0)                
                resp_mat_slice(k,n,i) = mean(spike_rates(select_slice));
                resp_mat_std_slice(k,n,i) = std(spike_rates(select_slice));
            else
                resp_mat_slice(k,n,i) = 0;
                resp_mat_std_slice(k,n,i) = 0;
            end
        end
    end
end

resp_mat_tran_slice = []; resp_mat_std_tran_slice = [];
for k = 1:length(unique_condition_num)
    for n = 1:length(unique_stim_type)
        for i = 1:length(unique_azimuth)+1
            if (i < 8)
                resp_mat_tran_slice(k,n,i) = resp_mat_slice(k,n,8-i);
                resp_mat_std_tran_slice(k,n,i) = resp_mat_std_slice(k,n,8-i);
            elseif (i==8)
                resp_mat_tran_slice(k,n,i) = resp_mat_slice(k,n,8);
                resp_mat_std_tran_slice(k,n,i) = resp_mat_std_slice(k,n,8);
            else
                resp_mat_tran_slice(k,n,i) = resp_mat_slice(k,n,7);
                resp_mat_std_tran_slice(k,n,i) = resp_mat_std_slice(k,n,7);
            end
        end
    end
end


% ----------------------------------------------------------
% define figure

for n=1:length(unique_stim_type)
    xoffset=0;
    yoffset=0;
    figure(n+10);
    orient landscape;
    set(n+10,'Position', [5+1200*(n-1),-120 1200,900], 'Name', '3D Direction Tuning Slice');
    axis off;
    
    for k=1: length(unique_condition_num) 
        if (xoffset > 0.5)          % now temperarily 2 pictures one row and 2 one column
            yoffset = yoffset-0.4;
            xoffset = 0;
        end
        axes('position',[0.11+xoffset 0.54+yoffset 0.32 0.24]);
        
        x_azimuth = [1 2 3 4 5 6 7 8 9];
        errorbar(x_azimuth, resp_mat_tran_slice(k,n,:), resp_mat_std_tran_slice(k,n,:)/sqrt(repetitions), 'ko-');
        hold on;
        spon_line(1:length(x_azimuth)) = spon_resp(k);  % display spontaneous as a dotted line
        plot(x_azimuth,spon_line,'b:');
        xlim( [x_azimuth(1), x_azimuth(end)] );
        set(gca, 'xtick', x_azimuth );
        set(gca, 'xticklabel','270|225|180|135|90|45|0|-45|-90');
        xlabel('Azimuth');
        title( h_title{(k+3*(n-1))} );
        xoffset=xoffset+0.48;

        % calculate min and max firing rate, standard deviation, HTI, Vectorsum
        Min_resp_slice(k,n) = min( resp_mat_tran_slice(k,n,:) );
        Max_resp_slice(k,n) = max( resp_mat_tran_slice(k,n,:) );
        resp_std_slice(k,n) = sum( sum(resp_mat_std_slice(k,n,:)) ) / vector_num; % average standard deviation?
        M = squeeze(resp_mat_slice(k,n,:));
        M = M';
        [Azi, Ele, Amp] = vectorsum(M);
        Vec_sum_slice{k,n} = [Azi, Ele, Amp];
        Vec_sum_azi(k,n) = Azi;
        HTI_temp_slice(k,n) = HTI(M,spon_resp(k));
        
    end
end


% -------------------------------------------------------------------------
% Curve fitting
% -------------------------------------------------------------------------

proceed0 = 1;
% proceed0 = input('proceed with fitting?');
if proceed0 == 1

options = optimset('MaxFunEvals', 10000, 'MaxIter', 5000, 'LargeScale', 'off', 'LevenbergMarquardt', 'on', 'Display', 'off');
A = []; b = []; Aeq = []; beq = []; nonlcon = [];

clear global xdata; % necessary when using tempo_gui multiple times (?)
global xdata;

xdata = [0 45 90 135 180 225 270 315] * pi/180;          % for fitting
xdata_tran = [-90 -45 0 45 90 135 180 225 270] * pi/180; % for display
for j = 1:repetitions
    xdata_mat(j,:) = xdata;
end
xdata = xdata_mat;

figure(3);
orient landscape;
set(3,'Position', [50,25 1200,900], 'Name', '1D Azimuth VaryFix CurveFits');
axis off;
for n=1:length(unique_stim_type)
    for k=1: length(unique_condition_num) 
        figure(3);
        xoffset = (n-1) * 0.33;
        yoffset = (k-1) * -0.28;
        axes('position',[0.02+xoffset 0.62+yoffset 0.28 0.20]);
        errorbar(xdata_tran, resp_mat_tran_slice(k,n,:), resp_mat_std_tran_slice(k, n, :)/sqrt(repetitions), 'ro');
        hold on;
        spon_line2(1:length(xdata_tran)) = spon_resp(k);  % display spontaneous as a dotted line
        plot(xdata_tran,spon_line2,'b:');

      % fitting individual trial data, so:
        clear global ydata
        global ydata
        for i=1:length(unique_azimuth)
            select = logical( (azimuth==unique_azimuth(i)) & (elevation == 0) & (condition_num==unique_condition_num(k)) & (stim_type==unique_stim_type(n)) );
            ydata(:,i) = spike_rates(select)';
        end

%**********************************************
% Function 4 (6 params, see VF_1D_Curvefit.m):

        model = ' Charlie Special ';
        param_label = 'A         mu     sigma     K     K-sig      DC';
        lb = [0.001 -2*pi pi/6 0 0.5 0];   % lower bounds
        ub = [1.5*(Max_resp_slice(k,n)-Min_resp_slice(k,n)) 2*pi 2*pi 0.95 0.95 0.8*Max_resp_slice(k,n)];   % upper bounds
        
      % initial parameter guesses
        x0 = [];
        
        x0(1) = Max_resp_slice(k,n) - Min_resp_slice(k,n);   % A = peak-trough modulation
        if x0(1) < 1
            x0(1) = 1;
        end

%     % mu = azimuth of vector sum:
%         x0(2) = Vec_sum{k,n}(1) * pi/180;
%         if x0(2) < 0
%             x0(2) = x0(2) + 2*pi;
%         end

      % OR, mu = azimuth of max response:
        whereis_max = logical(resp_mat_slice == Max_resp_slice(k,n));
        whereis_max = squeeze(whereis_max(k,n,:));
        max_azi{k,n} = unique_azimuth(find(whereis_max));
        if length(max_azi{k,n}) > 1   % need these to be unique, and believe it or not they sometimes aren't
            max_azi{k,n} = max_azi{k,n}(1);
        end
        x0(2) = max_azi{k,n} * pi/180;

        x0(6) = Min_resp_slice(k,n);   % DC = min response
        
      % search for best starting values of x0(3), x0(4), and x0(5)
        N = 30;
        min_err = 9999999999999999.99;
		x3range = lb(3) : (ub(3)-lb(3))/N : ub(3);
        x4range = lb(4) : (ub(4)-lb(4))/N : ub(4); 
        x5range = lb(5) : (ub(5)-lb(5))/N : ub(5); 
		for i = 1:N
            x3temp = x3range(i);
            if x3temp == 0
                x3temp = 0.0001;
            end
            for j = 1:N
                x4temp = x4range(j);
                for h = 1:N
                    x5temp = x5range(h);
                    if x5temp == 0
                        x5temp = 0.0001;
                    end
                    x_temp = [x0(1) x0(2) x3temp x4temp x5temp x0(6)];
                    error = VF_1D_Curvefit_err(x_temp);
                    if (error < min_err)
                        x3min = x3temp; x4min = x4temp; x5min = x5temp;
                        min_err = error;    
                    end
                end
            end
		end
		x0(3) = x3min; x0(4) = x4min; x0(5) = x5min;

%**********************************************

        % fit multiple times with some jitter in the initial params
        N_reps = 30;
        wiggle = 0.3;
        clear testpars fval_temp exitflag_temp;
        for j=1:N_reps
            rand_factor = rand(length(x0),1) * wiggle + (1-wiggle/2); % ranges from 1-wiggle/2 -> 1 + wiggle/2
            temp_x0 = x0' .* rand_factor;
            [testpars{j}, fval_temp(j), exitflag_temp(j)] = fmincon('VF_1D_Curvefit_err', temp_x0, A, b, Aeq, beq, lb, ub, nonlcon, options);
%            testpars{j} = fmincon('VF_1D_Curvefit_err', temp_x0, A, b, Aeq, beq, lb, ub, nonlcon, options);
            err{k,n}(j) = VF_1D_Curvefit_err(testpars{j});
            yfit_test{j} = (VF_1D_Curvefit(testpars{j},xdata));
            [coef_test,P_test] = corrcoef(ydata',yfit_test{j}');   % R^2's using means
            rsquared_test(j) = coef_test(1,2)^2;
        end

      % so the best-fit values of x are:
        best_err = find(err{k,n} == min(err{k,n}));
        best_r2 = find(rsquared_test(best_err) == max(rsquared_test(best_err)));  % if multiple occurences of lowest 
        x{k,n} = testpars{best_err(best_r2)};                                     % error, use the one with best R^2
      % and the rest...
        final_error(k,n) = min(err{k,n});
        fval(k,n) = fval_temp(best_err(best_r2));
        exitflag(k,n) = exitflag_temp(best_err(best_r2));
        yfit{k,n} = (VF_1D_Curvefit(x{k,n},xdata));
        [coef,P] = corrcoef(mean(ydata)',mean(yfit{k,n})');   % R^2's using means
        rsquared(k,n) = coef(1,2)^2;
        p_fit(k,n) = P(1,2);
        x_0{k,n} = x0;
        
      % finish plotting
        x_smooth = 0:0.01:2*pi;
        y_smooth = (VF_1D_Curvefit(x{k,n},x_smooth));
        x_smooth_tran = xdata_tran(1):0.01:xdata_tran(end);
        y_smooth_tran = fliplr(VF_1D_Curvefit(x{k,n},x_smooth_tran));
        plot(x_smooth_tran,y_smooth_tran,'b');
        xlim( [xdata_tran(1) xdata_tran(end)] );
        set(gca, 'xtick', xdata_tran);
%         set(gca, 'xdir' , 'reverse');
        set(gca, 'xticklabel','-90|-45|0|45|90|135|180|225|270');
        if k == length(unique_condition_num)
            xlabel('Azimuth');
        end

        % show params for each fit
        param_text = [num2str(x{k,n}(1),4) '    ' num2str(x{k,n}(2)*180/pi,4) '    ' num2str(x{k,n}(3)*180/pi,4) '    ' num2str(x{k,n}(4),4) '    ' num2str(x{k,n}(5),4) '    ' num2str(x{k,n}(6),4)];            
        x0_text = [num2str(x0(1),4) '    ' num2str(x0(2)*180/pi,4) '    ' num2str(x0(3)*180/pi,4) '    ' num2str(x0(4),4) '    ' num2str(x0(5),4) '    ' num2str(x0(6),4)];
        y_lim = ylim;
        y_range = y_lim(2)-y_lim(1);
        text(4, y_lim(2)+.20*y_range, param_label);
        text(4, y_lim(2)+.12*y_range, x0_text);
        text(4, y_lim(2)+.04*y_range, param_text);

      % take peak of fitted function as preferred heading 
        peak(k,n) = x_smooth(find(y_smooth == max(y_smooth))) * 180/pi;
%*******peak(k,n) = x{k,n}(2); (or should it be phi/mu parameter? Why aren't they identical? *******

    end
end


% plot error for each jittered fit, to make sure fits are converging properly
figure(4);
orient landscape;
set(4,'Position', [95,25 1200,900], 'Name', '1D Az VF CurveFit Error');
axis off;
for n=1:length(unique_stim_type)
    for k=1: length(unique_condition_num) 
        xoffset = (n-1) * 0.33;
        yoffset = (k-1) * -0.28;
        axes('position',[0.02+xoffset 0.62+yoffset 0.28 0.22]);
        plot(err{k,n});
        x_text = ['min err = ' num2str(min(err{k,n})) '   fval = ' num2str(fval(k,n))];
        xlabel(x_text);
        if n == 2 & k == 1
            title([FILE '   ' model]);
        end
    end
end

% print;
% close;


% -------------------------------------------------------------------------
% Compute shift ratios from the curve-fitted peaks
for n = 1:length(unique_stim_type)
    
    if abs(peak(1,n) - peak(2,n)) > 180   % (to deal with wrap-around problem)
        if peak(1,n) > peak(2,n)
            SR_fit(1,n) = (peak(1,n) - (peak(2,n)+360)) / unique_condition_num(3);
        else
            SR_fit(1,n) = ((peak(1,n)+360) - peak(2,n)) / unique_condition_num(3);
        end
    else
        SR_fit(1,n) = (peak(1,n) - peak(2,n)) / unique_condition_num(3);      % minus
    end
    
    if abs(peak(1,n) - peak(3,n)) > 180
        if peak(1,n) > peak(3,n)
            SR_fit(2,n) = (peak(1,n) - (peak(3,n)+360)) / (2*unique_condition_num(3));
        else
            SR_fit(2,n) = ((peak(1,n)+360) - peak(3,n)) / (2*unique_condition_num(3));
        end
    else
        SR_fit(2,n) = (peak(1,n) - peak(3,n)) / (2*unique_condition_num(3));  % plusminus
    end
    
    if abs(peak(2,n) - peak(3,n)) > 180
        if peak(2,n) > peak(3,n)
            SR_fit(3,n) = (peak(2,n) - (peak(3,n)+360)) / unique_condition_num(3);      
        else
            SR_fit(3,n) = ((peak(2,n)+360) - peak(3,n)) / unique_condition_num(3);
        end
    else
        SR_fit(3,n) = (peak(2,n) - peak(3,n)) / unique_condition_num(3);      % plus            
    end
    
end

% -------------------------------------------------------------------------
% Lastly, display fit params, etc. at the top of the figure

figure(3);
for n = 1:length(unique_stim_type)
    xoffset = (n-1) * 0.33;
    axes('position',[0.02+xoffset,0.83 0.31,0.12] );
    xlim( [0,100] );
    ylim( [0,length(unique_condition_num)] );
    text(0.3,length(unique_condition_num),'Azi-fit    exitflag   error        r^2          p-fit      SR-fit');
    for k=1:length(unique_condition_num)
        if p_fit(k,n) < 0.001
            p_fit(k,n) = 0; % round tiny p_fits to zero, for display purposes
        end            
        h_text{k,n} = num2str( [peak(k,n), exitflag(k,n), final_error(k,n), rsquared(k,n), p_fit(k,n), SR_fit(k,n)], 4);
        text(0.3,length(unique_condition_num)-k/2, h_text{k,n});
    end
    if n == 2
        text(0.35, length(unique_condition_num)+0.4, FILE);
    end
    if n == 3
        text(0.35, length(unique_condition_num)+0.4, model);
    end
    axis off;
end

% print;
% close;


%-------------------------------------------------------------------------
% Fisher information analysis: compute estimate of variance at each point on 
% fitted function, using the average fano factor for this cell
%-------------------------------------------------------------------------

for n=1:length(unique_stim_type)
    for k=1: length(unique_condition_num)
        
        fano(k,n) = mean(squeeze(resp_mat_std_slice(k,n,:).^2) ./ squeeze(resp_mat_slice(k,n,:)) );

        x_smooth_tran = xdata_tran(1):0.01:xdata_tran(end);
		y_smooth_tran = fliplr(VF_1D_Curvefit(x{k,n},x_smooth_tran));
        fisher_variance = y_smooth_tran * fano(k,n);
        fisher_slope = diff(y_smooth_tran);
        fisher{k,n} = (fisher_slope.^2) ./ fisher_variance(1:end-1);
        
        %%%%% TEMP - for testing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure; errorbar(x_smooth_tran,y_smooth_tran,fisher_variance);
        xlim( [xdata_tran(1) xdata_tran(end)] );
		set(gca, 'xtick', xdata_tran);
% 		set(gca, 'xdir' , 'reverse');
		set(gca, 'xticklabel','-90|-45|0|45|90|135|180|225|270');
        legend('variance');
        
        figure; plot(x_smooth_tran,y_smooth_tran/max(y_smooth_tran));
        hold on;
        plot(x_smooth_tran(1:end-1), fisher_slope/max(fisher_slope), 'g');
        plot(x_smooth_tran(1:end-1), fisher{k,n}/max(fisher{k,n}), 'r');
        xlim( [xdata_tran(1) xdata_tran(end)] );
		set(gca, 'xtick', xdata_tran);
% 		set(gca, 'xdir' , 'reverse');
		set(gca, 'xticklabel','-90|-45|0|45|90|135|180|225|270');
        legend('normalized response','normalized slope','normalized fisher info');
        %%%%% TEMP - for testing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    end
end


else   % to skip entire curve-fitting section, following PROCEED0 input
    peak = zeros(3,3);
    rsquared = zeros(3,3);
    p_fit = zeros(3,3);
    SR_fit = zeros(3,3);
end 



    %----------------------------------------------------------
    % Eye-centered model versus head-centered model comparison
    % (fitting all gaze angles simultaneously)

% proceed1 = input('proceed with eye vs head?');
proceed1 = 0;
if proceed1 == 1
    
% options = optimset('MaxFunEvals', 10000, 'MaxIter', 5000, 'LargeScale', 'off', 'LevenbergMarquardt', 'on', 'Display', 'off');
options = optimset('MaxFunEvals', 5000, 'MaxIter', 1000, 'LargeScale', 'off', 'LevenbergMarquardt', 'on', 'Display', 'off');
A = []; b = []; Aeq = []; beq = []; nonlcon = [];

clear global xdata ydata ydata_merged; % necessary when using tempo_gui multiple times (?)
global xdata ydata ydata_merged;

xdata = [0 45 90 135 180 225 270 315] * pi/180;          % for fitting
xdata_tran = [-90 -45 0 45 90 135 180 225 270] * pi/180; % for display
for j = 1:repetitions
    xdata_mat(j,:) = xdata;
end
xdata = xdata_mat;

for n=1:length(unique_stim_type)
    for k=1: length(unique_condition_num) 
        for i=1:length(unique_azimuth)
            select = logical( (azimuth==unique_azimuth(i)) & (elevation==0) & (condition_num==unique_condition_num(k)) & (stim_type==unique_stim_type(n)) );
            ydata{k,n}(:,i) = spike_rates(select)';
        end
    end
    ydata_merged{n} = [ydata{1,n}; ydata{2,n}; ydata{3,n}];
end


for n=1:length(unique_stim_type)
    
% model = ' Charlie Special ';
% 16 params: 
% X = [ A1  mu-s  sigma1  K1  K_sig1  DC1
%       A2  mu    sigma2  K2  K_sig2  DC2
%       A3  mu+s  sigma3  K3  K_sig3  DC3  ], where s = 22.5 for eye and 0 for head

    LB = [0.001 -2*pi pi/6 0 0.5 0 ; 
          0.001 -2*pi pi/6 0 0.5 0 ;
          0.001 -2*pi pi/6 0 0.5 0];   % lower bounds

    UB = [1.5*(Max_resp_slice(1,n)-Min_resp_slice(1,n)) 2*pi 2*pi 0.95 0.95 0.8*Max_resp_slice(1,n) ;
          1.5*(Max_resp_slice(2,n)-Min_resp_slice(2,n)) 2*pi 2*pi 0.95 0.95 0.8*Max_resp_slice(2,n) ;
          1.5*(Max_resp_slice(3,n)-Min_resp_slice(3,n)) 2*pi 2*pi 0.95 0.95 0.8*Max_resp_slice(3,n)];   % upper bounds
        
    % initial parameter guesses
    X0 = [];
    for k = 1:length(unique_condition_num)
        
        % A = peak-trough modulation
        X0(k,1) = Max_resp_slice(k,n) - Min_resp_slice(k,n);
        if X0(k,1) < 1
            X0(k,1) = 1;
        end
        
        % mu = azimuth of max response
        whereis_max = logical(resp_mat_slice == Max_resp_slice(k,n));
        whereis_max = squeeze(whereis_max(k,n,:));
        max_azi = unique_azimuth(find(whereis_max));
        if length(max_azi) > 1   % need these to be unique, and believe it or not they sometimes aren't
            max_azi = max_azi(1);
        end
        X0(k,2) = max_azi * pi/180;

        % DC = min response
        X0(k,6) = Min_resp_slice(k,n);
        
        % search for best starting values of sigma, K, and K-sig
        N = 40;
        min_err = 9999999999999999.99;
		x3range = LB(k,3) : (UB(k,3)-LB(k,3))/N : UB(k,3);
        x4range = LB(k,4) : (UB(k,4)-LB(k,4))/N : UB(k,4); 
        x5range = LB(k,5) : (UB(k,5)-LB(k,5))/N : UB(k,5);
		for i = 1:N
            x3temp = x3range(i);
            if x3temp == 0
                x3temp = 0.0001;
            end
            for j = 1:N
                x4temp = x4range(j);
                for h = 1:N
                    x5temp = x5range(h);
                    if x5temp == 0
                        x5temp = 0.0001;
                    end
                    x_temp = [X0(k,1) X0(k,2) x3temp x4temp x5temp X0(k,6)];
                    error = VF_1D_Curvefit_err_temp(x_temp,n,k,repetitions);
                    if (error < min_err)
                        x3min = x3temp; x4min = x4temp; x5min = x5temp;
                        min_err = error;    
                    end
                end
            end
		end
		X0(k,3) = x3min; X0(k,4) = x4min; X0(k,5) = x5min;

    end
    
    % fit multiple times with some jitter in the initial params
    N_reps = 15;
    wiggle = 0.3;
    clear testpars_head testpars_eye;
    global stimtype;
    stimtype = n;
    min_err_eye = 9999999999999999.99; min_err_head = 9999999999999999.99;
    for j=1:N_reps

        FILE
        n        
        j
        
        rand_factor = rand(size(X0)) * wiggle + (1-wiggle/2); % ranges from 1-wiggle/2 -> 1 + wiggle/2
        temp_X0 = X0 .* rand_factor;

        testpars_head = fmincon('VF_1D_Curvefit_err_head', temp_X0, A, b, Aeq, beq, LB, UB, nonlcon, options);
        err_head = VF_1D_Curvefit_err_head(testpars_head);
        if (err_head < min_err_head)
            testpars_head_min = testpars_head;
            min_err_head = err_head;    
        end

        testpars_eye = fmincon('VF_1D_Curvefit_err_eye', temp_X0, A, b, Aeq, beq, LB, UB, nonlcon, options);
        err_eye = VF_1D_Curvefit_err_eye(testpars_eye);
        if (err_eye < min_err_eye)
            testpars_eye_min = testpars_eye;
            min_err_eye = err_eye;    
        end

    end

    X_0_head{n} = X0;
    X_0_eye{n} = X0;
    X_head{n} = testpars_head_min;
    X_eye{n} = testpars_eye_min;
    yfit_head{n} = (VF_1D_Curvefit_head(X_head{n},xdata));
    yfit_eye{n} = (VF_1D_Curvefit_eye(X_eye{n},xdata));

    % R^2's using means, but need to parse and avg the data first
    for k = 1:length(unique_condition_num)
        for i = 1:length(unique_azimuth)
            ydata_stacked{n}(i+length(unique_azimuth)*(k-1)) = mean(ydata_merged{n}((k-1)*repetitions+1:k*repetitions,i));
            yfit_head_stacked{n}(i+length(unique_azimuth)*(k-1)) = mean(yfit_head{n}((k-1)*repetitions+1:k*repetitions,i));
            yfit_eye_stacked{n}(i+length(unique_azimuth)*(k-1)) = mean(yfit_eye{n}((k-1)*repetitions+1:k*repetitions,i));
        end
    end

    clear coef P;
    [coef,P] = corrcoef(ydata_stacked{n},yfit_head_stacked{n});
    R_head(n) = coef(1,2);
    rsquared_head(n) = coef(1,2)^2;
    p_fit_head(n) = P(1,2);

    clear coef P;
    [coef,P] = corrcoef(ydata_stacked{n},yfit_eye_stacked{n});
    R_eye(n) = coef(1,2);
    rsquared_eye(n) = coef(1,2)^2;
    p_fit_eye(n) = P(1,2);
    
%    for partial correlation, need corrcoef between eye and head themselves
    clear coef P;
    [coef,P] = corrcoef(yfit_head_stacked{n},yfit_eye_stacked{n});
    R_headeye(n) = coef(1,2);
    rsquared_headeye(n) = coef(1,2)^2;
    partialcorr_head(n) = (R_head(n) - R_eye(n) * R_headeye(n)) / sqrt( (1-rsquared_eye(n)) * (1-rsquared_headeye(n)) );
    partialcorr_eye(n) = (R_eye(n) - R_head(n) * R_headeye(n)) / sqrt( (1-rsquared_head(n)) * (1-rsquared_headeye(n)) );
    partialZ_head(n) = 0.5 * log((1+partialcorr_head(n))/(1-partialcorr_head(n))) / (1/sqrt(length(unique_azimuth)*length(unique_condition_num)-3));
    partialZ_eye(n) = 0.5 * log((1+partialcorr_eye(n))/(1-partialcorr_eye(n))) / (1/sqrt(length(unique_azimuth)*length(unique_condition_num)-3));
    
end


X_head_temp = X_head;
X_eye_temp = X_eye;

for n=1:length(unique_stim_type)
    
    figure(n+12);
    orient landscape;
    set(n+12,'Position', [50,25 1200,900], 'Name', '3D VaryFixation Slice Model Fits');
    axis off;
   
    X_head_temp{n}(1,2) = X_head_temp{n}(2,2);
    X_head_temp{n}(3,2) = X_head_temp{n}(2,2);
    X_eye_temp{n}(1,2) = X_eye_temp{n}(2,2) + pi/8;
    X_eye_temp{n}(3,2) = X_eye_temp{n}(2,2) - pi/8;
    xoffset=0;
    yoffset=0;
    
    for k=1: length(unique_condition_num) 
        
        if (xoffset > 0.5)          % now temperarily 2 pictures one row and 2 one column
            yoffset = yoffset-0.4;
            xoffset = 0;
        end
        axes('position',[0.11+xoffset 0.54+yoffset 0.32 0.24]);
        errorbar(xdata_tran, resp_mat_tran_slice(k,n,:), resp_mat_std_tran_slice(k, n, :)/sqrt(repetitions), 'ro');
        hold on;
        spon_line2(1:length(xdata_tran)) = spon_resp(k);  % display spontaneous as a dotted line
        plot(xdata_tran,spon_line2,'b:');
        
        x_smooth = 0:0.01:2*pi;
        y_smooth_head = VF_1D_Curvefit(X_head_temp{n}(k,:),x_smooth);
        y_smooth_eye = VF_1D_Curvefit(X_eye_temp{n}(k,:),x_smooth);
        x_smooth_tran = xdata_tran(1):0.01:xdata_tran(end);
        y_smooth_tran_head = fliplr(VF_1D_Curvefit(X_head_temp{n}(k,:),x_smooth_tran));
        y_smooth_tran_eye = fliplr(VF_1D_Curvefit(X_eye_temp{n}(k,:),x_smooth_tran));

        plot(x_smooth_tran,y_smooth_tran_head,'b',x_smooth_tran,y_smooth_tran_eye,'g');
        xlim( [xdata_tran(1) xdata_tran(end)] );
        set(gca, 'xtick', xdata_tran);
%        set(gca, 'xdir' , 'reverse');
        set(gca, 'xticklabel','270|225|180|135|90|45|0|-45|-90');
%        set(gca, 'xticklabel','-90|-45|0|45|90|135|180|225|270');
        if k == length(unique_condition_num)
            xlabel('Azimuth');
        end
        xoffset=xoffset+0.48;

        % show peaks (mu) for eye and head
        param_text = [num2str(X_head_temp{n}(k,2)*180/pi,4) '       ' num2str(X_eye_temp{n}(k,2)*180/pi,4)];
        clear y_lim y_range;
        y_lim = ylim;
        y_range = y_lim(2)-y_lim(1);
        text(0.5, y_lim(2)+.12*y_range, 'azi-head    azi-eye');
        text(0.5, y_lim(2)+.04*y_range, param_text);
    end
    
    % and the R^2's at the top
    axes('position',[0.32,0.83 0.31,0.12] );
    xlim( [0,100] );
    ylim( [0,1] );
    text(25,0.5,'     Rsquared-head          Rsquared-eye     ');
    text(25,0.3,['     ' num2str(rsquared_head(n)) '                    ' num2str(rsquared_eye(n))]);
    text(25,1,FILE);
    if unique_stim_type(n) == 1
        text(5,0.5,'Vestibular');
    else
        text(5,0.5,'Visual');
    end
    axis off;
    
%    print;
%    close;
    
end


else  % to skip entire section above, following PROCEED1 input
    for n=1:length(unique_stim_type)
        rsquared_head(n) = NaN; rsquared_eye(n) = NaN;
        partialZ_head(n) = NaN; partialZ_eye(n) = NaN;
    end
end



    % -------------------------------------------------------------------------
    % ANOVA to test tuning significance

% first parse raw data into repetitions, including null trials
for q = 1:repetitions
    azimuth_rep{q} = temp_azimuth(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
    elevation_rep{q} = temp_elevation(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
    stim_type_rep{q} = temp_stim_type(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
    condition_num_rep{q} = temp_condition_num(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
    spike_rates_rep{q} = temp_spike_rates(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
end

for n = 1:length(unique_stim_type)
    for k = 1:length(unique_condition_num)
        for i = 1:length(unique_azimuth)
            clear select_rep;
            for q = 1:repetitions
                select_rep{q} = logical( azimuth_rep{q}==unique_azimuth(i) & elevation_rep{q}==0 & condition_num_rep{q}==unique_condition_num(k) & stim_type_rep{q}==unique_stim_type(n) );
                resp_anova{k,n}(q,i) = spike_rates_rep{q}(select_rep{q});
            end
        end
        p_anova(k,n) = anova1(resp_anova{k,n}(:,:),[],'off');
    end
end


    %---------------------------------------------------------------------------------------
    % Rayleigh test (Batschelet, 1981)

for k=1:length(unique_condition_num)
    for n=1:length(unique_stim_type)
        M = squeeze(resp_mat_slice(k,n,:));
        M = M';
        c = 1.0262;                % correction for grouped data at 45 deg intervals
        R = Vec_sum_slice{k,n}(3) * c;   % resultant length = vectorsum magnitude * correction
        num = sum(M);              % n = sum of all vectors (same as 'total number of spikes')
        Z(k,n) = R^2 / num;        % z = n*r^2 = R^2/n (because r = R/n)
    end
end



%     %---------------------------------------------------------------------------------------
%     % Compute rotated vectors ('eye-centered' prediction) and shift ratios with rotation.m
%     % OMIT - not necessary for horizontal shifts
% 
gaze_dir = 0;
dir_text = 'Horizontal';
% for n = 1: length(unique_stim_type)
%     [exp_plus, exp_minus, shift_ratio_plus, shift_ratio_minus, shift_ratio_plusminus, noise_ratio_plus, noise_ratio_minus, noise_ratio_plusminus] = rotation_no_plots(Vec_sum_slice{3*n-1}, Vec_sum_slice{3*n}, Vec_sum_slice{3*n-2}, unique_condition_num(3), gaze_dir);
%     rot_data_slice{n} = [shift_ratio_plus, shift_ratio_minus, shift_ratio_plusminus];
%     rot_data2_slice{n} = [exp_plus, exp_minus, shift_ratio_plus, shift_ratio_minus, shift_ratio_plusminus, noise_ratio_plus, noise_ratio_minus, noise_ratio_plusminus];
% end


    % For horizontal gaze shifts, compute 'true' shift ratio (using only
    % azimuths), because rotation.m may be overestimating the SR for cells with a
    % substantial elevation component.
for n = 1:length(unique_stim_type)
    if gaze_dir == 0
        if abs(Vec_sum_slice{3*n-2}(1) - Vec_sum_slice{3*n-1}(1)) > 180
            SR_slice{n}(1) = ((Vec_sum_slice{3*n-2}(1)+360) - Vec_sum_slice{3*n-1}(1)) / unique_condition_num(3);
        else
            SR_slice{n}(1) = (Vec_sum_slice{3*n-2}(1) - Vec_sum_slice{3*n-1}(1)) / unique_condition_num(3);  % minus
        end
        if abs(Vec_sum_slice{3*n-2}(1) - Vec_sum_slice{3*n}(1)) > 180
            SR_slice{n}(2) = ((Vec_sum_slice{3*n-2}(1)+360) - Vec_sum_slice{3*n}(1)) / (2*unique_condition_num(3));
        else
            SR_slice{n}(2) = (Vec_sum_slice{3*n-2}(1) - Vec_sum_slice{3*n}(1)) / (2*unique_condition_num(3));    % plusminus
        end
        if abs(Vec_sum_slice{3*n-1}(1) - Vec_sum_slice{3*n}(1)) > 180
            SR_slice{n}(3) = ((Vec_sum_slice{3*n-1}(1)+360) - Vec_sum_slice{3*n}(1)) / unique_condition_num(3);      
        else
            SR_slice{n}(3) = (Vec_sum_slice{3*n-1}(1) - Vec_sum_slice{3*n}(1)) / unique_condition_num(3);    % plus            
        end
    else
        SR_slice{n} = [NaN NaN NaN];  % n/a if vertical
    end
end


%     %----------------------------------------------------------
%     % Cross-covariance method for finding shift ratio ('displacement index', Avillac et al. 2005) - SLICE
%     
% bin = 1; % interval (in degrees) between interpolated points -- 360/bin must be an even integer
% method = 'linear';
% showplots = 0;
% x_values = [0 45 90 135 180 225 270 315 360];
% DI_slice{bin_num} = cross_covariance(resp_mat_slice, unique_stim_type, unique_condition_num, bin, method, showplots, x_values);


%     %----------------------------------------------------------
%     % Bootstrap DI's to classify significantly eye, head, intermed, or unclassif
%     
% bootstraps = 200;
% if bootstraps > 1
% 
% %tic
% for t = 1:bootstraps
%     if t/10 == floor(t/10)
%         FILE
%         t
%     end
%     resp_mat_boot = [];  % response matrix first
%     for k=1:length(unique_condition_num)
%         for n=1:length(unique_stim_type)
%             for i=1:length(unique_azimuth)
%                 select = logical( (azimuth==unique_azimuth(i)) & (elevation==0) & (condition_num==unique_condition_num(k)) & (stim_type==unique_stim_type(n)) );
%                 if (sum(select) > 0)
%                     spike_select = spike_rates(select);
%                     for r = 1:repetitions
%                         spike_select = spike_select( randperm(length(spike_select)));
%                         spike_bootstrap(r) = spike_select(1);   %(sampling with replacement)
%                     end
%                     resp_mat_boot(k, n, i) = mean(spike_bootstrap);
%                 else
%                     resp_mat_boot(k, n, i) = 0;                
%                 end
%             end        
%         end
%     end
%     
%     bin = 2; % interval (in degrees) between interpolated points -- 360/bin must be an even integer
%     method = 'linear';
%     showplots = 0;
%     x_values = [0 45 90 135 180 225 270 315 360];
%     DI_boot{t} = cross_covariance(resp_mat_boot, unique_stim_type, unique_condition_num, bin, method, showplots, x_values);
%     DI_avg_boot(t,:) = mean(DI_boot{t});
% end
% %toc
% 
% % For 95% confidence interval, clip off 2.5% of each side of the distribution
% clip = floor(bootstraps * .025);
% for n = 1:length(unique_stim_type)
% 
%     DI_avg_sort(:,n) = sort(DI_avg_boot(:,n));
%     DI_avg_95(:,n) = DI_avg_sort(clip + 1 : end - clip, n);
%     
%     % now assign head-centered, eye-centered, or intermediate based on whether confidence interval...
%     % includes 0 but not 1 (head):
%     if (DI_avg_95(end,n) >= 0 & DI_avg_95(1,n) <= 0) & ~(DI_avg_95(end,n) >= 1.0 & DI_avg_95(1,n) <= 1.0)
%         DI_frame(n) = 1;
%     % includes 1 but not 0 (eye):
%     elseif (DI_avg_95(end,n) >= 1.0 & DI_avg_95(1,n) <= 1.0) & ~(DI_avg_95(end,n) >= 0 & DI_avg_95(1,n) <= 0)
%         DI_frame(n) = 2;
%     % includes neither ('intermediate', including large/negative DI's):
%     elseif ~(DI_avg_95(end,n) >= 1.0 & DI_avg_95(1,n) <= 1.0) & ~(DI_avg_95(end,n) >= 0 & DI_avg_95(1,n) <= 0)
%         DI_frame(n) = 3;
%     % or includes both (unclassifiable):
%     else
%         DI_frame(n) = 4;
%     end
%     
% end
% 
% % % Plot histograms
% % for n = 1: length(unique_stim_type)
% %     figure(n*11);
% %     hist(DI_avg_sort(:,n));
% % end
% 
% % Save bootstrap distributions to .mat file
% save(['Z:\Users\Chris2\bootstraps\DI\' FILE(1:end-4) '.mat'], 'DI_avg_sort');
% 
% else
%     for n = 1:length(unique_stim_type)
%         DI_frame(n) = NaN;
%     end
% end
% 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % TEMPORARY - uncomment for batch DI_boot (and comment everything below)
% % 
% % if unique_stim_type == 1
% %     stim_text = 'Vestibular';
% % elseif unique_stim_type == 2
% %     stim_text = 'Visual';
% % else
% %     stim_text = 'Vestibular'; % (both, but ves first)
% % end
% % 
% % buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %s\t', FILE, DI_slice(:,1), DI_frame(1), stim_text);
% % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_VaryFix_DIBoot.dat'];
% % printflag = 0;
% % if (exist(outfile, 'file') == 0)    %file does not yet exist
% %     printflag = 1;
% % end
% % fid = fopen(outfile, 'a');
% % if (printflag)
% %     fprintf(fid, 'FILE\t DI_minus\t DI_plusminus\t DI_plus\t Frame\t Stim_type\t');
% %     fprintf(fid, '\r\n');
% % end
% % fprintf(fid, '%s', buff);
% % fprintf(fid, '\r\n');
% % fclose(fid);
% % 
% % % And another line if two stim types
% % if length(unique_stim_type) > 1
% %     stim_text = 'Visual';
% %     buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %s\t', FILE, DI_slice(:,2), DI_frame(2), stim_text);
% %     outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_VaryFix_DIBoot.dat'];
% % 	fid = fopen(outfile, 'a');
% % 	fprintf(fid, '%s', buff);
% % 	fprintf(fid, '\r\n');
% % 	fclose(fid);
% % end
% % 
% % end
% % toc
% % return;
% % 
% % % TEMPORARY - uncomment for batch DI_boot (and comment everything below)
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% 	%----------------------------------------------------------
% 	% Congruency metric: simple correlation between vis+ves (interpolated) tuning curves
% 
% if length(unique_stim_type) > 1
%     
% xi = 0 : bin : 359;
% resp_mat_360 = resp_mat_slice;
% for n = 1:length(unique_stim_type)
%     for k = 1:length(unique_condition_num)
%         resp_mat_360(k,n,length(x_values)) = resp_mat_slice(k,n,1);
%         clear temp_y;
%         for i = 1:length(x_values)
%             temp_y(i) = resp_mat_360(k,n,i);
%         end
%         yi{k,n} = interp1(x_values, temp_y, xi, method);
%     end
% end
% 
% corr_temp = corrcoef(yi{2,1},yi{2,2});
% congruency = corr_temp(1,2);
% 
% else
%     congruency = NaN;
% end
% 
%     %------------------------------------------------------------------
%     % Now show vectorsum, HTI, p, spontaneous, shift ratio, and DI at the top of figure
% 
% for n = 1:length(unique_stim_type)
%     figure(n+10);
%     axes('position',[0.02,0.83 0.31,0.12] );
%     xlim( [0,100] );
%     ylim( [0,length(unique_condition_num)+0.5] );
%     % removed p-perm for now
%     text(0.3,length(unique_condition_num),'Azi          Std         HTI       p-anova        Z        SR        DI');
%     for k=1:length(unique_condition_num)
%         K = [2 3 1];  % (for rot_data, which has shift ratios as plus, minus, plusminus)
%         if p_anova(k,n) < 0.001
%             p_anova(k,n) = 0; % round tiny p_anovas to zero, for display purposes
%         end            
%         h_text{k,n} = num2str( [Vec_sum_slice{k,n}(1), resp_std_slice(k,n), HTI_temp_slice(k,n), p_anova(k,n), Z(k,n), SR_slice{n}(k), DI_slice(k,n)], 4);
%         text(0.3,length(unique_condition_num)-k/2, h_text{k,n});
%     end
%     text(0.3, length(unique_condition_num)+0.4, FILE);
%     axis off;
% %    print; 
% %    close;
% end
% 
% %--------------------------------------------------------------------------------------------------------------------------------
% %--------------------------------------------------------------------------------------------------------------------------------
% % END horizontal plane slice code
% %--------------------------------------------------------------------------------------------------------------------------------
% %--------------------------------------------------------------------------------------------------------------------------------
end


%------------------------------------------------------------------
% 3D version of Displacement Index
% 
% bin = 1; % interval (in degrees) between interpolated points -- 360/bin must be an even integer
% method = 'linear';
% showplots = 0;
% DI_3D{bin_num} = cross_covariance_3D(resp_mat, unique_stim_type, unique_condition_num, bin, method, showplots);
% for n = 1:length(unique_stim_type)
%     DI_3D(:,n) = [NaN ; NaN ; NaN];
% end
% 
% clear temp;
% temp = mean(DI_slice{bin_num});
% DI_stim1(bin_num) = temp(1);
% if size(temp) == [1,2]
%     DI_stim2(bin_num) = temp(2);
% end
% 
% end % end of massive FOR loop from line 39
% 
% figure;
% plot(1:bin_num, DI_ves, 'k'); hold on;
% plot(1:bin_num, DI_vis, 'r'); hold on;
% plot(1:bin_num, DI_comb, 'b');
% set(gca, 'xtick', (0:2.5:20));
% set(gca, 'xticklabel','0|250|500|750|1000|1250|1500|1750|2000');
% xlabel('Time (ms)');
% ylabel('DI');
% title(FILE);
% print;
% ylim([-1 1.5]);
% ylabel('DI');
% print;
% close;
% 
% %--------------------------------------------------------------------------------------
% %---TEMP - DI vs. Time OUTPUT--------------------------------------------------------------
% %--------------------------------------------------------------------------------------
% gaze_dir = 0;
% dir_text = 'Horizontal';
% 
% if unique_stim_type == 1
%     stim_text = 'Vestibular';
%     save(['C:\MATLAB6p5\work\DI_vs_time\' FILE(1:end-4) '.mat'], 'DI_stim1');
% elseif unique_stim_type == 2
%     stim_text = 'Visual';
%     save(['C:\MATLAB6p5\work\DI_vs_time\' FILE(1:end-4) '.mat'], 'DI_stim1');
% else
%     stim_text = 'Vestibular'; % (both, but ves first)
%     save(['C:\MATLAB6p5\work\DI_vs_time\' FILE(1:end-4) '.mat'], 'DI_stim1', 'DI_stim2');
% end
% 
% buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %s', ...
%        FILE, DI_stim1, stim_text);
% outfile = ['C:\MATLAB6p5\work\DI_vs_time\DI_vs_time_3D.dat'];
% printflag = 0;
% if (exist(outfile, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile, 'a');
% if (printflag)
%     fprintf(fid, 'FILE\t');
%     fprintf(fid, '\r\n');
% end
% fprintf(fid, '%s', buff);
% fprintf(fid, '\r\n');
% fclose(fid);
% 
% % And another line if two stim types
% if length(unique_stim_type) > 1
%     stim_text = 'Visual';
%     buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %s', ...
%     FILE, DI_stim2, stim_text);
%     outfile = ['C:\MATLAB6p5\work\DI_vs_time\DI_vs_time_3D.dat'];
% 	fid = fopen(outfile, 'a');
% 	fprintf(fid, '%s', buff);
% 	fprintf(fid, '\r\n');
% 	fclose(fid);
% end
% %--------------------------------------------------------------------------------------
% %---end TEMP - DI vs. Time OUTPUT--------------------------------------------------------------
% %--------------------------------------------------------------------------------------
% return;





%------------------------------------------------------------------
% 'Displacement Index' in elevation, to determine whether the tuning shifts 
% orthogonal to the axis of the gaze shift
% bin = 8; % interval (in degrees) between interpolated points -- 360/bin must be an even integer
% method = 'linear';
% DI_3D_elev = cross_covariance_3D_elev(resp_mat, unique_stim_type, unique_condition_num, bin, method, Vec_sum, FILE);
% for n = 1:length(unique_stim_type)
%     DI_3D_elev(:,n) = [NaN ; NaN ; NaN];
% end

% % ********* VERTICAL SHIFT RATIO INSTEAD **********
% for n = 1:length(unique_stim_type)
%     SR_3D_elev(n) = ((Vec_sum{2+3*(n-1)}(2) - Vec_sum{1+3*(n-1)}(2)) / unique_condition_num(3) + ...
%                      (Vec_sum{3+3*(n-1)}(2) - Vec_sum{2+3*(n-1)}(2)) / unique_condition_num(3) + ...
%                      (Vec_sum{3+3*(n-1)}(2) - Vec_sum{1+3*(n-1)}(2)) / unique_condition_num(3)) / 3;
% end
% 
% %Bootstrap SR_3D_elevs to determine significance of elevation shift
% tic
% bootstraps = 1000;
% for t = 1:bootstraps
%     if t/100 == floor(t/100)
%         FILE
%         t
%     end
%     resp_mat_boot = [];  % response matrix first
%     for k=1:length(unique_condition_num)
%         for n=1:length(unique_stim_type)
%             for i=1:length(unique_azimuth)
%                 for j=1:length(unique_elevation)
%                     select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) & (stim_type==unique_stim_type(n)) );
%                     if (sum(select) > 0)
%                         spike_select = spike_rates(select);
%                         for r = 1:repetitions
%                             spike_select = spike_select( randperm(length(spike_select)));
%                             spike_bootstrap(r) = spike_select(1);   %(sampling with replacement)
%                         end
%                         resp_mat_boot((k+3*(n-1)), j, i) = mean(spike_bootstrap);
%                     else
%                         resp_mat_boot((k+3*(n-1)), j, i) = 0;                
%                     end
%                 end
%             end        
%             N=squeeze(resp_mat_boot((k+3*(n-1)),:,:));
%             [Azi, Ele, Amp] = vectorsum(N);
%             Vec_sum_boot{(k+3*(n-1))} = [Azi, Ele, Amp];
%         end
%     end
%     for n=1:length(unique_stim_type)
%         SR_avg_boot(t,n) = ((Vec_sum_boot{2+3*(n-1)}(2) - Vec_sum_boot{1+3*(n-1)}(2)) / unique_condition_num(3) + ...
%                             (Vec_sum_boot{3+3*(n-1)}(2) - Vec_sum_boot{2+3*(n-1)}(2)) / unique_condition_num(3) + ...
%                             (Vec_sum_boot{3+3*(n-1)}(2) - Vec_sum_boot{1+3*(n-1)}(2)) / unique_condition_num(3)) / 3;
%     end
% end
% toc
% 
% % For 95% confidence interval, clip off 2.5% of each side of the distribution
% clip = floor(bootstraps * .025);
% for n = 1:length(unique_stim_type)
% 
%     SR_avg_sort(:,n) = sort(SR_avg_boot(:,n));
%     SR_avg_95(:,n) = SR_avg_sort(clip + 1 : end - clip, n);
%     
%     % now assign head-centered, eye-centered, or intermediate based on whether confidence interval...
%     % includes 0 but not 1 (head):
%     if (SR_avg_95(end,n) >= 0 & SR_avg_95(1,n) <= 0) & ~(SR_avg_95(end,n) >= 1.0 & SR_avg_95(1,n) <= 1.0)
%         SR_frame(n) = 1;
%     % includes 1 but not 0 (eye):
%     elseif (SR_avg_95(end,n) >= 1.0 & SR_avg_95(1,n) <= 1.0) & ~(SR_avg_95(end,n) >= 0 & SR_avg_95(1,n) <= 0)
%         SR_frame(n) = 2;
%     % includes neither ('intermediate', including large/negative SR's):
%     elseif ~(SR_avg_95(end,n) >= 1.0 & SR_avg_95(1,n) <= 1.0) & ~(SR_avg_95(end,n) >= 0 & SR_avg_95(1,n) <= 0)
%         SR_frame(n) = 3;
%     % or includes both (unclassifiable):
%     else
%         SR_frame(n) = 4;
%     end
%     
% end
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % TEMPORARY - for SR_3D_elev output (can uncomment everything below when done)
% if unique_stim_type == 1
%     stim_text = 'Vestibular';
% elseif unique_stim_type == 2
%     stim_text = 'Visual';
% else
%     stim_text = 'Vestibular'; % (both, but ves first)
% end
% 
% buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %s\t', FILE, mean(HTI_temp(1:3)), SR_3D_elev(1), SR_frame(1), stim_text);
% outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_VaryFix_3DSRelev.dat'];
% printflag = 0;
% if (exist(outfile, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile, 'a');
% if (printflag)
%     fprintf(fid, 'FILE\t mean_HTI\t SR_elev_avg\t SR_frame\t Stim_type\t');
%     fprintf(fid, '\r\n');
% end
% fprintf(fid, '%s', buff);
% fprintf(fid, '\r\n');
% fclose(fid);
% 
% % And another line if two stim types
% if length(unique_stim_type) > 1
%     stim_text = 'Visual';
%     buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %s\t', FILE, mean(HTI_temp(4:6)), SR_3D_elev(2), SR_frame(2), stim_text);
%     outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_VaryFix_3DSRelev.dat'];
% 	fid = fopen(outfile, 'a');
% 	fprintf(fid, '%s', buff);
% 	fprintf(fid, '\r\n');
% 	fclose(fid);
% end
% 
% return;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %----------------------------------------------------------
% %Bootstrap 3D_DI's to classify significantly eye, head, intermed, or unclassif
% 
% bootstraps = 1;
% if bootstraps > 1
% % tic
% 
% for t = 1:bootstraps
%     if t/10 == floor(t/10)
%         FILE
%         t
%     end
%     resp_mat_boot = [];  % response matrix first
%     for k=1:length(unique_condition_num)
%         for n=1:length(unique_stim_type)
%             for i=1:length(unique_azimuth)
%                 for j=1:length(unique_elevation)
%                     select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) & (stim_type==unique_stim_type(n)) );
%                     if (sum(select) > 0)
%                         spike_select = spike_rates(select);
%                         for r = 1:repetitions
%                             spike_select = spike_select( randperm(length(spike_select)));
%                             spike_bootstrap(r) = spike_select(1);   %(sampling with replacement)
%                         end
%                         resp_mat_boot((k+3*(n-1)), j, i) = mean(spike_bootstrap);
%                     else
%                         resp_mat_boot((k+3*(n-1)), j, i) = 0;                
%                     end
%                 end
%             end        
%         end
%     end
%     
%     bin = 2; % interval (in degrees) between interpolated points -- 360/bin must be an even integer
%     method = 'linear';
%     showplots = 0;
%     DI_boot{t} = cross_covariance_3D(resp_mat_boot, unique_stim_type, unique_condition_num, bin, method, showplots);
%     DI_avg_boot(t,:) = mean(DI_boot{t});
% end
% 
% % For 95% confidence interval, clip off 2.5% of each side of the distribution
% clip = floor(bootstraps * .025);
% for n = 1:length(unique_stim_type)
% 
%     DI_avg_sort(:,n) = sort(DI_avg_boot(:,n));
%     DI_avg_95(:,n) = DI_avg_sort(clip + 1 : end - clip, n);
%     
%     % now assign head-centered, eye-centered, or intermediate based on whether confidence interval...
%     % includes 0 but not 1 (head):
%     if (DI_avg_95(end,n) >= 0 & DI_avg_95(1,n) <= 0) & ~(DI_avg_95(end,n) >= 1.0 & DI_avg_95(1,n) <= 1.0)
%         DI_frame(n) = 1;
%     % includes 1 but not 0 (eye):
%     elseif (DI_avg_95(end,n) >= 1.0 & DI_avg_95(1,n) <= 1.0) & ~(DI_avg_95(end,n) >= 0 & DI_avg_95(1,n) <= 0)
%         DI_frame(n) = 2;
%     % includes neither ('intermediate', including large/negative DI's):
%     elseif ~(DI_avg_95(end,n) >= 1.0 & DI_avg_95(1,n) <= 1.0) & ~(DI_avg_95(end,n) >= 0 & DI_avg_95(1,n) <= 0)
%         DI_frame(n) = 3;
%     % or includes both (unclassifiable):
%     else
%         DI_frame(n) = 4;
%     end
%     
% end
% % toc
% 
% % % Plot histograms
% % for n = 1: length(unique_stim_type)
% %     figure(n*11);
% %     hist(DI_avg_sort(:,n));
% % end
% 
% % Save bootstrap distributions to .mat file
% save(['Z:\Users\Chris2\bootstraps\DI_3D\' FILE(1:end-4) '.mat'], 'DI_avg_sort');
% 
% else
%     for n = 1:length(unique_stim_type)
%         DI_frame(n) = NaN;
%     end
% end
% 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % TEMPORARY - uncomment for batch DI_boot (and comment everything below)
% % 
% % if unique_stim_type == 1
% %     stim_text = 'Vestibular';
% % elseif unique_stim_type == 2
% %     stim_text = 'Visual';
% % else
% %     stim_text = 'Vestibular'; % (both, but ves first)
% % end
% % 
% % buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %s\t', FILE, DI_3D(:,1), DI_frame(1), stim_text);
% % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_VaryFix_3DDIBoot.dat'];
% % printflag = 0;
% % if (exist(outfile, 'file') == 0)    %file does not yet exist
% %     printflag = 1;
% % end
% % fid = fopen(outfile, 'a');
% % if (printflag)
% %     fprintf(fid, 'FILE\t DI_minus\t DI_plusminus\t DI_plus\t Frame\t Stim_type\t');
% %     fprintf(fid, '\r\n');
% % end
% % fprintf(fid, '%s', buff);
% % fprintf(fid, '\r\n');
% % fclose(fid);
% % 
% % % And another line if two stim types
% % if length(unique_stim_type) > 1
% %     stim_text = 'Visual';
% %     buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %s\t', FILE, DI_3D(:,2), DI_frame(2), stim_text);
% %     outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_VaryFix_3DDIBoot.dat'];
% % 	fid = fopen(outfile, 'a');
% % 	fprintf(fid, '%s', buff);
% % 	fprintf(fid, '\r\n');
% % 	fclose(fid);
% % end
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






%------------------------------------------------------------------
% Define figure

for n=1:length(unique_stim_type)
    xoffset=0;
    yoffset=0;
    figure(n+1);
    orient landscape;
    set(n+1,'Position', [5+1200*(n-1),-120 1200,900], 'Name', '3D Direction Tuning');
    axis off;

    % for cosine plot (Lambert projection)
    azi_cos = [1,2,3,4,5,6,7,8,9];
    ele_sin = [-1,-0.707,0,0.707,1];

    for k=1: length(unique_condition_num) 
        if (xoffset > 0.5)          % now temperarily 2 pictures one row and 2 one column
            yoffset = yoffset-0.4;
            xoffset = 0;
        end
        axes('position',[0.11+xoffset 0.54+yoffset 0.32 0.24]);
 
        contourf(azi_cos, ele_sin, squeeze( resp_mat_tran((k+3*(n-1)),:,:)) );
        caxis([min(Min_resp(3*n-2:3*n)) max(Max_resp(3*n-2:3*n))]);
%         colormap gray_reverse;  % For grayscale
        colorbar;
        % make 0 correspond to rightward and 180 correspond to leftward
        set(gca, 'ydir' , 'reverse');
        set(gca, 'xtick', [] );
        set(gca, 'ytick', [] );
        title( h_title{(k+3*(n-1))} );
	
        % plot 1-D for mean respond as a function of elevation
        axes('position',[0.06+xoffset 0.54+yoffset 0.04 0.24]);
        for j=1:length(unique_elevation)
            y_elevation_mean(1,j)=mean(resp_mat_tran((k+3*(n-1)),j,:));
            y_elevation_std(1,j) =std( spike_rates([find( (elevation==unique_elevation(j))&(condition_num==unique_condition_num(k))& (stim_type==unique_stim_type(n)) )]) );
            y_elevation_ste(1,j) =y_elevation_std(1,j)/ sqrt(length(find( (elevation==unique_elevation(j))&(condition_num==unique_condition_num(k))& (stim_type==unique_stim_type(n)) )) );
        end
%         x_elevation=-90:45:90;
        % Instead, transform scale by cosine (Lambert proj):
        x_elevation = [-1,-0.707,0,0.707,1];
        errorbar(x_elevation,y_elevation_mean,y_elevation_ste,'o-');
        xlabel('Elevation');
        view(90,90);
%         set(gca, 'xtick',[-90,-45,0,45,90]);
%         xlim([-90, 90]);
        set(gca, 'xtick',[-1,-0.707,0,0.707,1]);
        xlim([-1, 1]);

        ylim([min(y_elevation_mean(1,:))-max(y_elevation_ste(1,:)), max(y_elevation_mean(1,:))+max(y_elevation_ste(1,:))]);
	
        % plot 1-D for mean respond as a function of azimuth
        axes('position',[0.11+xoffset 0.46+yoffset 0.274 0.06]);
        for i=1:(length(unique_azimuth) )
            y_azimuth_mean(1,i)=mean(resp_mat_tran(k,:,i));
            y_azimuth_std(1,i) =std( spike_rates([find( (azimuth==unique_azimuth(i))&(condition_num==unique_condition_num(k))& (stim_type==unique_stim_type(n)) )]) );
            y_azimuth_ste(1,i) =y_azimuth_std(1,i)/ sqrt(length(find( (azimuth==unique_azimuth(i))&(condition_num==unique_condition_num(k))& (stim_type==unique_stim_type(n)) )) );    
        end
        y_azimuth_mean(1,9) = mean(resp_mat_tran((k+3*(n-1)),:,1));
        for i=1:( length(unique_azimuth)+1 )
            if (i < 8)        
                y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,8-i);
            elseif (i == 8)
                y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,8);
            else
                y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,7);
            end
        end
        x_azimuth=1:(length(unique_azimuth)+1);
        errorbar(x_azimuth,y_azimuth_mean,y_azimuth_ste_tran,'o-');
        xlim( [1, length(unique_azimuth)+1] );
        set(gca, 'xticklabel','270|225|180|135|90|45|0|-45|-90');
        xlabel('Azimuth');
        ylim([min(y_azimuth_mean(1,:))-max(y_azimuth_ste(1,:)), max(y_azimuth_mean(1,:))+max(y_azimuth_ste(1,:))]);
        xoffset=xoffset+0.48;
    end
end

%-------------------------------------------------------------------
%check significance of HTI and calculate p value (permutation test)
%
% perm_num = input('enter perm num:');
perm_num = 10;
bin = 0.005;
% tic
for m=1: perm_num 
    for n = 1: length(unique_stim_type)
        for k = 1: length(unique_condition_num)
            spike_rates_pe{(k+3*(n-1))} = spike_rates( find( condition_num==unique_condition_num(k) & stim_type==unique_stim_type(n) )  );
            spike_rates_pe{(k+3*(n-1))} = spike_rates_pe{(k+3*(n-1))}( randperm(length(spike_rates_pe{(k+3*(n-1))})) );
% old way:  spike_rates_perm=[spike_rates_perm,spike_rates_pe{(k+3*(n-1))}];  % get the permuted spikerate to re-calculate HTI for each condition
        end
    end

    % new, correct way to re-assign spike_rates_pe to appropriate indices in spike_rates_perm (10/12/04)
    spike_rates_perm = [];
    spike_rates_perm(length(spike_rates))=0;
    for n = 1: length(unique_stim_type)
        for k=1:length(unique_condition_num) 
            ii = find(condition_num == unique_condition_num(k) & stim_type == unique_stim_type(n));
            spike_rates_perm(ii) = spike_rates_pe{(k+3*(n-1))};
        end
    end
    
    % re-creat a matrix similar as resp_mat              
    resp_vector_perm = [];
    for n=1:length(unique_stim_type)
        for i=1:length(unique_azimuth)
            for j=1:length(unique_elevation)
                for k=1:length(unique_condition_num)
                    select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) );
                    if (sum(select) > 0)
                        resp_mat_perm((k+3*(n-1)),j,i) = mean(spike_rates_perm(select));
                        resp_mat_perm_std((k+3*(n-1)),j,i) = std(spike_rates_perm(select));
                    else
                        resp_mat_perm((k+3*(n-1)),j,i) = 0;
                        resp_mat_perm_std((k+3*(n-1)),j,i) = 0;
                    end
                end        
            end
        end
    end
    % re-calculate HTI now
    for n=1:length(unique_stim_type)
        for k=1: length(unique_condition_num)
            resp_perm_std((k+3*(n-1))) = sum( sum(resp_mat_perm_std((k+3*(n-1)),:,:)) ) / vector_num; 
            M_perm=squeeze(resp_mat_perm((k+3*(n-1)),:,:));
         %   DSI_perm((k+3*(n-1)),m) = DSI(M_perm, spon_resp(k), resp_perm_std((k+3*(n-1))) );
            HTI_perm((k+3*(n-1)),m) = HTI(M_perm, spon_resp(k));
        end
    end
end

x_bin = 0 : bin : 1;
for n = 1 : length(unique_stim_type)
    for k = 1 : length(unique_condition_num)
        histo((k+3*(n-1)),:) = hist( HTI_perm((k+3*(n-1)),:), x_bin );
        bin_sum = 0;
        m = 0;
        while ( m < (HTI_temp((k+3*(n-1)))/bin) )
              m = m+1;
              bin_sum = bin_sum + histo((k+3*(n-1)),m);
              p(k+3*(n-1)) = (perm_num - bin_sum)/ perm_num;    % calculate p value
        end 
    end
end
% toc


%------------------------------------------------------------------
% Now show spon, vectorsum, HTI, p and DI at the top of figure

% define gaze_dir = 0 for horizontal gaze shift or 1 for vertical
if length(unique_fix_y) == 1
    gaze_dir = 0;
    dir_text = 'Horizontal';
else
    gaze_dir = 1;
    dir_text = 'Vertical';
end

for n = 1:length(unique_stim_type)
    figure(n+1);
    axes('position',[0.05,0.85, 0.9,0.1] );
    xlim( [0,100] );
    ylim( [0,length(unique_condition_num)] );
    h_spon = num2str(spon_resp);
    text(0, length(unique_condition_num), FILE);
    text(15,length(unique_condition_num),'Spon          Minimum        Maximum       Azi             Ele                Amp           Std             HTI                   p                  DI');
    text(0, length(unique_condition_num)-0.5, dir_text);
    for k=1:length(unique_condition_num) 
        h_text{(k+3*(n-1))}=num2str( [spon_resp(k), Min_resp((k+3*(n-1))), Max_resp((k+3*(n-1))), Vec_sum{(k+3*(n-1))}, resp_std((k+3*(n-1))), HTI_temp((k+3*(n-1))), p(k+3*(n-1)), DI_3D(k,n) ] );
        text(0,length(unique_condition_num)-k, h_title{(k+3*(n-1))});
        text(15,length(unique_condition_num)-k, h_text{(k+3*(n-1))});
    end
    axis off;
%    print;
%    close;
end
 
%---------------------------------------------------------------------------------------
% Calculate rotated vectors ('eye-centered' prediction) from the vectorsum and their difference angles 
% (see rotation.m) and show the vectors graphically in a second figure.  -- OBSOLETE: see below
%
% for n = 1: length(unique_stim_type)
%     [exp_plus, exp_minus, shift_ratio_plus, shift_ratio_minus, shift_ratio_plusminus, noise_ratio_plus, noise_ratio_minus, noise_ratio_plusminus] = rotation_no_plots(Vec_sum{3*n-1}, Vec_sum{3*n}, Vec_sum{3*n-2}, unique_condition_num(3), gaze_dir);
%     [exp_plus, exp_minus, shift_ratio_plus, shift_ratio_minus, shift_ratio_plusminus, noise_ratio_plus, noise_ratio_minus, noise_ratio_plusminus] = rotation_no_plots(Vec_sum{3*n-1}, Vec_sum{3*n}, Vec_sum{3*n-2}, unique_condition_num(3), gaze_dir, n+3);
%     axes('position',[0.05,0.75, 0.9,0.2] );
%     title(FILE);
%     xlim([0,10]);
%     ylim([0,10]);
%     text(2.5,10,'Azi               Ele              Amp');
%     text(0,9,'Actual minus (magenta) ='); text(2.5,9,num2str(Vec_sum{3*n-2}));
%     text(0,8,'Zero vector (green) ='); text(2.5,8,num2str(Vec_sum{3*n-1}));
%     text(0,7,'Actual plus (cyan) ='); text(2.5,7,num2str(Vec_sum{3*n}));
%     text(0,5,'Expected minus (red) ='); text(2.5,5,num2str(exp_minus));
%     text(0,4,'Zero vector (green) ='); text(2.5,4,num2str(Vec_sum{3*n-1}));
%     text(0,3,'Expected plus (blue) ='); text(2.5,3,num2str(exp_plus));
%     text(6,9,'Shift Ratio, Plus ='); text(8,9,num2str(shift_ratio_plus));
%     text(6,8,'Shift Ratio, Minus ='); text(8,8,num2str(shift_ratio_minus));
%     text(6,7,'Shift Ratio, PlusMinus ='); text(8.2,7,num2str(shift_ratio_plusminus));
%     text(6,5,'Noise Ratio, Plus ='); text(8,5,num2str(noise_ratio_plus));
%     text(6,4,'Noise Ratio, Minus ='); text(8,4,num2str(noise_ratio_minus));
%     text(6,3,'Noise Ratio, PlusMinus ='); text(8.2,3,num2str(noise_ratio_plusminus));
%     text(0,10,dir_text);
%     axis off;
%     rot_data{n} = [shift_ratio_plus, shift_ratio_minus, shift_ratio_plusminus];
%     rot_data2{n} = [exp_plus, exp_minus, shift_ratio_plus, shift_ratio_minus, shift_ratio_plusminus, noise_ratio_plus, noise_ratio_minus, noise_ratio_plusminus];
% end

% For horizontal gaze shifts, compute 'true' shift ratio (using only
% azimuths), because rotation.m may be overestimating the SR for cells with a
% substantial elevation component.
for n = 1:length(unique_stim_type)
    if gaze_dir == 0
        if abs(Vec_sum{3*n-2}(1) - Vec_sum{3*n-1}(1)) > 180
            SR_true{n}(1) = ((Vec_sum{3*n-2}(1)+360) - Vec_sum{3*n-1}(1)) / unique_condition_num(3);
        else
            SR_true{n}(1) = (Vec_sum{3*n-2}(1) - Vec_sum{3*n-1}(1)) / unique_condition_num(3);  % minus
        end
        if abs(Vec_sum{3*n-2}(1) - Vec_sum{3*n}(1)) > 180
            SR_true{n}(2) = ((Vec_sum{3*n-2}(1)+360) - Vec_sum{3*n}(1)) / (2*unique_condition_num(3));
        else
            SR_true{n}(2) = (Vec_sum{3*n-2}(1) - Vec_sum{3*n}(1)) / (2*unique_condition_num(3));    % plusminus
        end
        if abs(Vec_sum{3*n-1}(1) - Vec_sum{3*n}(1)) > 180
            SR_true{n}(3) = ((Vec_sum{3*n-1}(1)+360) - Vec_sum{3*n}(1)) / unique_condition_num(3);      
        else
            SR_true{n}(3) = (Vec_sum{3*n-1}(1) - Vec_sum{3*n}(1)) / unique_condition_num(3);    % plus            
        end
    else
        SR_true{n} = [NaN NaN NaN];  % n/a if vertical
    end
end
 

% -------------------------------------------------------------------------
% Gain Field test (ANOVA of individual trial data across gaze angles)

% parse raw data into repetitions, including null trials
for q = 1 : repetitions
    azimuth_rep{q} = temp_azimuth(trials_per_rep*(q-1)+1 : trials_per_rep*q);
    elevation_rep{q} = temp_elevation(trials_per_rep*(q-1)+1 : trials_per_rep*q);
    stim_type_rep{q} = temp_stim_type(trials_per_rep*(q-1)+1 : trials_per_rep*q);
    condition_num_rep{q} = temp_condition_num(trials_per_rep*(q-1)+1 : trials_per_rep*q);
    spike_rates_rep{q} = temp_spike_rates(trials_per_rep*(q-1)+1 : trials_per_rep*q);
    spike_data_rep{q} = temp_spike_data( (BegTrial-1)*5000 + ((q-1)*trials_per_rep*5000) + 1 : q*trials_per_rep*5000 + (BegTrial-1)*5000 );
    event_data_rep{q} = temp_event_data( (BegTrial-1)*5000 + ((q-1)*trials_per_rep*5000) + 1 : q*trials_per_rep*5000 + (BegTrial-1)*5000 );
end

clear x y P f c;
for n=1:length(unique_stim_type)
    for k=1:length(unique_condition_num)
        % max and min of response matrix (means) at each stim/gaze condition
        whereis_max = logical(resp_mat == Max_resp(k+3*(n-1)));
        whereis_max = squeeze(whereis_max(k+3*(n-1),:,:));
        [max_ele max_azi] = find(whereis_max);
        if length(max_ele) > 1  % need these to be unique, and believe it or not they sometimes aren't
            max_ele = max_ele(1);
        end
        if length(max_azi) > 1
            max_azi = max_azi(1);
        end
        max_ele = unique_elevation(max_ele);
        max_azi = unique_azimuth(max_azi);

        whereis_min = logical(resp_mat == Min_resp(k+3*(n-1)));
        whereis_min = squeeze(whereis_min(k+3*(n-1),:,:));
        [min_ele min_azi] = find(whereis_min);
        min_ele = unique_elevation(min_ele);
        min_azi = unique_azimuth(min_azi);
        if length(min_ele) > 1
            min_ele = min_ele(1);
        end
        if length(min_azi) > 1
            min_azi = min_azi(1);
        end
      
        % now for each rep, calculate max-min and max-spontaneous
        clear q;
        for q = 1: length(spike_rates_rep)
            if abs(max_ele) == 90  % can't require a particular azimuth for +/- 90 elevation
                max_index = find(elevation_rep{q}==max_ele & condition_num_rep{q}==unique_condition_num(k) & stim_type_rep{q}==unique_stim_type(n));
            else
                max_index = find(azimuth_rep{q}==max_azi & elevation_rep{q}==max_ele & condition_num_rep{q}==unique_condition_num(k) & stim_type_rep{q}==unique_stim_type(n));
            end
            if abs(min_ele) == 90
                min_index = find(elevation_rep{q}==min_ele & condition_num_rep{q}==unique_condition_num(k) & stim_type_rep{q}==unique_stim_type(n));
            else
                min_index = find(azimuth_rep{q}==min_azi & elevation_rep{q}==min_ele & condition_num_rep{q}==unique_condition_num(k) & stim_type_rep{q}==unique_stim_type(n));
            end
            spon_index = find(stim_type_rep{q} == -9999 & condition_num_rep{q} == unique_condition_num(k));
            
            max_allreps{n}(q,k) = spike_rates_rep{q}(max_index);
            spon_allreps{n}(q,k) = spike_rates_rep{q}(spon_index);
            max_min_allreps{n}(q,k) = spike_rates_rep{q}(max_index) - spike_rates_rep{q}(min_index);
            max_spon_allreps{n}(q,k) = spike_rates_rep{q}(max_index) - spike_rates_rep{q}(spon_index);
            x(q,k) = unique_condition_num(k);
        end
    end
    
    % simple monotonic test: if max-spon at zero gaze is sig > or < than at both
    % eccentric gaze angles, then GF is non-monotonic
    clear resp_minus resp_zero resp_plus;
    resp_minus = max_spon_allreps{n}(:,1); resp_zero = max_spon_allreps{n}(:,2); resp_plus = max_spon_allreps{n}(:,3);
    if ((mean(resp_zero) > mean(resp_plus) & mean(resp_zero) > mean(resp_minus)) | (mean(resp_zero) < mean(resp_plus) & mean(resp_zero) < mean(resp_minus))) & (ttest2(resp_zero, resp_plus) == 1 & ttest2(resp_zero, resp_minus) == 1)
        monotonic(n) = 0;
    else
        monotonic(n) = 1;
    end
    
    p_anova_max(n) = anova1(max_allreps{n},[],'off');
    p_anova_spon(n) = anova1(spon_allreps{n},[],'off');
    p_anova_maxmin(n) = anova1(max_min_allreps{n},[],'off');
    p_anova_maxspon(n) = anova1(max_spon_allreps{n},[],'off');
    gf_anovas{n} = [p_anova_max(n) p_anova_spon(n) p_anova_maxmin(n) p_anova_maxspon(n)];
    
    p_KW_max(n) = kruskalwallis(max_allreps{n},[],'off');
    p_KW_spon(n) = kruskalwallis(spon_allreps{n},[],'off');
    p_KW_maxmin(n) = kruskalwallis(max_min_allreps{n},[],'off');
    p_KW_maxspon(n) = kruskalwallis(max_spon_allreps{n},[],'off');
    gf_KWs{n} = [p_KW_max(n) p_KW_spon(n) p_KW_maxmin(n) p_KW_maxspon(n)];
    
    y = max_allreps{n};
    p = polyfit(x,y,1);
    f = polyval(p,x);
    [c,P] = corrcoef(f,y);
    GFr_max(n) = c(1,2);
    GFp_max(n) = P(1,2);
    GFslope_max(n) = p(1);
    
    y = spon_allreps{n};
    p = polyfit(x,y,1);
    f = polyval(p,x);
    [c,P] = corrcoef(f,y);
    GFr_spon(n) = c(1,2);
    GFp_spon(n) = P(1,2);
    GFslope_spon(n) = p(1);
    
    y = max_min_allreps{n};
    p = polyfit(x,y,1);
    f = polyval(p,x);
    [c,P] = corrcoef(f,y);
    GFr_maxmin(n) = c(1,2);
    GFp_maxmin(n) = P(1,2);
    GFslope_maxmin(n) = p(1);
    
    y = max_spon_allreps{n};
    p = polyfit(x,y,1);
    f = polyval(p,x);
    [c,P] = corrcoef(f,y);
    GFr_maxspon(n) = c(1,2);
    GFp_maxspon(n) = P(1,2);
    GFslope_maxspon(n) = p(1);
    
end
 
 

% %--------------------------------------------------------------------------------------
% % TEMP TEMP TEMP -- new GF data
% 
% gaze_dir = 0;
% dir_text = 'Horizontal';
% 
% if unique_stim_type == 1
%     stim_text = 'Vestibular';
% elseif unique_stim_type == 2
%     stim_text = 'Visual';
% else
%     stim_text = 'Vestibular'; % (both, but ves first)
% end
% % buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %3.0f\t %s\t %s\t', ...
% %        FILE, spon_resp, Min_resp(1:3), Max_resp(1:3), Vec_sum{1:3}, HTI_temp(1:3), resp_std(1:3), gf_anovas{1}, gf_KWs{1}, GFr_max(1), GFp_max(1), GFslope_max(1), GFr_spon(1), GFp_spon(1), GFslope_spon(1), GFr_maxmin(1), GFp_maxmin(1), GFslope_maxmin(1), GFr_maxspon(1), GFp_maxspon(1), GFslope_maxspon(1), EndTrial-(BegTrial-1), stim_text, dir_text);
%        % currently 72 fields (11/05)
% buff = sprintf('%s\t %6.3f\t %s\t', FILE, monotonic(1), stim_text);
% % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_Vary_Fixation_Sum.dat'];
% outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\monotonic_3D.dat'];
% printflag = 0;
% if (exist(outfile, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile, 'a');
% if (printflag)
%     fprintf(fid, 'FILE\t Spon_minus\t Spon_zero\t Spon_plus\t Min_minus\t Min_zero\t Min_plus\t Max_minus\t Max_zero\t Max_plus\t Azi_minus\t Ele_minus\t Amp_minus\t Azi_zero\t Ele_zero\t Amp_zero\t Azi_plus\t Ele_plus\t Amp_plus\t HTI_minus\t HTI_zero\t HTI_plus\t Std_minus\t Std_zero\t Std_plus\t ANOVA_max\t ANOVA_spon\t ANOVA_maxmin\t ANOVA_maxspon\t KW_max\t KW_spon\t KW_maxmin\t KW_maxspon\t GF_r_max\t GF_p_max\t GF_slope_max\t GF_r_spon\t GF_p_spon\t GF_slope_spon\t GF_r_maxmin\t GF_p_maxmin\t GF_slope_maxmin\t GF_r_maxspon\t GF_p_maxspon\t GF_slope_maxspon\t Num_trials\t Stim_type\t Gaze_dir');
%     fprintf(fid, '\r\n');
% end
% fprintf(fid, '%s', buff);
% fprintf(fid, '\r\n');
% fclose(fid);
% 
% % And another line if two stim types
% if length(unique_stim_type) > 1
%     stim_text = 'Visual';
% %     buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %3.0f\t %s\t %s\t', ...
% %            FILE, spon_resp, Min_resp(4:6), Max_resp(4:6), Vec_sum{4:6}, HTI_temp(4:6), resp_std(4:6), gf_anovas{2}, gf_KWs{2}, GFr_max(2), GFp_max(2), GFslope_max(2), GFr_spon(2), GFp_spon(2), GFslope_spon(2), GFr_maxmin(2), GFp_maxmin(2), GFslope_maxmin(2), GFr_maxspon(2), GFp_maxspon(2), GFslope_maxspon(2), EndTrial-(BegTrial-1), stim_text, dir_text);
%     buff = sprintf('%s\t %6.3f\t %s\t', FILE, monotonic(2), stim_text);
%     outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_Vary_Fixation_Sum.dat'];
% 	fid = fopen(outfile, 'a');
% 	fprintf(fid, '%s', buff);
% 	fprintf(fid, '\r\n');
% 	fclose(fid);
% end
% 
% return;
% %--------------------------------------------------------------------------------------
% % TEMP TEMP TEMP -- new GF data
% 
%  
%  
%  
% % -------------------------------------------------------------------------
% % Response Latency (sliding ANOVA method -- Avillac et al. 2005)
% 
% clear baseline_spikes stim_spikes latency;
% for n = 1:length(unique_stim_type)
%     for k = 1:length(unique_condition_num)
%         for q = 1:repetitions
%             clear max_index max_events max_spikes;
%             if abs(max_ele) == 90  % can't require a particular azimuth for +/- 90 elevation
%                 max_index = find(elevation_rep{q}==max_ele & condition_num_rep{q}==unique_condition_num(k) & stim_type_rep{q}==unique_stim_type(n));
%             else
%                 max_index = find(azimuth_rep{q}==max_azi & elevation_rep{q}==max_ele & condition_num_rep{q}==unique_condition_num(k) & stim_type_rep{q}==unique_stim_type(n));
%             end
%             max_events = event_data_rep{q}(((max_index-1)*5000)+1 : max_index*5000);
%             max_spikes = spike_data_rep{q}(((max_index-1)*5000)+1 : max_index*5000);
%         % for baseline, take 100 ms window before stimulus onset (event code '4')
%             baseline_spikes{k,n}(q) = sum(max_spikes(find(max_events==4)-100 : find(max_events==4)-1));
%             stim_spikes{k,n}(q,:) = max_spikes(find(max_events==4) : end);
%         end
% 
%         % now compare baseline rate to rate in a sliding 20 ms window moving through 'stim_spikes'
%         p_anova_latency = 1;
%         T = 1;
%         while p_anova_latency >= 0.05 | mean((sum(stim_spikes{k,n}(:,T:19+T)')'*50)) <= mean((baseline_spikes{k,n}')*10)
%             p_anova_latency = anova1([sum(stim_spikes{k,n}(:,T:19+T)')'*50 (baseline_spikes{k,n}')*10], [] , 'off');
%             T = T + 1;
%             if T == 1981
%                 break;
%             end
%             
% %             if floor(T/20) == T/20
% %                 T
% %                 [sum(stim_spikes{k,n}(:,T:19+T)')'*50 (baseline_spikes{k,n}')*10]
% %                 p_anova_latency
% %                 pause;
% %             end            
%             
%         end
%         latency(k,n) = T + 19
%         
%     end
% end
% 
% 
% % %--------------------------------------------------------------------------------------
% % %---TEMP - LATENCY OUTPUT--------------------------------------------------------------
% % %--------------------------------------------------------------------------------------
% % gaze_dir = 0;
% % dir_text = 'Horizontal';
% % 
% % if unique_stim_type == 1
% %     stim_text = 'Vestibular';
% % elseif unique_stim_type == 2
% %     stim_text = 'Visual';
% % else
% %     stim_text = 'Vestibular'; % (both, but ves first)
% % end
% % buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %s\t', FILE, latency(:,1), stim_text);
% % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_Vary_Fixation_Latency.dat'];
% % printflag = 0;
% % if (exist(outfile, 'file') == 0)    %file does not yet exist
% %     printflag = 1;
% % end
% % fid = fopen(outfile, 'a');
% % if (printflag)
% %     fprintf(fid, 'FILE\t Latency_minus\t Latency_zero\t Latency_plus\t Stim_type\t');
% %     fprintf(fid, '\r\n');
% % end
% % fprintf(fid, '%s', buff);
% % fprintf(fid, '\r\n');
% % fclose(fid);
% % 
% % % And another line if two stim types
% % if length(unique_stim_type) > 1
% %     stim_text = 'Visual';
% %     buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %s\t', FILE, latency(:,2), stim_text);
% %     outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_Vary_Fixation_Latency.dat'];
% % 	fid = fopen(outfile, 'a');
% % 	fprintf(fid, '%s', buff);
% % 	fprintf(fid, '\r\n');
% % 	fclose(fid);
% % end
% % %--------------------------------------------------------------------------------------
% % %---TEMP - LATENCY OUTPUT--------------------------------------------------------------
% % %--------------------------------------------------------------------------------------
% 
% 
% 
% %
% % TEMP - ALL OUTPUT - commented for now
% % %--------------------------------------------------------------------------------------
% % % Write out all data to a cumulative summary file
% % 
% % if unique_stim_type == 1
% %     stim_text = 'Vestibular';
% % elseif unique_stim_type == 2
% %     stim_text = 'Visual';
% % else
% %     stim_text = 'Vestibular'; % (both, but ves first)
% % end
% % buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %3.0f\t %s\t %s\t', ...
% %        FILE, spon_resp, Min_resp(1:3), Max_resp(1:3), Vec_sum{1:3}, HTI_temp(1:3), p(1:3), resp_std(1:3), gf_anovas{1}, GFr_max(1), GFp_max(1), GFslope_max(1), GFr_spon(1), GFp_spon(1), GFslope_spon(1), GFr_maxmin(1), GFp_maxmin(1), GFslope_maxmin(1), GFr_maxspon(1), GFp_maxspon(1), GFslope_maxspon(1), boot_data{1}, SR_true{1}, DI_3D(:,1), EndTrial-(BegTrial-1), stim_text, dir_text);
% %        % currently 62 fields (11/05)
% % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_Vary_Fixation_Sum.dat'];
% % printflag = 0;
% % if (exist(outfile, 'file') == 0)    %file does not yet exist
% %     printflag = 1;
% % end
% % fid = fopen(outfile, 'a');
% % if (printflag)
% %     fprintf(fid, 'FILE\t Spon_minus\t Spon_zero\t Spon_plus\t Min_minus\t Min_zero\t Min_plus\t Max_minus\t Max_zero\t Max_plus\t Azi_minus\t Ele_minus\t Amp_minus\t Azi_zero\t Ele_zero\t Amp_zero\t Azi_plus\t Ele_plus\t Amp_plus\t HTI_minus\t HTI_zero\t HTI_plus\t Pval_minus\t Pval_zero\t Pval_plus\t Std_minus\t Std_zero\t Std_plus\t ANOVA_max\t ANOVA_spon\t ANOVA_maxmin\t ANOVA_maxspon\t GF_r_max\t GF_p_max\t GF_slope_max\t GF_r_spon\t GF_p_spon\t GF_slope_spon\t GF_r_maxmin\t GF_p_maxmin\t GF_slope_maxmin\t GF_r_maxspon\t GF_p_maxspon\t GF_slope_maxspon\t Exp_plus_azi\t Exp_plus_ele\t Exp_plus_amp\t Exp_minus_azi\t Exp_minus_ele\t Exp_minus_amp\t Frame_plus\t Frame_minus\t Frame_plusminus\t SR_true_minus\t SR_true_plusminus\t SR_true_plus\t DI_3D_minus\t DI_3D_plusminus\t DI_3D_plus\t Num_trials\t Stim_type\t Gaze_dir');
% %     fprintf(fid, '\r\n');
% % end
% % fprintf(fid, '%s', buff);
% % fprintf(fid, '\r\n');
% % fclose(fid);
% % 
% % % And another line if two stim types
% % if length(unique_stim_type) > 1
% %     stim_text = 'Visual';
% %     buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %3.0f\t %s\t %s\t', ...
% %            FILE, spon_resp, Min_resp(4:6), Max_resp(4:6), Vec_sum{4:6}, HTI_temp(4:6), p(4:6), resp_std(4:6), gf_anovas{2}, GFr_max(2), GFp_max(2), GFslope_max(2), GFr_spon(2), GFp_spon(2), GFslope_spon(2), GFr_maxmin(2), GFp_maxmin(2), GFslope_maxmin(2), GFr_maxspon(2), GFp_maxspon(2), GFslope_maxspon(2), boot_data{2}, SR_true{2}, DI_3D(:,2), EndTrial-(BegTrial-1), stim_text, dir_text);
% %     outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_Vary_Fixation_Sum.dat'];
% % 	fid = fopen(outfile, 'a');
% % 	fprintf(fid, '%s', buff);
% % 	fprintf(fid, '\r\n');
% % 	fclose(fid);
% % end
% % 
% % 
% % %--------------------------------------------------------------------------------------
% % % Write out horizontal slice data to a separate file
% % if proceed == 1
% % 
% % if unique_stim_type == 1
% %     stim_text = 'Vestibular';
% % elseif unique_stim_type == 2
% %     stim_text = 'Visual';
% % else
% %     stim_text = 'Vestibular'; % (both, but ves first)
% % end
% % buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %3.0f\t %s\t %s\t', ...
% %        FILE, congruency, p_anova(:,1), SR_true{1}, SR_slice{1}, DI_slice(:,1), rsquared_head(1), rsquared_eye(1), partialZ_head(1), partialZ_eye(1), EndTrial-(BegTrial-1), stim_text, dir_text);
% %        % currently 21 fields (10/05)
% % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_Vary_Fixation_Slice.dat'];
% % printflag = 0;
% % if (exist(outfile, 'file') == 0)    %file does not yet exist
% %     printflag = 1;
% % end
% % fid = fopen(outfile, 'a');
% % if (printflag)
% %     fprintf(fid, 'FILE\t Congruency\t P_anova_minus\t P_anova_zero\t P_anova_plus\t SR_true_minus\t SR_true_plusminus\t SR_true_plus\t SR_slice_minus\t SR_slice_plusminus\t SR_slice_plus\t DI_slice_minus\t DI_slice_plusminus\t DI_slice_plus\t Rsquared_head\t Rsquared_eye\t partialZ_head\t partialZ_eye\t Num_trials\t Stim_type\t Gaze_dir');
% %     fprintf(fid, '\r\n');
% % end
% % fprintf(fid, '%s', buff);
% % fprintf(fid, '\r\n');
% % fclose(fid);
% % 
% % % And another line if two stim types
% % if length(unique_stim_type) > 1
% %     stim_text = 'Visual';
% %     buff = sprintf('%s\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %3.0f\t %s\t %s\t', ...
% %         FILE, congruency, p_anova(:,2), SR_true{2}, SR_slice{2}, DI_slice(:,2), rsquared_head(2), rsquared_eye(2), partialZ_head(2), partialZ_eye(2), EndTrial-(BegTrial-1), stim_text, dir_text);
% %     outfile = [BASE_PATH 'ProtocolSpecific\MOOG\VaryFixation\Dir3D_Vary_Fixation_Slice.dat'];
% % 	fid = fopen(outfile, 'a');
% % 	fprintf(fid, '%s', buff);
% % 	fprintf(fid, '\r\n');
% % 	fclose(fid);
% % end
% % 
% % end
% 
% 
% time = clock;
% disp('END TIME = ');
% disp(time(4:6));
% 
% toc
% return;