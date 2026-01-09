%% set parameters and load data


addpath('../code_base'); set_config(); disp(config)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%% get data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
roi_type = 'hpc_main';

% type_neural = 'act'; str_neural = 'act_indiv';
type_neural = 'pat'; str_neural = 'r_pat_indiv';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load metric
load( sprintf('./data_organized/act_%s/%s_%s.mat', str_dir, str_neural, roi_type) ) 

if strcmp(type_neural, 'act')
    neural_metric = act_metric;
    con_name_list = act_con_name_list;
    flag_name_list = act_flag_name_list;
    roi_name_list = roi_name_list;
elseif strcmp(type_neural, 'pat')
    neural_metric = pat_metric;
    con_name_list = con_name_pat_list;
    flag_name_list = flag_name_list;
    roi_name_list = roi_name_list;
    for i = 1:length(con_name_list)
        for j = 1:length(flag_name_list)
            for k = 1:length(roi_name_list)
                if k > length(roi_name_list)*2/3                    
                    n_regions = length(roi_name_list)/3;
                    k2 = mod(k-1, n_regions)+1;
                    neural_metric{i}{j}{k} = (pat_metric{i}{j}{k2} + pat_metric{i}{j}{k2+n_regions})/2;
                end
            end
        end
    end
end



%%
% p-table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sbj_flag = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);

stat_type = 'nonparam';
p_cutoff = 0.05; 

flag_i = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


data = [];
data_raw = {};
for roi_i = 1:length(roi_name_list)
    for con_i = 1:length(con_name_list)
        try
            temp = neural_metric{con_i}{flag_i}{roi_i}(sbj_flag);
            if strcmp(stat_type,'param')
                [~,p] = ttest(temp);
            else
                p = signrank(temp, 0, 'method', 'approximate');
            end
            if nanmean(temp)<0
                p = -p;
            end
            data(roi_i,con_i) = p;
        catch
            data(roi_i,con_i) = nan;
        end
        data_raw{roi_i, con_i} = temp;
    end
end
jh_p_table(data, roi_name_list, cellfun(@(x) replace(x,'_',' '),con_name_list, 'uni', 0), p_cutoff, data_raw);
title(flag_name_list{flag_i})

jh_set_fig(size=[size(data,2)*1.5, size(data,1)])
%% bar - activation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
con_i = 2; % retrieval

% flag_i = 1; % all
% flag_i = 2; % correct only
flag_i = 3; % correct vs. not

roi = 7:9; % bilateral

color = config.color_em;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color2 = jh_color_modify(color, 'saturation', .1, 'value', 1);

data = cellfun(@(x) x(sbj_flag), neural_metric{con_i}{flag_i}(roi), uni=0);

% average activation
if length(roi) > 3; n_divider = length(data)/3; else; n_divider = 3; end
n_divider = 3;

figure;
[fig_bar,x_ticks] = jh_bar(data, drawpoint=false, divider=n_divider, color=color);
xticks(x_ticks); 
xticklabels({});


jh_set_fig()
disp(sprintf('%s (%s) (n=%d)', con_name_list{con_i}, flag_name_list{flag_i}, sum(~isnan(data{1}))))

cellfun(@(x,str) func_stats_single(x, str), data, roi_name_list(roi))
func_stats_compare(data{3}, data{1})
func_stats_compare(data{3}, data{2})


%% correlation table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sbj_flag = true(1,length(neural_metric{1}{1}{1}));
sbj_flag = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);

con_i = 1;

flag_i = 1;

corr_type = 'spearman';
p_cutoff = 0.05;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data_behav = {};
for behav_i = 1:length(behav_metric_list)
    temp = behav_metric_list{behav_i}(sbj_flag);
    data_behav{behav_i} = temp;
end

data_neural = {};
for roi_i = 1:length(roi_name_list)
    temp = neural_metric{con_i}{flag_i}{roi_i}(sbj_flag);
    data_neural{roi_i} = temp;
end

jh_corr_table(data_neural, data_behav, roi_name_list, behav_metric_name_list, p_cutoff, corr_type)
title(sprintf('%s', con_name_list{con_i}) )
% xline([n:n:size(data_behav,2)]+0.5, 'w-', linewidth=3)
jh_set_fig(size=[length(data_behav)*1.5+1, length(data_neural)])


%% correlation plot

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sbj_flag = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);

con_i = 1; flag_i = 1; behav_i = 4; color = config.color_where;

roi_i = 9;
% roi_i = 7;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


disp(con_name_list{con_i})
disp(behav_metric_name_list{behav_i})
disp(roi_name_list{roi_i})

data1 = behav_metric_list{behav_i}(sbj_flag);
data2 = neural_metric{con_i}{flag_i}{roi_i}(sbj_flag);

figure;
[r1,p1] = jh_regress(data1, data2,'on', ...
                    'MarkerColor', color,'markeralpha',1, ...
                    'ShadeColor', color, 'ShadeAlpha', .15, linewidth=config.regress_line_width);
[r2,p2] = jh_regress(data1, data2,'off','type','spearman');
if p2 < 0.05; jh_regress(data1, data2,'line', linecolor=color, linewidth=config.regress_line_width); end


jh_set_fig(scale = .9, ...
    size=config.fig_size, fontsize=config.font_size, position=[14 3], markersize=config.regress_marker_size)

title_str1 = sprintf('Pearson r = %.3f (p = %.3f)',r1,p1);
if p1 < 0.05; title_str1 = [title_str1,'*']; end
title_str2 = sprintf('Spearman r = %.3f (p = %.3f)',r2,p2);
if p2 < 0.05; title_str2 = [title_str2,'*']; end
title_str = {title_str1, title_str2};
fprintf('%s\n', title_str{:})
