%-----------------------------------------------------------------------------------------------------------------------
%-- PSTH_CuedDirec.m -- Plot PSTHs for each stimulus condition
%--	VR, 9/21/05
%-----------------------------------------------------------------------------------------------------------------------

function PSTH_CuedDirec(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;		
Path_Defs;
ProtocolDefs;	%needed for all protocol specific functions - contains keywords - BJP 1/4/01

%get the column of values of directions in the dots_params matrix
direction = data.dots_params(DOTS_DIREC,:,PATCH1);
unique_direction = munique(direction');
Pref_direction = data.one_time_params(PREFERRED_DIRECTION);
if (unique_direction(1) ~= Pref_direction) %reorder so that Pref_direction is first in unique_direction
    unique_direction = unique_direction(end:-1:1);
end
    
%get the motion coherences
coherence = data.dots_params(DOTS_COHER, :, PATCH1);
unique_coherence = munique(coherence');
signed_coherence = coherence.*(-1+2.*(direction==Pref_direction));
unique_signed_coherence = [-unique_coherence' unique_coherence'];

%get the cue validity: -1=Invalid; 0=Neutral; 1=Valid; 2=CueOnly
cue_val = data.cue_params(CUE_VALIDITY,:,PATCH2);
unique_cue_val = munique(cue_val');
cue_val_names = {'NoCue','Invalid','Neutral','Valid','CueOnly'};
NOCUE = -2; INVALID = -1; NEUTRAL = 0; VALID = 1; CUEONLY = 2;

%get the cue directions
cue_direc = data.cue_params(CUE_DIREC, :, PATCH1);
unique_cue_direc = munique(cue_direc');
%cue_dir_type = 1 if PrefDir, 0 if Neutral Cue, -1 if Null Cue
cue_dir_type = logical( (squeeze_angle(cue_direc) == Pref_direction) & (cue_val ~= NEUTRAL) ) - logical( (squeeze_angle(cue_direc) ~= Pref_direction) & (cue_val ~= NEUTRAL) );
unique_cue_dir_type = munique(cue_dir_type');
cue_dir_typenames = {'Null','Neutral','Pref'};

%compute cue types - 0=neutral, 1=directional, 2=cue_only
cue_type = abs(cue_val); %note that both invalid(-1) and valid(+1) are directional
unique_cue_type = munique(cue_type');

%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (coherence == data.one_time_params(NULL_VALUE)) );

% keyboard

%now, select trials that fall between BegTrial and EndTrial
trials = 1:length(coherence);
%a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

%get outcome for each trial: 0=incorrect, 1=correct
trial_outcomes = logical (data.misc_params(OUTCOME,:) == CORRECT);
trial_choices = ~xor((direction==Pref_direction),trial_outcomes); %0 for Null Choices, 1 for Pref Choices

linetypes = {'b-','r-','g-'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %some temporary stuff for testing timing
% %trials = [1:53, 55:100];
% for i = 1:length(trials)
% sync(i) = find(data.spike_data(2,:,trials(i))~=0,1);
% cueon(i) = find(data.event_data(1,:,trials(i))==CUE_ON_CD);
% stimstart(i) = find(data.event_data(1,:,trials(i))==VSTIM_ON_CD);
% cuediode(i) = find(data.spike_data(1,:,trials(i))~=0,1);
% stimdiode(i) = find(data.spike_data(1,stimstart(i)-100:end,trials(i))~=0,1)+stimstart(i)-100;
% end
% figure
% temph = cuediode-cueon; subplot(411); hist(temph); 
% title(sprintf('Cue diode-code: Range=[%3.1f:%3.1f] Med=%3.1f, Mean=%3.1f',min(temph),max(temph),median(temph),mean(temph)));
% temph = sync-stimstart; subplot(412); hist(temph);
% title(sprintf('Sync-Code: Range=[%3.1f:%3.1f] Med=%3.1f, Mean=%3.1f',min(temph),max(temph),median(temph),mean(temph)));
% temph = stimdiode-stimstart; subplot(413); hist(temph);
% title(sprintf('Stim: diode-code: Range=[%3.1f:%3.1f] Med=%3.1f, Mean=%3.1f',min(temph),max(temph),median(temph),mean(temph)));
% temph = stimdiode-sync; subplot(414); hist(temph);
% title(sprintf('Stim: diode-sync: Range=[%3.1f:%3.1f] Med=%3.1f, Mean=%3.1f',min(temph),max(temph),median(temph),mean(temph)));
% xlabel('Time (ms)');
% keyboard


%first align the psths with the stimulus events - cue onset, motion onset

%first compute the psth centered around the cue onset, and a psth centered around the stimulus onset
precue = 200; %time to show before the cue starts
postcue = 400; %time to show after cue starts
prestim = 300; %time to display before the visual stimulus
poststim = 1100; %time to display after the visual stimulus
binwidth = 25; %in ms (used for psth)
bw = 50; %in ms, used for roc
spksamprate = 1000;
stddev = sqrt(2*15^2); %in ms, std dev of guassian used for filtering
stddev = 15; 
buff = 3*stddev; 
gaussfilt = normpdf([1:2*buff+1],buff+1,stddev); %gaussian filter 3 std.dev's wide
long = 200; %extra buffer to save to allow for extra smoothing later
cue_timing_offset = 46; %in ms, time between CUE_ON_CD and detectable light on screen; use to offset cue onset.
% stim_timing_offset = 12; %in ms, time between first sync pulse (*NOT* VSTIM_ON_CD) and detectable light on screen
stim_timing_offset = 52; %in ms, median time between VSTIM_ON_CD and first detectable light on screen

%now make psths from ALL trials to produce normalization values
select = trials(select_trials);
for m = 1:length(select)
    full_raster(m,:) = data.spike_data(SpikeChan,:,select(m));
    temp_sm_raster = conv(gaussfilt, full_raster(m,:));
    sm_full_raster(m,:) = temp_sm_raster(2*buff+1:end-2*buff);
    
    t_infixwin = find(data.event_data(1,:,select(m)) == IN_FIX_WIN_CD);
    if (t_infixwin > 250)
        targon_raster(m,:) = data.spike_data(SpikeChan,t_infixwin-250:t_infixwin+250,select(m));
    elseif (t_infixwin < 250)
        targon_raster(m,:) = [zeros(1,251-t_infixwin) data.spike_data(SpikeChan,1:t_infixwin+250,select(m))];
    else
        targon_raster(m,:) = zeros(1,501);
    end
    temp_sm_raster = conv(gaussfilt, targon_raster(m,:));
    sm_targon_raster(m,:) = temp_sm_raster(2*buff+1:end-2*buff);

    t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);
    sacc_raster(m,:) = data.spike_data(SpikeChan,t_sacc-250:t_sacc+250,m);
    temp_sm_raster = conv(gaussfilt, sacc_raster(m,:));
    sm_sacc_raster(m,:) = temp_sm_raster(2*buff+1:end-2*buff);
end
sm_all_full_psth = sum(sm_full_raster,1)./length(select).*spksamprate;
sm_all_targon_psth = sum(sm_targon_raster,1)./length(select).*spksamprate;
sm_all_sacc_psth = sum(sm_sacc_raster,1)./length(select).*spksamprate;
normval = [max(sm_all_full_psth) max(sm_all_targon_psth) max(sm_all_sacc_psth)];
clear sacc_raster sm_sacc_raster;
clear sm_all_full_psth sm_all_targon_psth sm_all_sacc_psth;
num_trials = zeros(length(unique_coherence),2,length(unique_cue_dir_type),2);

for k = 1:length(unique_cue_dir_type)
    for i = 1:length(unique_coherence)
        for j = 1:2 %PrefChoice=1, NullChoice=2
            %first select the relevant trials and get a raster
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & (cue_val ~= CUEONLY) );
            if isempty(select)
                sm_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+1);
                prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+1);
            else
                for m = 1:length(select)
                    % t_stimon = find(data.spike_data(2,:,select(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                    t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset; 
                    prestim_raster{i,j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff:t_stimon+poststim+buff, select(m));
                    temp_sm_raster = conv(gaussfilt, prestim_raster{i,j,k}(m,:)); %convolve with the gaussian filters
                    sm_prestim_raster{i,j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                end
            end
            sm_prestim_psth{i,j,k} = sum(sm_prestim_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            %prestim_psth{i,j,k} = sum(prestim_raster{i,j,k},1)./length(select).*spksamprate; %psth is NOT binned
            for g = 1:length(unique_direction) %Motion: PrefDir = 1, NullDir = 0\
                select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                    (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & ...
                    (direction == unique_direction(g)) & (cue_val ~= CUEONLY) );
                num_trials(i,j,k,g) = length(select);
                %misc: save out raw rasters?  bigger 'long' window for
                %yet more smoothing!
                if isempty(select)
                    sm_ungrouped_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+1);
                    ungrouped_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+1);
                else
                    for m = 1:length(select)
                        t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                        ungrouped_prestim_raster{i,j,k,g}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff:t_stimon+poststim+buff, select(m));
                        temp_sm_raster = conv(gaussfilt, ungrouped_prestim_raster{i,j,k,g}(m,:)); %convolve with the gaussian filters
                        sm_ungrouped_prestim_raster{i,j,k,g}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                        clear ungrouped_prestim_raster;
                    end
                end
                if ~isempty(select)
                    sm_ungrouped_prestim_psth{i,j,k,g} = sum(sm_ungrouped_prestim_raster{i,j,k,g},1)./length(select).*spksamprate; %sum and scale rasters to get psth
                    %ungrouped_prestim_psth{i,j,k,g} = sum(ungrouped_prestim_raster{i,j,k,g},1)./length(select).*spksamprate; %psth is NOT binned
                else
                    sm_ungrouped_prestim_psth{i,j,k,g} = NaN.*zeros(prestim+poststim+1,1);
                    %ungrouped_prestim_psth{i,j,k,g} = NaN.*zeros(prestim+poststim+1,1);
                end
            end
        end
        %now compute a running roc metric for the two choices
        for v = 1:size(sm_prestim_psth{i,1,k},2) %time bin
            if isnan(prestim_raster{i,1,k}(1)) | isnan(prestim_raster{i,2,k}(1))
                prestim_roc{i,k}(v) = NaN;
            else
                pc = sm_prestim_raster{i,1,k}(:,v);
                nc = sm_prestim_raster{i,2,k}(:,v);
                prestim_roc{i,k}(v) = rocn(pc,nc,100);
            end
        end
    end
    %repeat this collapsing across all coherences for the cue response
    for j = 1:2 %again for the two choices - a little kludgey organization but allows roc computation and inclusion of cue only trials
        select = trials(select_trials & (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) );
        if isempty(select)
            sm_postcue_raster{i,j,k} = NaN.*ones(1,precue+postcue+1);
            postcue_raster{i,j,k} = NaN.*ones(1,precue+postcue+1);
        else
            for m = 1:length(select)
                t_cueon = find(data.event_data(1,:,select(m)) == CUE_ON_CD) + cue_timing_offset;
                postcue_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_cueon-precue-buff:t_cueon+postcue+buff, select(m));
                temp_sm_raster = conv(gaussfilt, postcue_raster{j,k}(m,:)); %convolve with the gaussian filters
                sm_postcue_raster{j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
            end
        end
        sm_postcue_psth{j,k} = sum(sm_postcue_raster{j,k},1)./length(select).*spksamprate; %psth is NOT binned
    end 
    %also combine the two directions in the postcue to get a single postcue psth
    sm_postcue_combined_raster{k} = [sm_postcue_raster{1,k}; sm_postcue_raster{2,k}];
    sm_postcue_combined_psth{k} = sum(sm_postcue_combined_raster{k},1)./size(sm_postcue_combined_raster{k},1).*spksamprate;
    %now compute ROC
    for v = 1:size(sm_postcue_psth{1,k},2) %time bin
        if isempty(postcue_raster{1,k}) | isempty(postcue_raster{2,k})
            postcue_roc{k}(v) = NaN;
        else
            pc = sm_postcue_raster{1,k}(:,v);
            nc = sm_postcue_raster{2,k}(:,v);
            postcue_roc{k}(v) = rocn(pc,nc,100);
        end
    end
end
clear prestim_raster postcue_raster sm_postcue_raster sm_prestim_raster
%find max of the psths
maxy_prestim = zeros(length(unique_coherence),1);
for j = 1:length(unique_coherence)
    temp = sm_prestim_psth(j,:,:);
    for i = 1:prod(size(temp))
        if (max(temp{i})>maxy_prestim(j))
            maxy_prestim(j) = max(temp{i});
        end
    end
end

%now plot the peristimulus psths
postcue_x = [-precue:postcue];
prestim_x = [-prestim:poststim];
h(1)=figure;
set(h(1),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Peri-Stimulus Time Histogram',FILE));

for j = 1:2 %PrefChoice = 1; NullChioce=2;
    %first plot the peri-CueOnset psth, then underneath plot the peri-VStim psths
    subplot(1+length(unique_coherence), 2, j); hold on;
    for k = 1:length(unique_cue_dir_type)
        plot(postcue_x,sm_postcue_psth{j,k},linetypes{k});
    end
    axis tight;
    xlabel('Time about Cue Onset');
    if j==1
        ylabel('F.R.{Hz}');
        title(sprintf('%s: PrefDir Choices',FILE));
%         legh=legend('NullDir','Neutral','PrefDir','Location','NorthEast');
%         set(legh,'box','off');
    else
        title('NullDir Choices');
    end
    for i = 1:length(unique_coherence)
        subplot(1+length(unique_coherence), 2, i*2+j);
        hold on;
        for k = 1:length(unique_cue_dir_type)
            if ~isempty(sm_prestim_psth{i,j,k})
                plot(prestim_x,sm_prestim_psth{i,j,k},linetypes{k});
            end
        end
        axis tight;
        ylim([0 maxy_prestim(i)]);
        if j==1
            ylabel(sprintf('Coh= %3.1f%%',unique_coherence(i)));
        end
        if i==1
            
        elseif i==length(unique_coherence)
            xlabel('Time about VStim Onset (ms)');
        end
    end
end

%now plot the roc time courses per coherence
h(2)=figure;
set(h(2),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: ROC',FILE));
for i = 1:length(unique_coherence)
    subplot(length(unique_coherence)+1,1,i+1); hold on;    
    for k = 1:length(unique_cue_dir_type)
        if ~isempty(prestim_roc{i,k})
            plot(prestim_x,prestim_roc{i,k},linetypes{k});
        end
    end
    axis tight
    plot(xlim, [0.5 0.5], 'k:');
    if i==length(unique_coherence)
        xlabel('Time about VStim Onset (ms)');
    end
    ylabel(sprintf('Coh = %6.1f',unique_coherence(i)));
    ylim([0 1]);
end
%now plot the roc time course for the cue
subplot(length(unique_coherence)+1,1,1); hold on;
for k = 1:length(unique_cue_dir_type)
    plot(postcue_x,postcue_roc{k}, linetypes{k});
end
axis tight
plot(xlim,[0.5 0.5], 'k:');
xlabel('Time about Cue Onset (ms)'); ylabel('ROC');
%ylim([0 1]);
title(sprintf('%s: ROC values, sorted by cue direction',FILE));


% keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%now repeat this around saccades
%first compute the psth centered around the saccade onset
presacc = 700; %time to show before the saccade starts
postsacc = 200; %time to show after saccade starts

for k = 1:length(unique_cue_dir_type)
    for i = 1:length(unique_coherence)
        for j = 1:2 %PrefChoice=1, NullChoice=2
            %first select the relevant trials and get a raster
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & (cue_val ~= CUEONLY) );
            if isempty(select)
                sm_sacc_raster{i,j,k} = NaN.*ones(1,presacc+postsacc+1);
                sacc_raster{i,j,k} = NaN.*ones(1,presacc+postsacc+1);
            else
                for m = 1:length(select)
                    t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);
                    sacc_raster{i,j,k}(m,:) = data.spike_data(SpikeChan, t_sacc-presacc-buff:t_sacc+postsacc+buff, select(m));
                    temp_sm_raster = conv(gaussfilt, sacc_raster{i,j,k}(m,:));
                    sm_sacc_raster{i,j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff);
                end
            end
            sm_sacc_psth{i,j,k} = sum(sm_sacc_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters
            sacc_psth{i,j,k} = sum(sacc_raster{i,j,k},1)./length(select).*spksamprate;
        end
        for g = 1:length(unique_direction) %Motion: PrefDir = 1, NullDir = 0\
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) &(cue_dir_type == unique_cue_dir_type(k)) & ...
                (direction == unique_direction(g)) & (cue_val ~= CUEONLY) );
            %misc: save out raw rasters?  bigger 'long' window for yet more smoothing!
            if isempty(select)
                sm_ungrouped_sacc_raster{i,j,k} = NaN.*ones(1,presacc+postsacc+1);
                ungrouped_sacc_raster{i,j,k} = NaN.*ones(1,presacc+postsacc+1);
            else
                for m = 1:length(select)
                    t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD,1);
                    ungrouped_sacc_raster{i,j,k,g}(m,:) = data.spike_data(SpikeChan, t_sacc-presacc-buff:t_sacc+postsacc+buff, select(m));
                    temp_sm_raster = conv(gaussfilt, ungrouped_sacc_raster{i,j,k,g}(m,:)); %convolve with the gaussian filters
                    sm_ungrouped_sacc_raster{i,j,k,g}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                end
            end
            if length(select) > 0
                sm_ungrouped_sacc_psth{i,j,k,g} = sum(sm_ungrouped_sacc_raster{i,j,k,g},1)./length(select).*spksamprate; %sum and scale rasters to get psth
                %ungrouped_sacc_psth{i,j,k,g} = sum(ungrouped_sacc_raster{i,j,k,g},1)./length(select).*spksamprate; %psth is NOT binned
            else
                sm_ungrouped_sacc_psth{i,j,k,g} = NaN.*zeros(presacc+postsacc+1,1);
                %ungrouped_sacc_psth{i,j,k,g} = zeros(presacc+postsacc+1,1);
            end
        end

        %now compute a running roc metric for the two choices
        for v = 1:size(sm_sacc_psth{i,1,k},2)
            if isempty(sacc_raster{i,1,k}) | isempty(sacc_raster{i,2,k})
                sacc_roc{i,k}(v) = NaN;
            else
                pc = sm_sacc_raster{i,1,k}(:,v);
                nc = sm_sacc_raster{i,2,k}(:,v);
                sacc_roc{i,k}(v) = rocn(pc,nc,100);
            end
        end
    end
end
clear sacc_raster sm_sacc_raster ungrouped_sacc_raster sm_ungrouped_sacc_raster;
%find max of the psths
maxy = zeros(length(unique_coherence),1);
for j = 1:length(unique_coherence)
    temp = sm_sacc_psth(j,:,:);
    for i = 1:prod(size(temp))
        if (max(temp{i})>maxy(j))
            maxy(j) = max(temp{i});
        end
    end
end
%now plot the peristimulus psths
sacc_x = [-presacc:postsacc];
h(3)=figure;
set(h(3),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Peri-Saccadic Time Histogram',FILE));
for j = 1:2 %PrefChoice = 1; NullChioce=2;
    for i = 1:length(unique_coherence)
        subplot(length(unique_coherence), 2, (i-1)*2+j);
        hold on;
        for k = 1:length(unique_cue_dir_type)
            if ~isempty(sm_sacc_psth{i,j,k})
                plot(sacc_x,sm_sacc_psth{i,j,k},linetypes{k});
            end
        end
        axis tight;
        ylim([0 maxy(i)])
        plot([0 0],ylim,'k');
        if j==1
            ylabel(sprintf('Coh= %3.1f%%',unique_coherence(i)));
        end
        if i==1
            if j==1
                title(sprintf('%s: PrefDir Choices',FILE));
            else
                title('NullDir Choices');
            end
        elseif i==length(unique_coherence)
            xlabel('Time about Saccade Onset (ms)');
        end
    end
end

%now plot the roc time courses per coherence
h(4)=figure;
set(h(4),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Saccade-aligned ROC',FILE));
for i = 1:length(unique_coherence)
    subplot(length(unique_coherence),1,i); hold on;    
    for k = 1:length(unique_cue_dir_type)
        if ~isempty(sacc_roc{i,k})
            plot(sacc_x,sacc_roc{i,k},linetypes{k});
        end
    end
    axis tight
    plot(xlim, [0.5 0.5], 'k:');
    if i==1
        title(sprintf('%s: ROC values, sorted by cue direction',FILE));
    elseif i==length(unique_coherence)
        xlabel('Time about Saccade Onset (ms)');
    end
    ylabel(sprintf('Coh = %6.1f',unique_coherence(i)));
    ylim([0 1]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now repeat for cue only trials
precue_co = 200;
postcue_co = 200+150+1000;
prestim_co = -800; %200 before FP off
poststim_co = 1400;

for k = 1:2:length(unique_cue_dir_type)
    for j = 1:2
        select = trials(select_trials & (trial_choices == 2-j) & ...
            (cue_dir_type == unique_cue_dir_type(k)) & (cue_val == CUEONLY) );
        if isempty(select)
            sm_co_postcue_raster{j,k} = NaN.*ones(1,precue_co+postcue_co+1);
            sm_co_postcue_psth{j,k} = NaN.*ones(1,precue_co+postcue_co+1);
            sm_co_prestim_raster{j,k} = NaN.*ones(1,prestim_co+poststim_co+1);
            sm_co_prestim_psth{j,k} = NaN.*ones(1,prestim_co+poststim_co+1);
            sm_co_sacc_raster{j,k} = NaN.*ones(1,presacc+postsacc+1);
            sm_co_sacc_psth{j,k} = NaN.*ones(1,presacc+postsacc+1);
        else
            for m = 1:length(select)
                % t_stimon = find(data.spike_data(2,:,select(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset; 
                t_cueon = find(data.event_data(1,:,select(m)) == CUE_ON_CD) + cue_timing_offset;
                t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);

                co_postcue_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_cueon-precue_co-buff:t_cueon+postcue_co+buff, select(m));
%                 co_postcue_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_cueon-precue-buff:t_cueon+postcue+buff, select(m));
                temp_sm_raster = conv(gaussfilt, co_postcue_raster{j,k}(m,:)); %convolve with the gaussian filters
                sm_co_postcue_raster{j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges

                co_prestim_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim_co-buff:t_stimon+poststim_co+buff, select(m));
%                 co_prestim_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff:t_stimon+poststim+buff, select(m));
                temp_sm_raster = conv(gaussfilt, co_prestim_raster{j,k}(m,:)); %convolve with the gaussian filters
                sm_co_prestim_raster{j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges

                co_sacc_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_sacc-presacc-buff:t_sacc+postsacc+buff, select(m));
                temp_sm_raster = conv(gaussfilt, co_sacc_raster{j,k}(m,:));
                sm_co_sacc_raster{j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff);
            end

            sm_co_postcue_psth{j,k} = sum(sm_co_postcue_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            %co_postcue_psth{j,k} = sum(co_postcue_raster{j,k},1)./length(select).*spksamprate;

            sm_co_prestim_psth{j,k} = sum(sm_co_prestim_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            %co_prestim_psth{j,k} = sum(co_prestim_raster{j,k},1)./length(select).*spksamprate;

            sm_co_sacc_psth{j,k} = sum(sm_co_sacc_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            %co_sacc_psth{j,k} = sum(co_sacc_raster{j,k},1)./length(select).*spksamprate;
        end
    end

    %now compute a running roc metric for the two choices
    for v = 1:prestim_co+poststim_co+1
        pc = sum(sm_co_prestim_raster{1,k}(:,v),2); 
        nc = sum(sm_co_prestim_raster{2,k}(:,v),2); 
        sm_co_prestim_roc{k}(v) = rocn(pc,nc,100);
    end
    for v = 1:precue_co+postcue_co+1
        pc = sum(sm_co_postcue_raster{1,k}(:,v),2); 
        nc = sum(sm_co_postcue_raster{2,k}(:,v),2); 
        sm_co_postcue_roc{k}(v) = rocn(pc,nc,100);
    end
    for v = 1:presacc+postsacc+1
        pc = sum(sm_co_sacc_raster{1,k}(:,v),2);
        nc = sum(sm_co_sacc_raster{2,k}(:,v),2);
        sm_co_sacc_roc{k}(v) = rocn(pc,nc,100);
    end 
end
clear co_prestim_raster co_precue_raster co_sacc_raster;
clear sm_co_prestim_raster sm_co_precue_raster sm_co_sacc_raster;

%now plot the timecourses and rocs on one figure
postcue_co_x = [-precue_co:postcue_co];
prestim_co_x = [-prestim_co:poststim_co];
prestim_co_x = [-200:prestim_co+poststim_co-200]; %relative to FP offset
h(5) = figure;
set(h(5),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: CueOnly',FILE));

subplot(6,2,1); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_postcue_psth{1,k})
        plot(postcue_co_x, sm_co_postcue_psth{1,k}, linetypes{k});
    end
end
xlabel('Time about cue onset'); ylabel('FR (Hz)');
axis tight; yl = max(ylim); ylim([0 yl]);
title(sprintf('%s: Pref Choices',FILE));

subplot(6,2,2); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_postcue_psth{2,k})
        plot(postcue_co_x, sm_co_postcue_psth{2,k}, linetypes{k});
    end
end
xlabel('Time about cue onset'); 
axis tight; 
title('Null Choices');
if max(ylim) < yl
    ylim([0 yl]);
else
    yl = max(ylim); ylim([0 yl]);
    subplot(6,2,1); hold on; ylim([0 yl]);
end

subplot(6,2,3:4); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_postcue_roc{k})
        plot(postcue_co_x, sm_co_postcue_roc{k}, linetypes{k});
    end
end
axis tight; plot(xlim, [0.5 0.5], 'k:');
xlabel('Time about cue onset'); ylabel('ROC');


subplot(6,2,5); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_prestim_psth{1,k})
        plot(prestim_co_x, sm_co_prestim_psth{1,k}, linetypes{k});
    end
end
xlabel('Time about go signal'); ylabel('FR (Hz)');
axis tight; yl = max(ylim); ylim([0 yl]);

subplot(6,2,6); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_prestim_psth{2,k})
        plot(prestim_co_x, sm_co_prestim_psth{2,k}, linetypes{k});
    end
end
xlabel('Time about go signal'); 
axis tight; 
if max(ylim) < yl
    ylim([0 yl]);
else
    yl = max(ylim); ylim([0 yl]);
    subplot(6,2,5); hold on; ylim([0 yl]);
end

subplot(6,2,7:8); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_prestim_roc{k})
        plot(prestim_co_x, sm_co_prestim_roc{k}, linetypes{k});
    end
end
axis tight; plot(xlim, [0.5 0.5], 'k:');
xlabel('Time about go signal (FP off)'); ylabel('ROC');


subplot(6,2,9); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_sacc_psth{1,k})
        plot(sacc_x, sm_co_sacc_psth{1,k}, linetypes{k});
    end
end
xlabel('Time about saccade onset'); ylabel('FR (Hz)');
axis tight; yl = max(ylim); ylim([0 yl]);

subplot(6,2,10); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_sacc_psth{2,k})
        plot(sacc_x, sm_co_sacc_psth{2,k}, linetypes{k});
    end
end
xlabel('Time about saccade onset'); 
axis tight; 
if max(ylim) < yl
    ylim([0 yl]);
else
    yl = max(ylim); ylim([0 yl]);
    subplot(6,2,9); hold on; ylim([0 yl]);
end

subplot(6,2,11:12); hold on;
for k = 1:2:length(unique_cue_dir_type)
    if ~isempty(sm_co_sacc_roc{k})
        plot(sacc_x, sm_co_sacc_roc{k}, linetypes{k});
    end
end
axis tight; plot(xlim, [0.5 0.5], 'k:');
xlabel('Time about saccade onset'); ylabel('ROC');


REPRINT_DATA = 0;
if REPRINT_DATA
    print(h(3), '-dwinc');
    print(h(4), '-dwinc');
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%
% now recompute all the rasters tacking on some extra time on each end to
% allow additional smoothing
long_sm_prestim_raster = cell(length(unique_coherence),2,length(unique_cue_dir_type));
long_prestim_raster = cell(length(unique_coherence),2,length(unique_cue_dir_type));
for k = 1:length(unique_cue_dir_type)
    for i = 1:length(unique_coherence)
        for j = 1:2 %PrefChoice=1, NullChoice=2
            %first select the relevant trials and get a raster
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & (cue_val ~= CUEONLY) );
            if isempty(select)
                long_sm_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
                long_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
            else
                for m = 1:length(select)
                    % t_stimon = find(data.spike_data(2,:,select(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                    t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                    long_prestim_raster{i,j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff-long:t_stimon+poststim+buff+long, select(m));
                    temp_sm_raster = conv(gaussfilt, long_prestim_raster{i,j,k}(m,:)); %convolve with the gaussian filters
                    long_sm_prestim_raster{i,j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                end
            end
            long_sm_prestim_psth{i,j,k} = sum(long_sm_prestim_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            long_prestim_psth{i,j,k} = sum(long_prestim_raster{i,j,k},1)./length(select).*spksamprate; 
            for g = 1:length(unique_direction) %Motion: PrefDir = 1, NullDir = 0
                select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                    (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & ...
                    (direction == unique_direction(g)) & (cue_val ~= CUEONLY) );
                if isempty(select)
                    long_sm_ungrouped_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
                    long_ungrouped_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
                else
                    for m = 1:length(select)
                        t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                        long_ungrouped_prestim_raster{i,j,k,g}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff-long:t_stimon+poststim+buff+long, select(m));
                        temp_sm_raster = conv(gaussfilt, long_ungrouped_prestim_raster{i,j,k,g}(m,:)); %convolve with the gaussian filters
                        long_sm_ungrouped_prestim_raster{i,j,k,g}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                    end
                end
                if length(select) > 0
                    long_sm_ungrouped_prestim_psth{i,j,k,g} = sum(long_sm_ungrouped_prestim_raster{i,j,k,g},1)./length(select).*spksamprate; %sum and scale rasters to get psth
                    long_ungrouped_prestim_psth{i,j,k,g} = sum(long_ungrouped_prestim_raster{i,j,k,g}(:,buff+1:end-buff),1)./length(select).*spksamprate; %psth is NOT binned
                else
                    long_sm_ungrouped_prestim_psth{i,j,k,g} = NaN.*zeros(1,prestim+poststim+2*long+1);
                    long_ungrouped_prestim_psth{i,j,k,g} = NaN.*zeros(1,prestim+poststim+2*long+1);
                end
                
            end
        end
    end
    %repeat this collapsing across all coherences for the cue response
    for j = 1:2 %again for the two choices - a little kludgey organization but allows roc computation and inclusion of cue only trials
        select = trials(select_trials & (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) );
        if isempty(select)
            long_postcue_raster{j,k} = NaN.*ones(1,precue+postcue+2*long+1);
            long_sm_postcue_raster{j,k} = NaN.*ones(1,precue+postcue+2*long+1);
        else
            for m = 1:length(select)
                t_cueon = find(data.event_data(1,:,select(m)) == CUE_ON_CD) + cue_timing_offset;
                long_postcue_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_cueon-precue-buff-long:t_cueon+postcue+buff+long, select(m));
                temp_sm_raster = conv(gaussfilt, long_postcue_raster{j,k}(m,:)); %convolve with the gaussian filters
                long_sm_postcue_raster{j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
            end
        end
        long_sm_postcue_psth{j,k} = sum(long_sm_postcue_raster{j,k},1)./length(select).*spksamprate; %psth is NOT binned
    end 
    %also combine the two directions in the postcue to get a single postcue psth
    long_sm_postcue_combined_raster{k} = [long_sm_postcue_raster{1,k}; long_sm_postcue_raster{2,k}];
    long_sm_postcue_combined_psth{k} = sum(long_sm_postcue_combined_raster{k},1)./size(long_sm_postcue_combined_raster{k},1).*spksamprate;
end
long_sm_sacc_raster = cell(length(unique_coherence),2,length(unique_cue_dir_type));
long_sacc_raster = cell(length(unique_coherence),2,length(unique_cue_dir_type));
for k = 1:length(unique_cue_dir_type)
    for i = 1:length(unique_coherence)
        for j = 1:2 %PrefChoice=1, NullChoice=2
            %first select the relevant trials and get a raster
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & (cue_val ~= CUEONLY) );
%             if ( (i==2) & (j==2) & (k==3) )
%                 keyboard
%             end
            if isempty(select)
                long_sacc_raster{i,j,k} = NaN.*ones(1,presacc+postsacc+2*long+1);
                long_sm_sacc_raster{i,j,k} = NaN.*ones(1,presacc+postsacc+2*long+1);
            else
                for m = 1:length(select)
                    t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);
                    long_sacc_raster{i,j,k}(m,:) = data.spike_data(SpikeChan, t_sacc-presacc-buff-long:t_sacc+postsacc+buff+long, select(m));
                    temp_sm_raster = conv(gaussfilt, long_sacc_raster{i,j,k}(m,:));
                    long_sm_sacc_raster{i,j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff);
                end
            end
            long_sm_sacc_psth{i,j,k} = sum(long_sm_sacc_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters
            long_sacc_psth{i,j,k} = sum(long_sacc_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters
            for g = 1:length(unique_direction) %Motion: PrefDir = 1, NullDir = 0
                select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                    (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & ...
                    (direction == unique_direction(g)) & (cue_val ~= CUEONLY) );
                if isempty(select)
                    long_ungrouped_sacc_raster{j,k} = NaN.*ones(1,presacc+postsacc+2*long+1);
                    long_sm_ungrouped_sacc_raster{j,k} = NaN.*ones(1,presacc+postsacc+2*long+1);
                else
                    for m = 1:length(select)
                        t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD,1);
                        long_ungrouped_sacc_raster{i,j,k,g}(m,:) = data.spike_data(SpikeChan, t_sacc-presacc-buff-long:t_sacc+postsacc+buff+long, select(m));
                        temp_sm_raster = conv(gaussfilt, long_ungrouped_sacc_raster{i,j,k,g}(m,:)); %convolve with the gaussian filters
                        long_sm_ungrouped_sacc_raster{i,j,k,g}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                    end
                end
                if length(select) > 0
                    long_sm_ungrouped_sacc_psth{i,j,k,g} = sum(long_sm_ungrouped_sacc_raster{i,j,k,g},1)./length(select).*spksamprate; %sum and scale rasters to get psth
                    long_ungrouped_sacc_psth{i,j,k,g} = sum(long_ungrouped_sacc_raster{i,j,k,g}(:,buff+1:end-buff),1)./length(select).*spksamprate; %psth is NOT binned
                else
                    long_sm_ungrouped_sacc_psth{i,j,k,g} = NaN.*zeros(1,presacc+postsacc+2*long+1);
                    long_ungrouped_sacc_psth{i,j,k,g} = NaN.*zeros(1,presacc+postsacc+2*long+1);
                end
            end
        end
    end
end
for k = 1:length(unique_cue_dir_type)
    for j = 1:2
        select = trials(select_trials & (trial_choices == 2-j) & ...
            (cue_dir_type == unique_cue_dir_type(k)) & (cue_val == CUEONLY) );
        if isempty(select)
            long_sm_co_postcue_raster{j,k} = NaN;
            long_sm_co_postcue_psth{j,k} = NaN.*ones(precue_co+postcue_co+2*long+1,1);
            long_sm_co_prestim_raster{j,k} = NaN;
            long_sm_co_prestim_psth{j,k} = NaN.*ones(prestim_co+poststim_co+2*long+1,1);
            long_sm_co_sacc_raster{j,k} = NaN;
            long_sm_co_sacc_psth{j,k} = NaN.*ones(presacc+postsacc+2*long+1,1);
        else
            for m = 1:length(select)
                % t_stimon = find(data.spike_data(2,:,select(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset; 
                t_cueon = find(data.event_data(1,:,select(m)) == CUE_ON_CD) + cue_timing_offset;
                t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);

                long_co_postcue_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_cueon-precue_co-buff-long:t_cueon+postcue_co+buff+long, select(m));
%                 long_co_postcue_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_cueon-precue-buff-long:t_cueon+postcue+buff+long, select(m));
                temp_sm_raster = conv(gaussfilt, long_co_postcue_raster{j,k}(m,:)); %convolve with the gaussian filters
                long_sm_co_postcue_raster{j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges

                long_co_prestim_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim_co-buff-long:t_stimon+poststim_co+buff+long, select(m));
%                 long_co_prestim_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff-long:t_stimon+poststim+buff+long, select(m));
                temp_sm_raster = conv(gaussfilt, long_co_prestim_raster{j,k}(m,:)); %convolve with the gaussian filters
                long_sm_co_prestim_raster{j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges

                long_co_sacc_raster{j,k}(m,:) = data.spike_data(SpikeChan, t_sacc-presacc-buff-long:t_sacc+postsacc+buff+long, select(m));
                temp_sm_raster = conv(gaussfilt, long_co_sacc_raster{j,k}(m,:));
                long_sm_co_sacc_raster{j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff);
            end

            long_sm_co_postcue_psth{j,k} = sum(long_sm_co_postcue_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            long_postcue_psth{j,k} = sum(long_co_postcue_raster{j,k},1)./length(select).*spksamprate;

            long_sm_co_prestim_psth{j,k} = sum(long_sm_co_prestim_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            long_prestim_psth{j,k} = sum(long_co_prestim_raster{j,k},1)./length(select).*spksamprate;

            long_sm_co_sacc_psth{j,k} = sum(long_sm_co_sacc_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            long_co_sacc_psth{j,k} = sum(long_co_sacc_raster{j,k},1)./length(select).*spksamprate;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%
%Now compute the zero-pct crossing of the fit for each cue_type.  
for k = 1:length(unique_cue_dir_type)
    d = [];
    for i = 1:length(unique_coherence)
        total = sum(logical( select_trials & (coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(k)) ));
        corr = sum(logical( select_trials & trial_outcomes & (coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(k)) ));
        pct_corr(k,i) = corr./total;
        d = [d; unique_coherence(i) pct_corr(k,i) total];
    end
    [alpha(k) beta(k) offset(k)] = weibull_bs_fit(d);
end

%%%%%%%%%%%%%%%%%%%%%%
%Splitting the data.  Split by cue-motion ISI or monkey RT.
%1) Folded Behavior by RT: Does slower choice signify weaker or stronger cue effect?
%2) Folded Behavior by ISI: Is the cue effect strong if the motion more closely follows the cue?
%3) Unfolded physiology
%compute unfolded RTs and ISIs
for i = 1:length(trials)
    rt(i) = find(data.event_data(1,:,i)==SACCADE_BEGIN_CD) - find(data.event_data(1,:,i)==TARGS_ON_CD);
    isi(i) = find(data.event_data(1,:,i)==VSTIM_ON_CD) - find(data.event_data(1,:,i)==CUE_OFF_CD);
end
%split by median of RT or ISI, compute behavior (folded)
for i = 1:length(unique_coherence)
    for k = 1:length(unique_cue_val)
        if unique_cue_val(k) == CUEONLY
            select = select_trials & (cue_val == CUEONLY); %kluge to combine across coher for cueonly 
        else 
            select = select_trials & (coherence == unique_coherence(i)) & (cue_val == unique_cue_val(k));
        end
        jitrt = rt + 1e-3.*(randn(1,length(rt)))-0.5; %this adds a teensy bit of noise to eliminate redundant medians
        lort = find(select & jitrt<=median(jitrt(select))); %these are indices for the appropriate trials
        hirt = find(select & jitrt>median(jitrt(select)));
        jitisi = isi + 1e-3.*(randn(1,length(isi)))-0.5;
        loisi = find(select & jitisi<=median(jitisi(select)));
        hiisi = find(select & jitisi>median(jitisi(select)));
        lort_pctcorr(i,k) = sum(trial_outcomes(lort))/length(lort); %pct correct for low rt trials
        hirt_pctcorr(i,k) = sum(trial_outcomes(hirt))/length(hirt);
        loisi_pctcorr(i,k) = sum(trial_outcomes(loisi))/length(loisi);
        hiisi_pctcorr(i,k) = sum(trial_outcomes(hiisi))/length(hiisi);
    end
end
%stuff for saving here
save_splitbehav = 0;
if save_splitbehav 
    savename = sprintf('Z:\\Data\\Tempo\\Baskin\\Analysis\\CDD_split_behavior\\ShortDurDelayCells\\Psy2D-%s.txt',FILE);
    temp = [unique_coherence'; lort_pctcorr'; hirt_pctcorr'; loisi_pctcorr'; hiisi_pctcorr'];
    %the first row are the values of the signed coherence
    %the next 4 rows are the pct correct for null, neutral and pref dir and cueonly cues respectively among short reaction time (LORT) trials.
    %subsequent 3 sets of 4 rows are the same for hirt, loisi, and hiisi trials.
    save(savename, 'temp', '-ascii'); 
end

%now split by median and extract psths
for i = 1:length(unique_coherence)
    for k = 1:length(unique_cue_dir_type)
        for j = 1:2
            if unique_cue_val(k) == CUEONLY
                select = select_trials & (trial_choices == 2-j) & (cue_val == CUEONLY); %kluge to combine across coher for cueonly 
            else 
                select = select_trials & (coherence == unique_coherence(i)) & (trial_choices == 2-j) & (cue_val == unique_cue_val(k));
            end
            jitrt = rt + 1e-3.*(randn(1,length(rt)))-0.5; %this adds a teensy bit of noise to eliminate redundant medians 
            lort = find(select & jitrt<=median(jitrt(select))); %these are indices for the appropriate trials
            hirt = find(select & jitrt>median(jitrt(select)));
            jitisi = isi + 1e-3.*(randn(1,length(isi)))-0.5;
            loisi = find(select & jitisi<=median(jitisi(select)));
            hiisi = find(select & jitisi>median(jitisi(select)));
            %obtain long smooth psth: long_lort_....
            if isempty(lort)
                long_lort_sm_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
                long_lort_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
            else
                for m = 1:length(lort)
                    % t_stimon = find(data.spike_data(2,:,lort(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                    t_stimon = find(data.event_data(1,:,lort(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                    long_lort_prestim_raster{i,j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff-long:t_stimon+poststim+buff+long, lort(m));
                    temp_sm_raster = conv(gaussfilt, long_lort_prestim_raster{i,j,k}(m,:)); %convolve with the gaussian filters
                    long_lort_sm_prestim_raster{i,j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                end
            end
            long_lort_sm_prestim_psth{i,j,k} = sum(long_lort_sm_prestim_raster{i,j,k},1)./length(lort).*spksamprate; %sum and scale rasters to get psth
            long_lort_prestim_psth{i,j,k} = sum(long_lort_prestim_raster{i,j,k},1)./length(lort).*spksamprate; 
            %obtain long smooth psth: long_hirt_....
            if isempty(hirt)
                long_hirt_sm_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
                long_hirt_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
            else
                for m = 1:length(hirt)
                    % t_stimon = find(data.spike_data(2,:,hirt(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                    t_stimon = find(data.event_data(1,:,hirt(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                    long_hirt_prestim_raster{i,j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff-long:t_stimon+poststim+buff+long, hirt(m));
                    temp_sm_raster = conv(gaussfilt, long_hirt_prestim_raster{i,j,k}(m,:)); %convolve with the gaussian filters
                    long_hirt_sm_prestim_raster{i,j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                end
            end
            long_hirt_sm_prestim_psth{i,j,k} = sum(long_hirt_sm_prestim_raster{i,j,k},1)./length(hirt).*spksamprate; %sum and scale rasters to get psth
            long_hirt_prestim_psth{i,j,k} = sum(long_hirt_prestim_raster{i,j,k},1)./length(hirt).*spksamprate; 
            %obtain long smooth psth: long_loisi_....
            if isempty(loisi)
                long_loisi_sm_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
                long_loisi_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
            else
                for m = 1:length(loisi)
                    % t_stimon = find(data.spike_data(2,:,loisi(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                    t_stimon = find(data.event_data(1,:,loisi(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                    long_loisi_prestim_raster{i,j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff-long:t_stimon+poststim+buff+long, loisi(m));
                    temp_sm_raster = conv(gaussfilt, long_loisi_prestim_raster{i,j,k}(m,:)); %convolve with the gaussian filters
                    long_loisi_sm_prestim_raster{i,j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                end
            end
            long_loisi_sm_prestim_psth{i,j,k} = sum(long_loisi_sm_prestim_raster{i,j,k},1)./length(loisi).*spksamprate; %sum and scale rasters to get psth
            long_loisi_prestim_psth{i,j,k} = sum(long_loisi_prestim_raster{i,j,k},1)./length(loisi).*spksamprate; 
            %obtain long smooth psth: long_hiisi_....
            if isempty(hiisi)
                long_hiisi_sm_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
                long_hiisi_prestim_raster{i,j,k} = NaN.*ones(1,prestim+poststim+2*long+1);
            else
                for m = 1:length(hiisi)
                    % t_stimon = find(data.spike_data(2,:,hiisi(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                    t_stimon = find(data.event_data(1,:,hiisi(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                    long_hiisi_prestim_raster{i,j,k}(m,:) = data.spike_data(SpikeChan, t_stimon-prestim-buff-long:t_stimon+poststim+buff+long, hiisi(m));
                    temp_sm_raster = conv(gaussfilt, long_hiisi_prestim_raster{i,j,k}(m,:)); %convolve with the gaussian filters
                    long_hiisi_sm_prestim_raster{i,j,k}(m,:) = temp_sm_raster(2*buff+1:end-2*buff); %lop off the edges
                end
            end
            long_hiisi_sm_prestim_psth{i,j,k} = sum(long_hiisi_sm_prestim_raster{i,j,k},1)./length(hiisi).*spksamprate; %sum and scale rasters to get psth
            long_hiisi_prestim_psth{i,j,k} = sum(long_hiisi_prestim_raster{i,j,k},1)./length(hiisi).*spksamprate;             
        end
    end
end


%%%%%%%%%%%%%%%%%%%
%do some additional smoothing and compute the CDI and CMI, also do permuation tests: 
%CDI = (dircue - neucue) / ( abs(dircue - neucue) + sqrt( (var(dircue)+var(neucue))/2 ) )
%CMI = (dircue - neucue) / (dircue + neucue) 
%The relevant window is 200-400ms 
stddev = 30;
buff = 3*stddev; lb = 100;
gaussfilt = normpdf([1:2*buff+1],buff+1,stddev); %gaussian filter 3 std.dev's wide
t_on = 200; t_off = 400;
for i = 1:length(unique_coherence)
    for j = 1:2
        for k = 1:length(unique_cue_dir_type)
            for m = 1:size(long_sm_prestim_raster{i,j,k})
                temp = conv(gaussfilt, long_sm_prestim_raster{i,j,k}(m,:));
                long_sm2_prestim_raster{i,j,k}(m,:) = temp(lb+buff+1:end-lb-buff);
            end
            windowmean{i,j,k} = mean(long_sm2_prestim_raster{i,j,k}(:,prestim+t_on+1:prestim+t_off),2);
            %windowmean - each matrix has a list of mean values for each trial of that type during the window 
        end
        CMI(i,j,1) = (mean(windowmean{i,j,1}) - mean(windowmean{i,j,2})) ./ ...
                     (mean(windowmean{i,j,1}) + mean(windowmean{i,j,2})); %T2-CMI
        CMI(i,j,2) = (mean(windowmean{i,j,3}) - mean(windowmean{i,j,2})) ./ ...
                     (mean(windowmean{i,j,3}) + mean(windowmean{i,j,2})); %T1-CMI
        CDI(i,j,1) = (mean(windowmean{i,j,1}) - mean(windowmean{i,j,2})) ./ ...
            ( abs(mean(windowmean{i,j,1}) - mean(windowmean{i,j,2})) + ...
              sqrt((var(windowmean{i,j,1})+var(windowmean{i,j,2}))/2) ); %T2-CDI
        CDI(i,j,2) = (mean(windowmean{i,j,3}) - mean(windowmean{i,j,2})) ./ ...
            ( abs(mean(windowmean{i,j,3}) - mean(windowmean{i,j,2})) + ...
              sqrt((var(windowmean{i,j,3})+var(windowmean{i,j,2}))/2) ); %T1-CDI                 
    end
end
meanCMI = squeeze(nanmean(nanmean(CMI,1),2)); %avg across coherence and choice
meanCDI = squeeze(nanmean(nanmean(CDI,1),2)); 
nboot = 1000; %for permutation test
for b = 1:nboot
    for i = 1:length(unique_coherence)
        for j= 1:2
            for k = [1 3]
                dirneuwm = [windowmean{i,j,k}; windowmean{i,j,2}];
                ntrials = size(dirneuwm,1);
                if ntrials > 0
                    bootshuff = randperm(ntrials);
                    bootdir = dirneuwm(bootshuff(1:size(windowmean{i,j,k})));
                    bootneu = dirneuwm(bootshuff(1+size(windowmean{i,j,k}):end));
                    tempbootCMI(i,j,(k+1)/2) = (mean(bootdir)-mean(bootneu)) ./ (mean(bootdir)+mean(bootneu));
                    tempbootCDI(i,j,(k+1)/2) = (mean(bootdir)-mean(bootneu)) ./ ...
                        ( abs(mean(bootdir)-mean(bootneu)) + sqrt((var(bootdir)+var(bootneu))/2) );
                else
                    tempbootCMI{i,j,(k+1)/2} = NaN;
                    tempbootCDI{i,j,(k+1)/2} = NaN;
                end
            end
        end
    end
    bootCMI(b,:) = nanmean(nanmean(tempbootCMI,1),2);
    bootCDI(b,:) = nanmean(nanmean(tempbootCDI,1),2);
end
sortbootCMI = sort(bootCMI);
sortbootCDI = sort(bootCDI);
CMI_hiCI = sortbootCMI(ceil(0.975*nboot),:)
CMI_loCI = sortbootCMI(ceil(0.025*nboot),:)
CDI_hiCI = sortbootCDI(ceil(0.975*nboot),:)
CDI_loCI = sortbootCDI(ceil(0.025*nboot),:)
h_CMI = (CMI_loCI > meanCMI') | (CMI_hiCI < meanCMI');
h_CDI = (CDI_loCI > meanCDI') | (CDI_hiCI < meanCDI');

% now divide the data by reaction time

save_CMICDI = 0;
if save_CMICDI
    %------------------------------------------------------------------------
    %write out all CMI and CDI and sig test results to a cumulative text file, VR 10/31/2007
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CMICDI.dat'];
%     outfile = ['Z:\Data\Tempo\Baskin\Analysis\CMICDI.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t T1CMI\t T2CMI\t T1CMIsig\t T2CMIsig\t T1CDI\t T2CDI\t T1CDIsig\t T2CDIsig\t ');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %6.5f\t %6.5f\t %d\t %d\t %6.5f\t %6.5f\t %d\t %d\t', ...
        FILE, meanCMI(2:-1:1), h_CMI(2:-1:1), meanCDI(2:-1:1), h_CDI(2:-1:1)); 
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
    %----------------------------------------------------------------------
    %--
end

%these were just to help me code... delete this when i finish debugging
% for i = 1:length(unique_coherence)
%     for j = 1:2
%         for k = 1:3
%             tempmean{i,j}(k,:) = mean(cum_prestim_psth{i,j,k}(:,prestim+t_on+1:prestim+t_off),2);
%         end
%         CMI(i,j,1,:) = (tempmean{i,j}(1,gooddata) - tempmean{i,j}(2,gooddata)) ./ ...
%                        (tempmean{i,j}(1,gooddata) + tempmean{i,j}(2,gooddata));
%         CMI(i,j,2,:) = (tempmean{i,j}(3,gooddata) - tempmean{i,j}(2,gooddata)) ./ ...
%                        (tempmean{i,j}(3,gooddata) + tempmean{i,j}(2,gooddata));
%     end
% end


%%%%%%%%%%%
%now save the following variables to a common matrix and save the file
%sm_prestim_psth{i,j,k}, sm_postcue_psth{j,k}, sm_sacc_psth{i,j,k},
%sm_postcue_combined_psth{k}
%sm_co_prestim_psth{j,k}, sm_co_postcue_psth{j,k}, sm_co_sacc_psth{i,j,k} 

SAVEDATA = 0;

if SAVEDATA

    SAVEFILE = sprintf('Z:\\Data\\Tempo\\Baskin\\Analysis\\LIP_PSTH\\ShortDurDelay\\%s_psth_summary.mat',FILE(1:8));
    file = FILE; coher = unique_coherence';
    save(SAVEFILE, 'file', 'coher', 'normval', 'sm_postcue_combined_psth', 'sm_postcue_psth', ...
        'sm_co_postcue_psth', 'sm_co_prestim_psth', 'sm_co_sacc_psth', 'sm_prestim_psth', 'sm_sacc_psth', ...
        'long_sm_postcue_combined_psth', 'long_sm_postcue_psth', 'long_sm_co_postcue_psth', 'long_sm_co_prestim_psth', ...
        'long_sm_co_sacc_psth', 'long_sm_prestim_psth', 'long_sm_sacc_psth', ...
        'sm_ungrouped_prestim_psth', 'long_sm_ungrouped_prestim_psth', 'long_ungrouped_prestim_psth', ...
        'sm_ungrouped_sacc_psth', 'long_sm_ungrouped_sacc_psth','long_ungrouped_sacc_psth',...
        'long_lort_sm_prestim_psth','long_hirt_sm_prestim_psth','long_loisi_sm_prestim_psth','long_hiisi_sm_prestim_psth',...
        'num_trials', 'offset');
    
%     SAVEFILE = 'Z:\LabTools\Matlab\TEMPO_Analysis\ProtocolSpecific\CuedDirectionDiscrim\cum_lip_psth3.mat';
%     load(SAVEFILE);
% 
%     cum_file{length(cum_file)+1} = FILE;
%     cum_coher = [cum_coher; unique_coherence'];
%     cum_normval = [cum_normval; normval];
%     for k = 1:length(unique_cue_dir_type)
%         cum_postcue_combined_psth{k}(end+1,:) = sm_postcue_combined_psth{k};
%         for j = 1:2 %prefchoice = 1, nullchoice = 2
%             cum_postcue_psth{j,k}(end+1,:) = sm_postcue_psth{j,k};
%             cum_co_postcue_psth{j,k}(end+1,:) = sm_co_postcue_psth{j,k};
%             cum_co_prestim_psth{j,k}(end+1,:) = sm_co_prestim_psth{j,k};
%             cum_co_sacc_psth{j,k}(end+1,:) = sm_co_sacc_psth{j,k};
%             for i = 1:length(unique_coherence)
%                 cum_prestim_psth{i,j,k}(end+1,:) =
%                 sm_prestim_psth{i,j,k};
%                 cum_sacc_psth{i,j,k}(end+1,:) = sm_sacc_psth{i,j,k};
%             end
%         end
%     end
% 
%     save(SAVEFILE, 'cum_file','cum_coher','cum_normval',...
%         'cum_postcue_combined_psth','cum_postcue_psth','cum_prestim_psth','cum_sacc_psth',...
%         'cum_co_postcue_psth','cum_co_prestim_psth','cum_co_sacc_psth');
end



% line below initializes variables stored in cum_lip_psth.mat
% cum_file = []; cum_coher = []; cum_postcue_combined_psth = repmat({[]},[1,3]); cum_normval = [];
% cum_postcue_psth = repmat({[]},[2,3]); cum_prestim_psth = repmat({[]},[5,2,3]); cum_sacc_psth = repmat({[]},[5,2,3]); 
% cum_co_postcue_psth = repmat({[]},[2,3]); cum_co_prestim_psth = repmat({[]},[2,3]); cum_co_sacc_psth = repmat({[]},[2,3]); 
