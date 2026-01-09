
%% set parameters and load data

addpath('../code_base'); set_config(); disp(config)

exp_type = '3t'; sess_i = 0; str_dir = '3t_post'; 


% get data
dir_behav = config.(sprintf('behav_%s', exp_type));
data_dir_base = sprintf('../../data_%s',str_dir);
func_load_data(dir_behav, exp_type, sess_i, data_dir_base); % sbj_list, data_all, valid_behav_sbj, valid_fmri_sbj
group = cellfun(@(x) x.type, data_all);

% get behavior
metric1 = func_get_em_metric(data_all, 1, 1:5, []);
metric2 = func_get_em_metric(data_all, 2, 1:5, []);

[spatial_metric_training, spatial_metric_training_cov] = func_get_spatial_metric_training(data_all, 'acc_coin','slope',1,7);

temp = func_get_spatial_metric_sess_wise(data_all, 'acc_coin');
spatial_metric_pre = temp{1};
spatial_metric_post = temp{8};

% set behavioral metric
behav_metric_list = { metric2.full.and - metric1.full.and, ...
                 metric2.what.when - metric1.what.when, ...
                 metric2.where.when - metric1.where.when, ...
                 metric2.what.recog - metric1.what.recog, ...
                 metric2.where.recog - metric1.where.recog, ...
                 spatial_metric_post - spatial_metric_pre, spatial_metric_training };
behav_cov_list = { metric1.full.and, metric1.what.when, metric1.where.when, ...
                   metric1.what.recog, metric1.where.recog, ...
                   spatial_metric_pre, spatial_metric_training_cov };
behav_name_list = {'full','what-when','where-when', 'what','where', 'post-pre', 'training_idx'};


%% get data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
roi_type = 'hpc_big';
roi_type = 'hpc_main';

type_neural = 'act'; str_neural = 'act_indiv';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load metric
pre = load( sprintf('./data_organized/act_%s/%s_%s.mat', '3t', str_neural, roi_type) ) ;
post = load( sprintf('./data_organized/act_%s/%s_%s.mat', '3t_post', str_neural, roi_type) ) ;

% process
if strcmp(type_neural, 'act')
    con_name_list = pre.act_con_name_list;
    flag_name_list = pre.act_flag_name_list;
    roi_name_list = pre.roi_name_list;

    neural_metric = {};
    neural_metric_cov = {};
    for i = 1:length(con_name_list)
        for j = 1:length(flag_name_list)
            for k = 1:length(roi_name_list)
                temp_pre = pre.act_metric{i}{j}{k};
                temp_post = post.act_metric{i}{j}{k};

                neural_metric{i}{j}{k} = temp_post - temp_pre;
                neural_metric_cov{i}{j}{k} = temp_pre;
            end
        end
    end

elseif strcmp(type_neural, 'pat')
    con_name_list = pre.con_name_pat_list;
    flag_name_list = pre.flag_name_list;
    roi_name_list = pre.roi_name_list;

    neural_metric = {};
    neural_metric_cov = {};
    for i = 1:length(con_name_list)
        for j = 1:length(flag_name_list)
            for k = 1:length(roi_name_list)
                if k <= length(roi_name_list)*2/3
                    temp_pre = pre.pat_metric{i}{j}{k};
                    temp_post = post.pat_metric{i}{j}{k};


                    neural_metric{i}{j}{k} =  temp_post - temp_pre;
                    neural_metric_cov{i}{j}{k} = temp_pre;
                else
                    n_regions = length(roi_name_list)/3;
                    k2 = mod(k-1, n_regions)+1;

                    temp_pre_l = pre.pat_metric{i}{j}{k2};
                    temp_pre_r = pre.pat_metric{i}{j}{k2+n_regions};
                    temp_post_l = post.pat_metric{i}{j}{k2};
                    temp_post_r = post.pat_metric{i}{j}{k2+n_regions};


                    neural_metric{i}{j}{k} = (temp_post_l + temp_post_r - temp_pre_l - temp_pre_r) / 2;
                    neural_metric_cov{i}{j}{k} = (temp_pre_l + temp_pre_r) / 2 ;
                end
            end
        end
    end

end

% # subjects
fprintf('\n\n\n%16s all\n','')
for i = 1:length(flag_name_list)
    fprintf('%15s  %3d\n', flag_name_list{i}, ...
                          sum(~isnan(neural_metric{1}{i}{1})) );
end

%% correlation - fix contrast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_residual = true;

sbj_flag = cellfun(@(x) x.type, data_all) == 1;

corr_type = 'spearman';

p_cutoff = 0.05;

flag_i = 1;
con_i = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp(con_name_list{con_i})

data = [];
data_r = [];
for roi_i = 1:length(roi_name_list) 
    for behav_i = 1:length(behav_name_list)
        data1 = behav_metric_list{behav_i}(sbj_flag);
        data1_cov = behav_cov_list{behav_i}(sbj_flag);
        data2 = neural_metric{con_i}{flag_i}{roi_i}(sbj_flag);
        data2_cov = neural_metric_cov{con_i}{flag_i}{roi_i}(sbj_flag);


        if is_residual
            data1 = func_get_residual(data1_cov, data1);
            data2 = func_get_residual(data2_cov, data2);
        end

        [r,p] = corr(data1(:), data2(:),'rows','pairwise','type',corr_type);
        if nanmean(r)<0
            p = -p;
        end
        data(roi_i,behav_i) = p;
        data_r(roi_i, behav_i) = r;
    end
end

jh_p_table(data, roi_name_list, cellfun(@(x) replace(x,'_',' '),behav_name_list, 'uni', 0), p_cutoff);

jh_set_fig(size=[size(data,2)*2+3, size(data,1)])


%% correlation - plot

behav_i = 7;

con_i = 2;
roi_i = 6;

color = config.color_em; scale = .9;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_residual = true;

sbj_flag = cellfun(@(x) x.type, data_all) == 1;

corr_type = 'spearman';

flag_i = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
color = config.color_em;

disp(con_name_list{con_i})
disp(roi_name_list{roi_i})
disp(behav_name_list{behav_i})


data1 = behav_metric_list{behav_i}(sbj_flag);
data1_cov = behav_cov_list{behav_i}(sbj_flag);
data2 = neural_metric{con_i}{flag_i}{roi_i}(sbj_flag);
data2_cov = neural_metric_cov{con_i}{flag_i}{roi_i}(sbj_flag);

if is_residual
    data1 = func_get_residual(data1_cov, data1);
    data2 = func_get_residual(data2_cov, data2);
end

figure;
[r1,p1] = jh_regress(data1, data2,'on', ...
                    'MarkerColor', color,'markeralpha',1, ...
                    'ShadeColor', color, 'ShadeAlpha', .15, linewidth=config.regress_line_width);
[r2,p2] = jh_regress(data1, data2,'off','type','spearman');
if p2 < 0.05; jh_regress(data1, data2,'line', linecolor=color, linewidth=config.regress_line_width); end


jh_set_fig(scale = scale, ...
    size=config.fig_size, fontsize=config.font_size, position=[14 3], markersize=config.regress_marker_size)

title_str1 = sprintf('Pearson r = %.3f (p = %.3f)',r1,p1);
if p1 < 0.05; title_str1 = [title_str1,'*']; end
title_str2 = sprintf('Spearman r = %.3f (p = %.3f)',r2,p2);
if p2 < 0.05; title_str2 = [title_str2,'*']; end
title_str = {title_str1, title_str2};
fprintf('%s\n', title_str{:})
fprintf('\n\n')

%%
%%


