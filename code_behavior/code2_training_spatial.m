%% set parameters

addpath('../code_base');
set_config();
disp(config)

%% load data
[data_all, age, sex, group] = func_load_behav_data(config.('behav_3t'), true);

spatial_metric_sess_wise = func_get_spatial_metric_sess_wise(data_all, 'acc_coin');
[spatial_metric_training, spatial_metric_training_cov] = func_get_spatial_metric_training(data_all, 'acc_coin','slope',1,7);

%% training curve
data = cellfun(@(x) x(group==1), spatial_metric_sess_wise(1:7), uni=0);
color = config.color_where;

figure;
hold on
for i = 1:length(data{1})
    plot(cellfun(@(x) x(i), data), color=[.2 .2 .2 .2], linewidth=.5)
end

[avg,err] = jh_mean_err(data);
fig_err = errorbar([1:length(avg)], avg, err,'-square');

fig_err.Color = color;  fig_err.LineWidth = config.err_line_width;  fig_err.CapSize = config.err_cap_size;  
fig_err.MarkerFaceColor = color; fig_err.MarkerSize = config.err_marker_size; fig_err.MarkerEdgeColor = color;

xticks(1:7); xlim([0.5 7.3]); xticklabels({})
yticks(0.7:0.1:1.0); ylim([0.65 1])

jh_set_fig(size=config.fig_size, fontsize=config.font_size)

% temp stats
flag = group==1 & spatial_metric_training > nanmedian(spatial_metric_training); flag1=flag;
flag = group==1 & spatial_metric_training <= nanmedian(spatial_metric_training); flag2=flag;
data = cellfun(@(x) x, spatial_metric_sess_wise(1:7), 'uni', 0);

func_stats_compare(data{1}(flag1),data{1}(flag2))

%% training index
data = {spatial_metric_training(group == 1)};  
color = config.color_where;

figure;
yline(0,color=[.7 .7 .7], linewidth=0.1)
fig_box = jh_boxchart(data,'color', color, 'DrawPoint',true);

xticks([]); xticklabels({}); xlim([-.2 2.1])
jh_set_fig()

func_stats_single(data{1})

%% group comparison - 2bars & 4bars

%%%%%%%%%%%%%%%%%%%%%%%%%
flag = group==1;

metric = spatial_metric_sess_wise;
y_ticks = 0.6:0.1:1; y_lim = [0.6 1]; y_ticks2 = -.2:.1:.2;
%%%%%%%%%%%%%%%%%%%%%%%%%

metric_sess8 = metric{8};
metric_sess1 = metric{1};
metric = metric_sess8 - metric_sess1;

color_exp = config.color_where;
color_ctrl = config.color_where2;

% 4 bars
data = { metric_sess1(group==1),metric_sess8(group==1), ...
         metric_sess1(group==0),metric_sess8(group==0) };
color = { color_exp; color_exp;  color_ctrl ; color_ctrl};

figure;
[fig_box, x_ticks] = jh_boxchart(data, 'color',color, 'DrawPoint',true, 'DrawMedian',true, ...
                           'DrawMedianLine',true, 'DrawPointLine', {[1,2],[3,4]}, divider=2, width=.6);

xticks(x_ticks); xticklabels({''})
yticks(y_ticks); ylim(y_lim)

jh_set_fig()

% 2 bars
data = {metric(group==1), metric(group==0)};
color = {color_exp ; color_ctrl};

figure;
yline(0,':',color=[.2 .2 .2],linewidth=.5)
fig_box = jh_boxchart(data,'color',color, 'DrawPoint',true);
xlim([.1 2.7]); xticks(1:2); xticklabels({})
yticks(y_ticks2)
jh_set_fig('position',[10 3])

func_stats_training(metric_sess1, metric_sess8, group, sex)


