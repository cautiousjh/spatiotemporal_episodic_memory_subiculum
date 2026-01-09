%% set parameters and load data


addpath('../code_base'); set_config(); disp(config)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exp_type = '3t'; sess_i = 1; str_dir = '3t';        data_dir_base = config.behav_3t;
% exp_type = '3t'; sess_i = 2; str_dir = '3t_post';   data_dir_base = config.behav_3t;
exp_type = '7t'; sess_i = 0; str_dir = '7t';    data_dir_base = config.behav_7t;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dir_behav = config.(sprintf('behav_%s',exp_type));
func_load_data(dir_behav, exp_type, sess_i, data_dir_base); % sbj_list, data_all, valid_behav_sbj, valid_fmri_sbj

% set behavioral metric
metric = func_get_em_metric(data_all, sess_i, 1:5, []);

behav_metric_list = { metric.full.and, metric.what.when, metric.where.when, ...
                      metric.where_bias.point, metric.where_bias.trial, ...
                      func_get_residual(metric.full.and, metric.where_bias.point), ...
                      func_get_residual(metric.full.and, metric.where_bias.trial), ...
                      func_get_residual(metric.what.when, metric.where.when), ...
                      func_get_residual(metric.where.when, metric.what.when) };

behav_metric_name_list = {'full','what-when','where-when', ...
                          'bias','bias trial','bias(res)','bias trial(res)', ...
                          'where\what', 'what\where'};

%% for subregional difference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
roi_type = 'hpc_main';

str_neural = 'compress_fix5_move_corrected';

stat_type = 'nonparam';
p_cutoff = 0.05; 
sbj_flag = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);

target_con = 1;
target_con_list = [1:8] + (target_con-1) * 8;

is_sub_fix = true;
is_sub_fix = false;

is_diff = true;
% is_diff = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load metric
load( sprintf('./data_organized/act_%s/%s_%s.mat', str_dir, str_neural, roi_type) ) 


%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_trial = cellfun(@(x) length(x.em.valid_fmri_trial), data_all);
elim_flag = n_trial ~= mode(n_trial);

for roi_i = 1:length(roi_name_list)
    for con_i = 1:length(con_name_list)
        metric_all{con_i}{roi_i}(elim_flag) = nan;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%


if is_sub_fix

    for roi_i = 1:length(roi_name_list)
        for con_i = 1:length(con_name_list)
            period_i = ceil(con_i/8);
            metric_type_i = mod(con_i-1, 8) + 1;
    
            if period_i == 1
                offset = 8*3;
            elseif period_i == 2 
                offset = 8*3;
            elseif period_i == 3
                offset = 8*2;
            else
                offset = 0;
            end
            metric_all{con_i}{roi_i} = metric_all{con_i}{roi_i} - metric_all{con_i+offset}{roi_i};    
        end
    end

end

neural_metric = {};
roi_final_name_list = {};
if strcmp(roi_type, 'hpc_Hbt')

elseif strcmp(roi_type, 'hpc_main')
    
    if is_diff
        for con_i = 1:length(con_name_list)
            for side_i = 1:3
                for compare_i = 1:3
                    if compare_i == 1; roi_i = 2; roi_j = 1;
                    elseif compare_i == 2; roi_i = 3; roi_j = 1;
                    elseif compare_i == 3; roi_i = 3; roi_j = 2;
                    end
    
                    idx = compare_i + (side_i-1)*3;
                    roi_i = roi_i + (side_i-1)*3;
                    roi_j = roi_j + (side_i-1)*3;
    
                    neural_metric{con_i}{idx} = metric_all{con_i}{roi_i} - metric_all{con_i}{roi_j};
    
                    if con_i == 1
                        roi_final_name_list{idx} = [roi_name_list{roi_i}, ' - ', roi_name_list{roi_j}(4:end)];
                    end
    
                end
            end
        end
    else
        neural_metric = metric_all;
        roi_final_name_list = roi_name_list;
    end
else
    neural_metric = metric_all;
    roi_final_name_list = roi_name_list;
end

neural_metric = neural_metric(target_con_list);
con_name_list = con_name_list(target_con_list);
roi_name_list = roi_final_name_list;

con_name_list

% draw p table
% data = [];
% data_raw = {};
% for roi_i = 1:length(roi_name_list)
%     for con_i = 1:length(con_name_list)
%         try
%             temp = neural_metric{con_i}{roi_i}(sbj_flag);
%             if strcmp(stat_type,'param')
%                 [~,p] = ttest(temp);
%             else
%                 p = signrank(temp);
%             end
%             if nanmean(temp)<0
%                 p = -p;
%             end
%             data(roi_i,con_i) = p;
%         catch
%             data(roi_i,con_i) = nan;
%         end
%         data_raw{roi_i, con_i} = temp;
%     end
% end
% jh_p_table(data, roi_name_list, cellfun(@(x) replace(x,'_',' '),con_name_list, 'uni', 0), p_cutoff, data_raw);
% % xline(size(data,2)/2+0.5, 'k-', linewidth=3)
% jh_set_fig(size=[size(data,2)*1.5, size(data,1)])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
con_i = 7;
% con_i = 8;

roi = 7:9;
% roi = 4:6;

color = config.color_em;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data = cellfun(@(x) x(sbj_flag), neural_metric{con_i}(roi), uni=0);

figure;
[fig_bar,x_ticks] = jh_bar(data, drawpoint=false, color=color);
xticks(x_ticks); 
xticklabels({});

jh_set_fig


disp(sprintf('%s  (n=%d)', con_name_list{con_i},  sum(~isnan(data{1}))))

cellfun(@(x,str) func_stats_single(x, str), data, roi_name_list(roi))
func_stats_compare(data{3}, data{1})
func_stats_compare(data{3}, data{2})


%% for correlation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
roi_type = 'hpc_main';

str_neural = 'compress_fix5_move_corrected';

stat_type = 'nonparam';
p_cutoff = 0.05; 
sbj_flag = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);

target_con = 1;
target_con_list = [1:8] + (target_con-1) * 8;

is_sub_fix = true;
% is_sub_fix = false;

is_diff = true;
is_diff = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load metric
load( sprintf('./data_organized/act_%s/%s_%s.mat', str_dir, str_neural, roi_type) ) 


%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_trial = cellfun(@(x) length(x.em.valid_fmri_trial), data_all);
elim_flag = n_trial ~= mode(n_trial);

for roi_i = 1:length(roi_name_list)
    for con_i = 1:length(con_name_list)
        metric_all{con_i}{roi_i}(elim_flag) = nan;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%


if is_sub_fix

    for roi_i = 1:length(roi_name_list)
        for con_i = 1:length(con_name_list)
            period_i = ceil(con_i/8);
            metric_type_i = mod(con_i-1, 8) + 1;
    
            if period_i == 1
                offset = 8*3;
            elseif period_i == 2 
                offset = 8*3;
            elseif period_i == 3
                offset = 8*2;
            else
                offset = 0;
            end
            metric_all{con_i}{roi_i} = metric_all{con_i}{roi_i} - metric_all{con_i+offset}{roi_i};    
        end
    end

end

neural_metric = {};
roi_final_name_list = {};
if strcmp(roi_type, 'hpc_Hbt')

elseif strcmp(roi_type, 'hpc_main')
    
    if is_diff
        for con_i = 1:length(con_name_list)
            for side_i = 1:3
                for compare_i = 1:3
                    if compare_i == 1; roi_i = 2; roi_j = 1;
                    elseif compare_i == 2; roi_i = 3; roi_j = 1;
                    elseif compare_i == 3; roi_i = 3; roi_j = 2;
                    end
    
                    idx = compare_i + (side_i-1)*3;
                    roi_i = roi_i + (side_i-1)*3;
                    roi_j = roi_j + (side_i-1)*3;
    
                    neural_metric{con_i}{idx} = metric_all{con_i}{roi_i} - metric_all{con_i}{roi_j};
    
                    if con_i == 1
                        roi_final_name_list{idx} = [roi_name_list{roi_i}, ' - ', roi_name_list{roi_j}(4:end)];
                    end
    
                end
            end
        end
    else
        neural_metric = metric_all;
        roi_final_name_list = roi_name_list;
    end
else
    neural_metric = metric_all;
    roi_final_name_list = roi_name_list;
end

neural_metric = neural_metric(target_con_list);
con_name_list = con_name_list(target_con_list);
roi_name_list = roi_final_name_list;

con_name_list

% correlation table
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sbj_flag = true(1,length(neural_metric{1}{1}));
% sbj_flag = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);
% 
% con_i = 7;
% % con_i = 8;
% 
% corr_type = 'spearman';
% p_cutoff = 0.05;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% data_behav = {};
% for behav_i = 1:length(behav_metric_list)
%     temp = behav_metric_list{behav_i}(sbj_flag);
%     data_behav{behav_i} = temp;
% end
% 
% data_neural = {};
% for roi_i = 1:length(roi_name_list)
%     temp = neural_metric{con_i}{roi_i}(sbj_flag);
%     data_neural{roi_i} = temp;
% end
% 
% jh_corr_table(data_neural, data_behav, roi_name_list, behav_metric_name_list, p_cutoff, corr_type)
% title(replace(con_name_list{con_i}, '_', ' ') )
% % xline([n:n:size(data_behav,2)]+0.5, 'w-', linewidth=3)
% jh_set_fig(size=[length(data_behav)*1.5+1, length(data_neural)])


% correlation plot

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sbj_flag = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);

con_i = 7;
behav_i = 4;

roi_i = 6;

color = config.color_where;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


disp(con_name_list{con_i})
disp(behav_metric_name_list{behav_i})

data1 = behav_metric_list{behav_i}(sbj_flag);
data2 = neural_metric{con_i}{roi_i}(sbj_flag);

figure;
[r1,p1] = jh_regress(data1, data2,'on', ...
                    'MarkerColor', color,'markeralpha',1, ...
                    'ShadeColor', color, 'ShadeAlpha', .15, linewidth=config.regress_line_width);
[r2,p2] = jh_regress(data1, data2,'off','type','spearman');
if p2 < 0.05; jh_regress(data1, data2,'line', linecolor=color, linewidth=config.regress_line_width); end


jh_set_fig(scale = 1, ...
    size=config.fig_size, fontsize=config.font_size, position=[14 3], markersize=config.regress_marker_size)

title_str1 = sprintf('Pearson r = %.3f (p = %.3f)',r1,p1);
if p1 < 0.05; title_str1 = [title_str1,'*']; end
title_str2 = sprintf('Spearman r = %.3f (p = %.3f)',r2,p2);
if p2 < 0.05; title_str2 = [title_str2,'*']; end
title_str = {title_str1, title_str2};
fprintf('%s\n', title_str{:})

