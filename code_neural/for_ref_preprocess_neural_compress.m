

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% This code is for reference %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% set parameters and load data

addpath('../code_base'); set_config(); disp(config)

exp_type = '7t'; sess_i = 0; str_dir = '7t'; func_dir_name_list = {'em1','em2','em3'}; n_worker = 7;


is_time = false;
roi_method = 'prob';
opt_img = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_partial = 0;
% is_partial = 1; % early
% is_partial = 2; % late
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_correct_motion = false;
is_correct_motion = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% set base directories
data_dir_base = sprintf('../../data_%s',str_dir);
result_dir_base = sprintf('../../results_em_%s',str_dir);

if strcmp(exp_type,'3t')
    dir_fmri = sprintf('%s/data/data_fmri_sess%d_preprocessed', config.base_3t, sess_i);
elseif strcmp(exp_type,'7t')
    dir_fmri = sprintf('%s/data/data_fmri_preprocessed',config.base_7t);
end

organize_dir = sprintf('./data_organized_%s/act_%s', roi_method, str_dir);
if ~exist(organize_dir, 'dir'); mkdir(organize_dir); end

% get data
dir_behav = config.(sprintf('behav_%s',exp_type));
func_load_data(dir_behav, exp_type, sess_i, data_dir_base); % sbj_list, data_all, valid_behav_sbj, valid_fmri_sbj

% reset workers
func_reset_workers();


%% load segmentation
if strcmp(exp_type,'3t')
    in_dir = sprintf('%s/data_fmri_seg/', data_dir_base); 
elseif strcmp(exp_type,'7t')
    in_dir = sprintf('%s/data_fmri_seg_from_rawT1/', data_dir_base); 
end


seg_all = {};
parfor (sbj_i = 1:length(data_all), n_worker)
% for sbj_i = 1:length(data_all)
    sbj = data_all{sbj_i};
    sbj_name = sbj_list{sbj_i};
    if isempty(sbj.em.valid_fmri_trial); continue; end

    data = load(fullfile(in_dir, sbj_name));
    seg_all{sbj_i} = data.sbj;
end

%% set ROI
roi_type_list = {'hpc_hbt', 'hpc_main','hpc_main_ap'};


sbj_flag = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);

roi_name_list_all = {};
vox_cnt_for_boot_all = {};
for roi_type_i = 1:length(roi_type_list)

    roi_type = roi_type_list{roi_type_i};
    type1 = roi_type(1:3);
    type2 = roi_type(5:end);
    target_roi_type = 'roi_list_prob';

    idx = find(~cellfun(@isempty, seg_all), 1);
    roi_name_list = seg_all{idx}.seg_fit.(type1).(type2).roi_name_list;
    n_roi = length(roi_name_list)/2;
    temp = cellfun(@(x) ['Bi.',x(4:end)], roi_name_list(1:n_roi), uni=0);
    roi_name_list = [roi_name_list(:)', temp(:)'];

    roi_name_list_all{roi_type_i} = roi_name_list;
    

    if ~contains(roi_type, '_ap')
        temp_cnt = [];
        for roi_i = 1:n_roi*2
            temp_cnt(roi_i) = min(cellfun(@(seg) length(seg.seg_fit.(type1).(type2).(target_roi_type){roi_i}), seg_all(sbj_flag)));
        end

        temp = min(temp_cnt);
        temp = [repmat(temp,1,2*n_roi), repmat(temp*2,1,n_roi)];
    else
        temp_cnt = [];
        for roi_i = 1:n_roi*2
            temp_cnt(roi_i) = min(cellfun(@(seg) length(seg.seg_fit.(type1).(type2).(target_roi_type){roi_i}), seg_all(sbj_flag)));
        end
        temp = reshape(temp_cnt,2,[]);
        temp = min(temp);
        temp = [temp;temp];
        temp = temp(:)';

        temp2 = reshape(temp,[],2);
        temp2 = sum(temp2');
        
        temp = [temp, temp2];
    end
    vox_cnt_for_boot_all{roi_type_i} = temp;

end



%% collect image
con_target_list = {'enc_period','ret_period','ret_enact', 'enc_fix', 'ret_fix'};

n_shots = 6;

act_all = {}; %{sbj_i}{con_i}{roi_type_i}{roi_i}
parfor (sbj_i = 1:length(sbj_list), 4)
% for sbj_i = 1:length(sbj_list)
    cd(dir_working);

    sbj = data_all{sbj_i};
    sbj_name = sbj_list{sbj_i};

    trials = data_all{sbj_i}.em.trials;    
    valid_trial = data_all{sbj_i}.em.valid_trial;
    valid_fmri_trial = data_all{sbj_i}.em.valid_fmri_trial;
 
    if sum(valid_fmri_trial)==0
        act_all{sbj_i} = {};
        continue
    end

    % get image
    img_sbj = {};
    for trial_i = valid_fmri_trial
        run_i = ceil(trial_i/2);
        trial_ii = mod(trial_i-1,2) + 1;

        in_dir = fullfile(dir_fmri, sbj_name, func_dir_name_list{run_i});
        func = jh_get_file_list(in_dir, target_reg_exp,'regexp');
        task_reg = fullfile(dir_reg, sprintf('%s_%s.mat',sbj_name, func_dir_name_list{run_i}));

        move = move_all{sbj_i}{run_i};  move_diff = [zeros(1,size(move,2)); diff(move)];
        rot = rot_all{sbj_i}{run_i};    rot_diff = [zeros(1,size(rot,2)); diff(rot)];
        fd = fd_all{sbj_i}{run_i};
        move_reg = [move, rot, fd];

        reg = load(task_reg);
        names = reg.names;
        onsets = reg.onsets;
        durations = reg.durations;


        % load data
        idx = find(cellfun(@(x) strcmp(x, 'enc_fix'), names));
        idx = idx(trial_ii);
        onset = onsets{idx};
        onset = jh_fmri_time2ind(onset, false);
        idx_start = onset;

        idx = find(cellfun(@(x) strcmp(x, 'ret_conf_fix'), names));
        idx = idx(trial_ii);
        onset = onsets{idx};
        onset = jh_fmri_time2ind(onset, false);
        idx_end = onset;
        idx_end = min(idx_end, length(func)); % exception

        idx_target = idx_start:idx_end;


        data = cellfun(@niftiread, func(idx_target), uni=0);
        data = double(cat(4,data{:}));


        T = size(data, 4);
        V = prod(size(data,1:3));
        temp_reshaped = reshape(permute(data, [4 1 2 3]), T, V); 
        
        if is_correct_motion
            temp_reshaped = func_get_residual_analytic(move_reg(idx_target, :), temp_reshaped);
        else
            temp_reshaped = detrend(temp_reshaped, 'constant'); % same as demean
        end
        
        temp_reshaped = detrend(temp_reshaped, 'linear'); 
        
        data = ipermute(reshape(temp_reshaped, [T, size(data,1), size(data,2), size(data,3)]), [4 1 2 3]);

        % match length
        data_final = zeros( [size(data,1:3), length(func)] );
        data_final(:,:,:,idx_target) = data;
        data = data_final;

        % crop
        for con_i = 1:length(con_target_list)
            idx = find(cellfun(@(x) strcmp(x, con_target_list{con_i}), names));
            idx = idx(trial_ii);

            onset = onsets{idx};
            onset = jh_fmri_time2ind(onset, false);
            offset = onsets{idx} + durations{idx};
            offset = jh_fmri_time2ind(offset,false);
            if contains(con_target_list{con_i}, 'fix')
                offset = onset + n_shots - 1;
            end

            offset = min(offset, size(data,4));  % exception

            target = onset:offset;
            
            if contains(con_target_list{con_i}, 'enc_period') || contains(con_target_list{con_i}, 'ret_enact') 
                len = offset - onset + 1;
                mid = onset + floor((len-1)/2);

                if is_partial == 1
                    s = onset; 
                    e = mid;
                    L = e - s + 1;
                    need = max(0, n_shots - L);
                    e = min(offset, e + need);
                    s = max(onset, s); 
                    e = min(offset, e);
                    target = s:e;

                elseif is_partial == 2
                    s = mid; 
                    e = offset;
                    L = e - s + 1;
                    need = max(0, n_shots - L);
                    s = max(onset, s - need);
                    s = max(onset, s); 
                    e = min(offset, e);
                    target = s:e;
                end
            end


            img_sbj{con_i}{trial_i} = data(:,:,:,target);
        end
    end

    for con_i = 1:length(con_target_list)
        img_sbj{con_i}( cellfun(@isempty, img_sbj{con_i}) ) = [];
    end


    % ROI
    seg = seg_all{sbj_i};
    
    act_sbj = {};

    for roi_type_i = 1:length(roi_type_list)

        roi_type = roi_type_list{roi_type_i};
        type1 = roi_type(1:3);
        type2 = roi_type(5:end);
        target_roi_type = 'roi_list_prob';

        roi_name_list = roi_name_list_all{roi_type_i};
        n_roi = length(roi_name_list)/3;

        for roi_i = 1:length(roi_name_list)

            if roi_i <= n_roi*2
                roi = seg_all{sbj_i}.seg_fit.(type1).(type2).(target_roi_type){roi_i};
            else
                roi = [seg_all{sbj_i}.seg_fit.(type1).(type2).(target_roi_type){roi_i-2*n_roi}(:); ...
                       seg_all{sbj_i}.seg_fit.(type1).(type2).(target_roi_type){roi_i-n_roi}(:) ];
            end

            for con_i = 1:length(con_target_list)
                for trial_i = 1:length(img_sbj{con_i})
                    img = img_sbj{con_i}{trial_i};
                    img = reshape(img, [], size(img,4)); 
                    act_sbj{con_i}{roi_type_i}{roi_i}{trial_i} = img(roi, :);

                end
            end
            
        end
    end

    act_all{sbj_i} = act_sbj;

end


%% NEURAL COMPRESSION
%%
%%
%% collect metric

n_boot = 1000;
metric_type_list = {'var90','var80','var75','slope10','slope20','slope30','dim','entropy'};

metric_raw_all = {}; %{con_i}{roi_type_i}{roi_i}{sbj_i}(metric_type_i)


for con_i = 1:length(con_target_list)

    for roi_type_i = 1:length(roi_type_list)
        roi_name_list = roi_name_list_all{roi_type_i};
        for roi_i = 1:length(roi_name_list)

            metric_collect = {};
            parfor sbj_i = 1:length(data_all)
                rng(sbj_i + 1e3*roi_i + 1e5*con_i + 1e7*roi_type_i)

                if isempty(act_all{sbj_i})
                    continue
                end

                data = act_all{sbj_i}{con_i}{roi_type_i}{roi_i};
                n_vox = vox_cnt_for_boot_all{roi_type_i}(roi_i);

                try

                metric_boot = [];
                for boot_i = 1:n_boot
                    metric_temp = [];

                    % voxel permutation
                    vox_idx = randperm(size(data{1},1), n_vox);

                    % time permutation
                    temp = {};
                    for trial_i = 1:length(data)
                        start_idx = randi([1,size(data{trial_i},2)-n_shots+1], 1);
                        time_idx = start_idx:(start_idx+n_shots-1);
                        temp{trial_i} = data{trial_i}(vox_idx, time_idx);
                    end

                    x = cat(2,temp{:});

                    % eigen-spectrum
                    if ~is_time
                        x = x';
                    end
                    
                    x = x - mean(x,1);
                    [u,s,~] = svd(x,'econ');
                    eigvals = diag(s).^2 / (size(x,1)-1);
                    eigvals = sort(eigvals, 'descend');
                    
                    % explained variance
                    cumvar = cumsum(eigvals) / sum(eigvals);
                    metric_temp(end+1) = find(cumvar >= 0.9, 1);
                    metric_temp(end+1) = find(cumvar >= 0.8, 1);
                    metric_temp(end+1) = find(cumvar >= 0.75, 1);
                    
                    % slope of log-log eigenspectrum
                    if length(eigvals) >=10
                        k = 10; x = log10(1:k)'; y = log10(eigvals(1:k)); slope = polyfit(x, y, 1); metric_temp(end+1) = slope(1);
                    else
                        metric_temp(end+1) = nan;
                    end

                    if length(eigvals) >=20
                        k = 20; x = log10(1:k)'; y = log10(eigvals(1:k)); slope = polyfit(x, y, 1); metric_temp(end+1) = slope(1);
                    else
                        metric_temp(end+1) = nan;
                    end
                    
                    if length(eigvals) >= 30
                        k = 30; x = log10(1:k)'; y = log10(eigvals(1:k)); slope = polyfit(x, y, 1); metric_temp(end+1) = slope(1);
                    else
                        metric_temp(end+1) = nan;
                    end
    
                    % effective dimensionality
                    metric_temp(end+1) = (sum(eigvals)^2) / sum(eigvals.^2);
    
                    % spectral entropy
                    p = eigvals / sum(eigvals);
                    entropy = -sum(p .* log2(p + 1e-10));
                    entropy = entropy / log2(length(p));
                    metric_temp(end+1) = entropy;

                    metric_boot(boot_i,:) = metric_temp;
                end
                metric_boot = mean(metric_boot);

                catch
                    metric_boot = nan(1,8);
                end

                metric_collect{sbj_i} = metric_boot;
            end

            metric_raw_all{con_i}{roi_type_i}{roi_i} = metric_collect;

        end
        

        fprintf('[%s] done - con: %s roi type: %s \n', ...
            datestr(now,31), con_target_list{con_i}, roi_type_list{roi_type_i});
        fprintf('\n\n')
    end
end

%% save

for roi_type_i = 1:length(roi_type_list)

    metric_all = {}; %{con_i+metric_type_i}{roi_i}{sbj_i}
    con_name_list = {};
    roi_name_list = roi_name_list_all{roi_type_i};

    for con_i = 1:length(con_target_list)
        for metric_i = 1:length(metric_type_list)
            feat_i = metric_i + (con_i-1)*length(metric_type_list);
            con_name_list{feat_i} = [ con_target_list{con_i}, ' ', metric_type_list{metric_i} ];

            for roi_i = 1:length(roi_name_list)
                metric_all{feat_i}{roi_i} = [];

                for sbj_i = 1:length(data_all)

                    if isempty(metric_raw_all{con_i}{roi_type_i}{roi_i}{sbj_i})
                        metric_all{feat_i}{roi_i}(sbj_i) = nan;
                    else
                        metric_all{feat_i}{roi_i}(sbj_i) = metric_raw_all{con_i}{roi_type_i}{roi_i}{sbj_i}(metric_i);
                    end
                end
                
            end

        end
    end

    if is_correct_motion
        if ~is_time
            str_save_type = 'compress_fix5_move_corrected';
        else
            str_save_type = 'compress_fix5_move_corrected_time'; 
        end
    else
%         str_save_type = 'compress_fix5';
    end

    if is_partial == 1
        str_save_type = [str_save_type, '_early'];
    elseif is_partial == 2
        str_save_type = [str_save_type, '_late'];
    end

    save( sprintf('%s/%s_%s.mat', organize_dir, str_save_type, roi_type_list{roi_type_i}), ...
        'con_name_list','roi_name_list', 'metric_all' )
end



