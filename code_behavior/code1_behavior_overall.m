%% set parameters

addpath('../code_base');
set_config();
disp(config)

%%%%%%%%%%%%%%%%%%%%%%%%%%
target_data = '3t'; sess_i = 1;
target_data = '7t'; sess_i = 0;
target_data = 'us'; sess_i = 0;
target_data = 'ALL'; sess_i = 1;
% target_data = 'MRI'; sess_i = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%

%% load data

if strcmp(target_data, 'ALL')
    [data_all1, age1, sex1, group1] = func_load_behav_data(config.('behav_3t'));
    [data_all2, age2, sex2, group2] = func_load_behav_data(config.('behav_7t'));
    [data_all3, age3, sex3, group3] = func_load_behav_data(config.('behav_us'));
    data_all = [data_all1, data_all2, data_all3];
    age = [age1, age2, age3];
    sex = [sex1, sex2, sex3];
    type_exp = [1*ones(1,length(age1)), 2*ones(1,length(age2)), 3*ones(1,length(age3)) ];

elseif strcmp(target_data, 'MRI')
    [data_all1, age1, sex1, group1] = func_load_behav_data(config.('behav_3t'));
    [data_all2, age2, sex2, group2] = func_load_behav_data(config.('behav_7t'));
    data_all = [data_all1, data_all2];
    age = [age1, age2];
    sex = [sex1, sex2];
    type_exp = [1*ones(1,length(age1)), 2*ones(1,length(age2)) ];

else
    path_name = sprintf('behav_%s', target_data);
    [data_all, age, sex, group] = func_load_behav_data(config.(path_name));
end

metric = func_get_em_metric(data_all, sess_i, 1:5, []);

fprintf('%d subjects (%d male, %d female)\n', length(age), sum(sex==1), sum(sex==0))
fprintf('age: %.2f (sd: %.2f)\n', nanmean(age), nanstd(age))

%% accuracy plots

%%% overall
flag_sbj = true(1,length(metric.full.and));

data = {metric.what.recog, metric.what.when, metric.where.recog, metric.where.when, metric.what_where, metric.full.and};
data = cellfun(@(x) x(flag_sbj(1:length(x))), data, uni=0);

color = {config.color_what; config.color_what; config.color_where; config.color_where;  ...
         jh_color_modify_hsv(config.color_em, 'saturation',0.8); config.color_em};

figure;
fig_box = jh_boxchart(data, color=color, divider=2, drawpoint=true);
xticklabels({' '})
yticks(.2:.2:1)
jh_set_fig(BarWidthUnit=.41)

func_stats_single(data{1}-data{2}, 'what vs. what-when')
func_stats_single(data{3}-data{4}, 'where vs. where-when')
func_stats_single(data{5}-data{1}, 'full vs. what-where')
func_stats_single(data{3}-data{5}, 'what-where vs. what-when')
func_stats_single(data{4}-data{3}, 'where-when vs. what-when')


%%% proportions
flag_sbj = metric.full.and < 0.8;

data = {cellfun(@(x) x(2)*100, metric.diagram), cellfun(@(x) x(3)*100, metric.diagram), ...
        cellfun(@(x) x(4)*100, metric.diagram), cellfun(@(x) x(5)*100, metric.diagram)};
temp = cellfun(@(x) sum(x(2:5)), metric.diagram);
data = cellfun(@(x) x./temp, data, uni=0);
data = cellfun(@(x) x(flag_sbj(1:length(x))), data, uni=0);

color = {config.color_what; config.color_where; config.color_em; jh_color_modify_hsv(config.color_em, 'saturation',0.5)};


figure;
fig_box = jh_bar(data,'color',color);
xticklabels({' '})
ylim([0 100])
xticks(find(~cellfun(@isempty, data)));
yticks(20:20:100)
jh_set_fig()

func_stats_single(data{2}-data{1}, 'what vs. where')
func_stats_single(data{1}-data{3}, 'what vs. what-where')
func_stats_single(data{2}-data{3}, 'where vs. what-where')
func_stats_single(data{3}-data{4}, 'fail vs. what-where')

%% spatiotemporal bias

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flag_sbj = true(1,length(metric.full.and));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% index - point-level
data = metric.where_bias.point(flag_sbj);

bin_size = 0.1;
bins = (-1:bin_size:1) + bin_size/2;

figure;
hold on
histogram(data(data>bin_size/2), bins, FaceColor=config.color_where, EdgeColor=config.edge_color, LineWidth=config.hist_line_width, FaceAlpha = 1)
histogram(data(data<-bin_size/2), bins, FaceColor=config.color_what, EdgeColor=config.edge_color, LineWidth=config.hist_line_width, FaceAlpha = 1)
histogram(data(abs(data)<=bin_size/2), bins, FaceColor=[.6 .6 .6], EdgeColor=config.edge_color, LineWidth=config.hist_line_width, FaceAlpha = 1)

yticks(5:5:25)
jh_set_fig(size=config.fig_size/.9, fontsize=config.font_size, linewidth=config.line_width)
func_stats_single(data)

[p,tbl,stats] = anovan(data, {categorical(type_exp), categorical(sex)}, 'model','interaction');
disp(tbl)

%%% index - trial-level
data = metric.where_bias.trial(flag_sbj) ./ metric.where_bias.n_trial(flag_sbj);

bin_size = 0.08;
bins = (-1:bin_size:1) + bin_size/2;

figure;
hold on
histogram(data(data>bin_size/2), bins, FaceColor=config.color_where, EdgeColor=config.edge_color, LineWidth=config.hist_line_width, FaceAlpha = 1)
histogram(data(data<-bin_size/2), bins, FaceColor=config.color_what, EdgeColor=config.edge_color, LineWidth=config.hist_line_width, FaceAlpha = 1)
histogram(data(abs(data)<=bin_size/2), bins, FaceColor=[.6 .6 .6], EdgeColor=config.edge_color, LineWidth=config.hist_line_width, FaceAlpha = 1)

yticks(5:5:25)
jh_set_fig(size=config.fig_size/.9, fontsize=config.font_size, linewidth=config.line_width)
func_stats_single(data)


%%% what vs. where better trial
data = {metric.where_bias.acc_what(flag_sbj), metric.where_bias.acc_where(flag_sbj)};
color = {config.color_what; config.color_where};

figure;
fig = jh_bar(data, Drawpoint=false, color=color, linewidth=0.5);
xticklabels({' '})
xlim([0,length(data)+1])
yticks(.1:.1:.4)
jh_set_fig()

func_stats_single(data{1}-data{2})

%%% confidence
data = {metric.conf.what.overall(flag_sbj), metric.conf.where.overall(flag_sbj)};
color = {config.color_what; config.color_where};

figure;
fig = jh_bar(data, Drawpoint=false, color=color, linewidth=0.5);
xticklabels({' '})
xlim([0,length(data)+1])
ylim([.5 .8])
yticks(.5:.1:1)
jh_set_fig()

func_stats_single(data{1}-data{2})


%% position-wise accuracy

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flag_sbj = true(1,length(data_all));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data_what = {};
data_where = {};
for pos = 1:5
    temp = func_get_em_metric(data_all(flag_sbj), 1, pos);
    data_what{pos} = temp.what.when;
    data_where{pos} = temp.where.when;
end

figure;
hold on

data = data_what; color = config.color_what;
[avg,err] = jh_mean_err(data);
fig_err = errorbar([1:length(avg)]-0.1, avg, err,'-square');
fig_err.Color = color;  fig_err.LineWidth = config.err_line_width;  fig_err.CapSize = config.err_cap_size;  
fig_err.MarkerFaceColor = color; fig_err.MarkerSize = config.err_marker_size; fig_err.MarkerEdgeColor = color;

data = data_where; color = config.color_where;
[avg,err] = jh_mean_err(data);
fig_err = errorbar([1:length(avg)]+0.1, avg, err,'-square');
fig_err.Color = color;  fig_err.LineWidth = config.err_line_width;  fig_err.CapSize = config.err_cap_size;  
fig_err.MarkerFaceColor = color; fig_err.MarkerSize = config.err_marker_size; fig_err.MarkerEdgeColor = color;


xticks(1:5); xticklabels({}); xlim([0.5 5.5])
yticks(0.5:0.1:0.8)

jh_set_fig(size=config.fig_size/.9, fontsize=config.font_size)

