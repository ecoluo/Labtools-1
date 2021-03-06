%-----------------------------------------------------------------------------------------------------------------------
%-- TimeBlockAnalysis.m -- Analyze CPs, etc over blocks of time within a discrimination run
%--	GCD, 3/1/01
%-----------------------------------------------------------------------------------------------------------------------
function TimeBlockAnalysis(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;		%needed for defines like IN_T1_WIN_CD
ProtocolDefs;	%needed for all protocol specific functions - contains keywords - BJP 1/4/01
Path_Defs;

Pref_HDisp = data.one_time_params(PREFERRED_HDISP);

%get the column of values of horiz. disparities in the dots_params matrix
h_disp = data.dots_params(DOTS_HDISP,:,PATCH1);
unique_hdisp = munique(h_disp');

%get the binocular correlations
binoc_corr = data.dots_params(DOTS_BIN_CORR, :, PATCH1);
unique_bin_corr = munique(binoc_corr');

%get signed binocular correlations
sign = (h_disp == Pref_HDisp)*2 - 1;	%=1 if preferred disparity, -1 if null disparity
signed_bin_corr = binoc_corr .* sign;
unique_signed_bin_corr = munique(signed_bin_corr');

%now, get the firing rates for all the trials 
spike_rates = data.spike_rates(SpikeChan, :);

%get trial lengths in seconds
trial_length = ((find(data.event_data(:,:,:)==StopCode)) - (find(data.event_data(:,:,:)==StartCode)))'/1000;

%now, Z-score the spike rates for each bin_corr and disparity condition
Z_Spikes = spike_rates;
for i=1:length(unique_bin_corr)
    for j=1:length(unique_hdisp)
        select = (binoc_corr == unique_bin_corr(i)) & (h_disp == unique_hdisp(j));
        z_dist = spike_rates(select);
        z_dist = (z_dist - mean(z_dist))/std(z_dist);
        Z_Spikes(select) = z_dist;
    end
end

%now, select trials that fall between BegTrial and EndTrial
trials = 1:length(binoc_corr);		% a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

%now, determine the choice that was made for each trial, PREFERRED or NULL
%by definition, a preferred choice will be made to Target1 and a null choice to Target 2
%thus, look for the events IN_T1_WIN_CD and IN_T2_WIN_CD.  GCD, 5/30/2000
num_trials = length(binoc_corr);
PREFERRED = 1;
NULL = 2;
for i=1:num_trials
    temp = data.event_data(1,:,i);
    events = temp(temp>0);  % all non-zero entries
    if (sum(events == IN_T1_WIN_CD) > 0)
        choice(i) = PREFERRED;
    elseif (sum(events == IN_T2_WIN_CD) > 0)
        choice(i) = NULL;
    else
        disp('Neither T1 or T2 chosen.  This should not happen!.  File must be bogus.');
    end        
end


BlockSize = 70;
block_starts = (BegTrial:(EndTrial-BlockSize+1));
block_ends = ((BegTrial+BlockSize-1):EndTrial);
grandCP = [];
for i=1:length(block_starts)
    pref_dist = []; null_dist = [];
    pref_dist = Z_Spikes((choice == PREFERRED) & (trials >= block_starts(i)) & (trials <= block_ends(i)));
    null_dist = Z_Spikes((choice == NULL) & (trials >= block_starts(i)) & (trials <= block_ends(i)));
    grandCP(i) = rocN(pref_dist, null_dist, 100);
end

figure;
set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [50 120 500 573], 'Name', 'Time Block Analysis');
subplot(3,2,1);
plot((block_starts+block_ends)/2, grandCP, 'k--');
hold on;
chance = ones(length(block_starts))*0.5;
plot((block_starts+block_ends)/2, chance, 'k--');
xlim([0 EndTrial]);
ylim([0 1]);
hold off;
titl = [PATH FILE];
title(titl);
xlabel('Trial #');
ylabel('Grand Choice Prob.');

%calculate the variance of the running CP.
var_all = var(grandCP);

BlockSize_var = 70;
block_starts_var = (BegTrial:(EndTrial-BlockSize-BlockSize_var+2));
block_ends_var = ((BegTrial+BlockSize+BlockSize_var-2):EndTrial);
%now calculate the running variance of the running CP.
for i=1:length(block_starts_var)
    var_run(i) = var(grandCP(i:i+BlockSize_var-1));
end
median_var_run = median(var_run);

subplot(3,2,2);
plot((block_starts_var+block_ends_var)/2, var_run, 'k--');
hold on;
xlim([0 EndTrial]);
hold off;
xlabel('Trial #');
ylabel('CP Variance');

%scramble up the values in the running CP and calculate the running variance.   
scramble = randperm(length(grandCP));
permuted_grandCP = grandCP(scramble);
for i=1:length(block_starts_var)
    var_run_perm(i) = var(permuted_grandCP(i:i+BlockSize_var-1));
end
median_var_run_perm = median(var_run_perm);
ratio = median_var_run_perm/median_var_run;
   
subplot(3,2,3);
plot((block_starts+block_ends)/2, permuted_grandCP, 'k--');
hold on;
chance = ones(length(block_starts))*0.5;
plot((block_starts+block_ends)/2, chance, 'k--');
xlim([0 EndTrial]);
ylim([0 1]);
hold off;
xlabel('Trial #');
ylabel('Permuted Grand Choice Prob.');

subplot(3,2,4);
plot((block_starts_var+block_ends_var)/2, var_run_perm, 'k--');
hold on;
xlim([0 EndTrial]);
hold off;
xlabel('Trial #');
ylabel('Permuted CP Variance');

subplot(3,2,5);
PlotTwoHists(var_run, var_run_perm);
xlabel('CP Variance');
titl = sprintf('ratio = %5.3f', ratio);
title(titl);

%do permutation test to get P value for grand CP
%[grandCP, grandPval] = ROC_signif_test(var_run, var_run_perm);
%titl = sprintf('grand CP = %5.3f, P = %6.4f', grandCP, grandPval);
%title(titl);


%correlation between neuronal threshold and psychophysical threshold  06/07/02 TU
%add correlation between grandCP and thresholds 07/08/03 TU

BlockSize = 5; % in reps
block_starts = (BegTrial : 2*length(unique_bin_corr) : BegTrial+(floor((EndTrial-BegTrial+1)/(2*length(unique_bin_corr)))-BlockSize)*2*length(unique_bin_corr));
block_ends = (BegTrial+(2*BlockSize*length(unique_bin_corr))-1 : 2*length(unique_bin_corr) : BegTrial+floor((EndTrial-BegTrial+1)/(2*length(unique_bin_corr)))*2*length(unique_bin_corr)-1);

for i=1:length(block_starts)
    %% ********* NEUROMETRIC ANALYSIS ********************
    %loop through each binocular correlation levels, and do ROC analysis for each
    ROC_values = []; N_obs = []; all_mean = []; all_var = [];
    for j=1:length(unique_bin_corr)
    
        pref_trials = ( (h_disp == Pref_HDisp) & (binoc_corr == unique_bin_corr(j)) & (trials >= block_starts(i)) & (trials <= block_ends(i)) );    
        pref_dist = spike_rates(pref_trials);
        null_trials = ( (h_disp ~= Pref_HDisp) & (binoc_corr == unique_bin_corr(j)) & (trials >= block_starts(i)) & (trials <= block_ends(i)));    
        null_dist = spike_rates(null_trials);
        ROC_values(j) = rocN(pref_dist, null_dist, 100);
        N_obs(j) = length(pref_dist) + length(null_dist);
        % data for Weibull fit
        fit_data(j, 1) = unique_bin_corr(j);
        fit_data(j, 2) = ROC_values(j);
        fit_data(j,3) = N_obs(j);
        
        %store mean spike count and variance for each disp/corr combination
        all_mean(j) = mean(spike_rates(pref_trials).*trial_length(pref_trials));
        all_var(j) = var(spike_rates(pref_trials).*trial_length(pref_trials));
        all_mean(length(unique_bin_corr)+j) = mean(spike_rates(null_trials).*trial_length(null_trials));
        all_var(length(unique_bin_corr)+j) = var(spike_rates(null_trials).*trial_length(null_trials));
    end

    %calculate neuronal threshold and slope
    [neuron_alpha(i) neuron_beta(i)] = weibull_fit(fit_data);
    
    %fit with a linear finction constraining the slope to 1
    fixed_param_flags = zeros(2,1); %by default, all 2 parameters will vary
    fixed_param_values = zeros(2,1); %override these values and flags to fix a parameter    
    fixed_param_flags(2) = 1; %fix the slope of the curve
    fixed_param_values(2) = 1; %fix the slope to 1

    if ~isempty(all_mean)
        means = [log10(all_mean') log10(all_var')];
        [pars{i}] = linearfit(means,fixed_param_flags,fixed_param_values);
        var_mean_ratio(i) = 10^pars{i}(1);
    else
        var_mean_ratio(i) = NaN;
    end
    
    %calculate differential response
    diff_resp(i) = all_mean(length(unique_bin_corr)) - all_mean(length(unique_bin_corr)+length(unique_bin_corr));
    
    %% *********** PSYCHOMETRIC ANALYSIS ****************************
    pct_correct = []; N_obs = [];
    for j=1:length(unique_bin_corr)
        sel_trials = ((binoc_corr == unique_bin_corr(j)) & (trials >= block_starts(i)) & (trials <= block_ends(i)));
        correct_trials = ((binoc_corr == unique_bin_corr(j)) & (trials >= block_starts(i)) & (trials <= block_ends(i)) & (data.misc_params(OUTCOME, :) == CORRECT) );
        pct_correct(j) = sum(correct_trials)/sum(sel_trials);
        N_obs(j) = sum(sel_trials);
        % data for Weibull fit
        fit_data(j, 1) = unique_bin_corr(j);
        fit_data(j, 2) = pct_correct(j);
        fit_data(j,3) = N_obs(j);
    end

    [monkey_alpha(i) monkey_beta(i)] = weibull_fit(fit_data);

    %% *********** GRAND CP ***************************
    pref_dist = []; null_dist = [];
    pref_dist = Z_Spikes((choice == PREFERRED) & (trials >= block_starts(i)) & (trials <= block_ends(i)));
    null_dist = Z_Spikes((choice == NULL) & (trials >= block_starts(i)) & (trials <= block_ends(i)));
    CP(i) = rocN(pref_dist, null_dist, 100);
end

%NP threshold correlation
corr1 = corrcoef(neuron_alpha, monkey_alpha);
temp = [ones(length(monkey_alpha),1) monkey_alpha'];
[b, bint, r, rint, stats1] = regress(neuron_alpha', temp);

%CP/Nthres correlation
corr2 = corrcoef(CP, neuron_alpha);
temp = [ones(length(neuron_alpha),1) neuron_alpha'];
[b, bint, r, rint, stats2] = regress(CP', temp);

%CP/Pthres correlation
corr3 = corrcoef(CP, monkey_alpha);
temp = [ones(length(monkey_alpha),1) monkey_alpha'];
[b, bint, r, rint, stats3] = regress(CP', temp);

%Nthres/VMR correlation
corr4 = corrcoef(neuron_alpha, var_mean_ratio);
temp = [ones(length(var_mean_ratio),1) var_mean_ratio'];
[b, bint, r, rint, stats4] = regress(neuron_alpha', temp);

%Nthres/Response Diff correlation
corr5 = corrcoef(neuron_alpha, diff_resp);
temp = [ones(length(diff_resp),1) diff_resp'];
[b, bint, r, rint, stats5] = regress(neuron_alpha', temp);

%-----------------------------------------------------------------------------------------------------------------------
%save some values to file
output1 = 0;
if (output1 == 1)
    outstr1 = sprintf('%s %8.6f %8.6f %8.6f %8.6f', FILE, var_all, median_var_run, median_var_run_perm, ratio);

    %also write out data in form suitable for plotting tuning curve with Origin.
    i = size(PATH,2) - 1;
    while PATH(i) ~='\'	%Analysis directory is one branch below Raw Data Dir
        i = i - 1;
    end   
    PATHOUT = [PATH(1:i) 'Analysis\Temp\'];
    outfile1 = [PATHOUT 'TimeBlock.dat'];
    %outfile2 = [PATHOUT 'Shift_ratio_GCtr.dat'];

    printflag = 0;
    if (exist(outfile1, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile1, 'a');
    if (printflag)
        fprintf(fid, 'File Var_all Median_var_run Median_var_perm Ratio');
        fprintf(fid, '\r\n');
    end
    fprintf(fid, '%s', outstr1);
    fprintf(fid, '\r\n');
    fclose(fid);
end

%----------------------------------------------------------------------------------------------------------------------------------------------------------
%also write out correlation data for N:P time course
outfile2 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\NPtimecourse.dat'];

printflag = 0;
if (exist(outfile2, 'file') == 0)    %file does not yet exist
    printflag = 1;
end
fid = fopen(outfile2, 'a');
if (printflag)
    fprintf(fid, 'File NPthresR NPthresP CPNthresR CPNthresP CPPthresR CPPthresP NthresVmrR NthresVmrP NthresRespDiffR NthresRespDiffP');
    fprintf(fid, '\r\n');
end
outstr2 = sprintf('%s %8.6f %8.6f %8.6f %8.6f %8.6f %8.6f %8.6f %8.6f %8.6f %8.6f', FILE, corr1(1,2), stats1(3), corr2(1,2), stats2(3), corr3(1,2), stats3(3), corr4(1,2), stats4(3), corr5(1,2), stats5(3));
fprintf(fid, '%s', outstr2);
fprintf(fid, '\r\n');
fclose(fid);

return;