%% set parameters

addpath('../code_base');
set_config();
disp(config)

%% load data
[data_all, age, sex, group] = func_load_behav_data(config.('behav_3t'), true);

% get metrics
em_metric1 = func_get_em_metric(data_all, 1, 1:5);
em_metric2 = func_get_em_metric(data_all, 2, 1:5);

spatial_metric_sess_wise = func_get_spatial_metric_sess_wise(data_all, 'acc_coin');
[spatial_metric_training, spatial_metric_training_cov] = func_get_spatial_metric_training(data_all, 'acc_coin','slope',1,7);

%% exp vs. ctrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flag_sbj = true(1,length(data_all));
is_residual = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
func_get_target_metric = @(x) x.full.and; color = config.color_em;
% func_get_target_metric = @(x) x.full.or; color = config.color_em;
% func_get_target_metric = @(x) x.full.sum; color = config.color_em;
% func_get_target_metric = @(x) x.what.recog; color = config.color_what;
% func_get_target_metric = @(x) x.what.when; color = config.color_what;
% func_get_target_metric = @(x) x.where.recog; color = config.color_where;
% func_get_target_metric = @(x) x.where.when; color = config.color_where;
% func_get_target_metric = @(x) x.what_where; color = config.color_em;
% func_get_target_metric = @(x) x.conf.what.overall; color = config.color_what;
% func_get_target_metric = @(x) x.conf.where.overall; color = config.color_where;
% func_get_target_metric = @(x) x.rt.where.overall; color = config.color_where;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

metric_pre = func_get_target_metric(em_metric1);
metric_post = func_get_target_metric(em_metric2);

% control for subjcts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% func_metric_temp = @(x) x.full.and;  
% metric = func_get_em_metric_all(data_all, 1, 1:5);                                          
% metric = func_metric_temp(metric);
% flag_sbj = metric < prctile(metric,75);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

metric_pre = metric_pre(flag_sbj);
metric_post = metric_post(flag_sbj);
metric = metric_post - metric_pre;

color_exp = color;
color_ctrl = jh_color_modify(color_exp, 'saturation',0.5, 'value', 1);

% 2 bars
data = {metric(group(flag_sbj)==1), metric(group(flag_sbj)==0)};
color = {color_exp ; color_ctrl};

figure;
yline(0,':',color=[.2 .2 .2],linewidth=.5)
fig_box = jh_boxchart(data,'color',color, 'DrawPoint',true);
xlim([.1 2.7]); xticks(1:2); xticklabels({})
jh_set_fig('position',[10 3])

func_stats_training(metric_pre, metric_post, group(flag_sbj), sex(flag_sbj))

%%
% correlation
flag = group(flag_sbj)==1;
data1 = spatial_metric_training(flag); data1_cov = spatial_metric_training_cov(flag);

data2 = metric(flag); data2_cov = metric_pre(flag);

if is_residual
    data1 = func_get_residual(data1_cov,data1);
    data2 = func_get_residual(data2_cov,data2);
end

figure;
[r1,p1] = jh_regress(data1, data2,'on', ...
                    'MarkerColor', color_exp,'markeralpha',1, ...
                    'ShadeColor', color_exp, 'ShadeAlpha', .15, linewidth=config.regress_line_width);
[r2,p2] = jh_regress(data1, data2,'off','type','spearman');
if p2 < 0.05; jh_regress(data1, data2,'line', linecolor=color_exp); end

jh_set_fig(size=config.fig_size, fontsize=config.font_size, position=[14 3], markersize=config.regress_marker_size)

title_str1 = sprintf('Pearson r = %.3f (p = %.3f)',r1,p1);
if p1 < 0.05; title_str1 = [title_str1,'*']; end
title_str2 = sprintf('Spearman r = %.3f (p = %.3f)',r2,p2);
if p2 < 0.05; title_str2 = [title_str2,'*']; end
title_str = {title_str1, title_str2};
fprintf('%s\n', title_str{:})


%% position-wise accuracy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flag_sbj = true(1,length(data_all));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% func_get_target_metric = @(x) x.full.and; color = config.color_em; y_lim = [-.07 .28]; y_ticks = 0:.1:.2;
% func_get_target_metric = @(x) x.full.or; color = config.color_em; y_lim = [-.07 .23]; y_ticks = 0:.1:.2;
% func_get_target_metric = @(x) x.what.recog; color = config.color_what;
% func_get_target_metric = @(x) x.what.when; color = config.color_what; y_lim = [-.07 .28]; y_ticks = 0:.1:.2;
% func_get_target_metric = @(x) x.where.recog; color = config.color_where;
func_get_target_metric = @(x) x.where.when; color = config.color_where; y_lim = [-.07 .23]; y_ticks = 0:.1:.2;
% func_get_target_metric = @(x) x.what_where; color = config.color_em;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color_exp = color;
color_ctrl = jh_color_modify(color_exp, 'saturation',0.5, 'value',1);


data = {};
data_pre = {}; data_post = {};
for pos = 1:5
    temp1 = func_get_em_metric(data_all(flag_sbj),1, pos);
    temp2 = func_get_em_metric(data_all(flag_sbj),2, pos);
    data{pos} = func_get_target_metric(temp2) - func_get_target_metric(temp1);
    data_pre{pos} = func_get_target_metric(temp1);
    data_post{pos} = func_get_target_metric(temp2);
end


data_exp = cellfun(@(x) x(group(flag_sbj)==1), data, 'uni', 0);
data_ctrl = cellfun(@(x) x(group(flag_sbj)==0), data, 'uni', 0);

figure;
yline(0,':',color=[.2 .2 .2],linewidth=.5)
hold on

[avg,err] = jh_mean_err(data_exp); color = color_exp;
fig_err = errorbar([1:length(avg)]-0.1, avg, err,'-square');
fig_err.Color = color;  fig_err.LineWidth = config.err_line_width;  fig_err.CapSize = config.err_cap_size;  
fig_err.MarkerFaceColor = color; fig_err.MarkerSize = config.err_marker_size; fig_err.MarkerEdgeColor = color;

[avg,err] = jh_mean_err(data_ctrl); color = color_ctrl;
fig_err = errorbar([1:length(avg)]+0.1, avg, err,':square');
fig_err.Color = color;  fig_err.LineWidth = config.err_line_width;  fig_err.CapSize = config.err_cap_size;  
fig_err.MarkerFaceColor = color; fig_err.MarkerSize = config.err_marker_size; fig_err.MarkerEdgeColor = color;


xticks(1:5); xticklabels(1:5); xlim([0.5 5.5])
ylim(y_lim); yticks(y_ticks)

jh_set_fig(size=config.fig_size, fontsize=config.font_size)


