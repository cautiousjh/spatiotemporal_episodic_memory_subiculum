
function [metric, metric_indiv_all] = func_get_em_metric(data_all, sess_i, pos, elim_trials)
%% parameters
if nargin == 1 || isempty(sess_i)
    sess_i = 0;
    pos = 1:5;
    elim_trials = [];
elseif nargin == 2
    pos = 1:5;
    elim_trials = [];
elseif nargin == 3
    elim_trials = [];
end

time_score = 0.5;

%% setting scores

% get response
resp_what = {};
resp_where = {};
for sbj_i = 1:length(data_all)

    try
        sbj = data_all{sbj_i}.em.sess(sess_i);
    catch
        sbj = data_all{sbj_i}.em;
    end

    temp_sbj_what = zeros(6,6);
    temp_sbj_where = zeros(6,6);
    for trial_i = 1:length(sbj.trials)
        if ~ismember(trial_i, sbj.valid_trial)
            continue
        end

        % object
        temp_trial = zeros(6,6);
        enc = sbj.trials(trial_i).enc.obj;
        ret = sbj.trials(trial_i).ret.obj;
        for point_i = 1:5
            find_i = find(ret == enc(point_i));
            if isempty(find_i)
                temp_trial(point_i,6) = temp_trial(point_i,6) + 1;
            else
                temp_trial(point_i,find_i) = temp_trial(point_i,find_i) + 1;
            end
        end
        
        temp_sbj_what = temp_sbj_what + temp_trial;
        
        % space
        temp_trial = zeros(6,6);
        enc = sbj.trials(trial_i).enc.basket;
        ret = sbj.trials(trial_i).ret.basket;
        for point_i = 1:5
            find_i = find(ret == enc(point_i));
            if isempty(find_i)
                temp_trial(point_i,6) = temp_trial(point_i,6) + 1;
            else
                temp_trial(point_i,find_i) = temp_trial(point_i,find_i) + 1;
            end
        end
        
        temp_sbj_where = temp_sbj_where + temp_trial;

    end

    resp_what{sbj_i} = temp_sbj_what;
    resp_where{sbj_i} = temp_sbj_where;

end

% overall
data_what = sum(cat(3,resp_what{:}),3);
data_where = sum(cat(3,resp_where{:}),3);

temp = sum(data_what,2);
data_what = data_what / temp(1);
data_where = data_where / temp(1);


% score final
score_what = zeros(6,6);
score_where = zeros(6,6);
for i = 1:5
    score_what(i,i) = 1;
    score_where(i,i) = 1;

    temp = data_what(i,:);
    base = 1-sum(temp(i));
    idx = 1:5; idx(i) = [];
    ratio = data_what(i,idx) / max(data_what(i,idx));
    score_what(i,idx) = base * ratio;

    temp = data_where(i,:);
    base = 1-sum(temp(i));
    idx = 1:5; idx(i) = [];
    ratio = data_where(i,idx) / max(data_where(i,idx));
    score_where(i,idx) = base * ratio;

end


%% accuracy metrics for every individuals

metric_indiv_all = {};
for sbj_i = 1:length(data_all)

    try
        sbj = data_all{sbj_i}.em.sess(sess_i);
    catch
        sbj = data_all{sbj_i}.em;
    end

    metric = struct();
    trial_idx = 0;
    for trial_i = 1:length(sbj.trials)
        if ~ismember(trial_i, sbj.valid_trial) || ismember(trial_i, elim_trials)
            continue
        end
        trial = sbj.trials(trial_i);
        trial_idx = trial_idx + 1;

        % full EM
        metric.full.and(trial_idx) = mean( trial.correct.obj_space_time(pos) );
        metric.full.sum(trial_idx) = mean( [trial.correct.obj_time(pos), trial.correct.space_time(pos)] );
        metric.full.or(trial_idx) = mean( trial.correct.obj_time(pos) | trial.correct.space_time(pos) );
        metric.full.tri(trial_idx) = mean( [trial.correct.obj_time(pos), trial.correct.space_time(pos), trial.correct.obj_space(pos)] );
        metric.full.recog(trial_idx) = mean( [trial.correct.obj(pos), trial.correct.space(pos)] );
                
        % what-related
        metric.what.recog(trial_idx) = mean( trial.correct.obj(pos) );
        metric.what.when(trial_idx) = mean( trial.correct.obj_time(pos) );
        % where-related
        metric.where.recog(trial_idx) = mean( trial.correct.space(pos) );
        metric.where.when(trial_idx) = mean( trial.correct.space_time(pos) );

        % probability-based metrics
        temp_what = [];
        temp_where = [];
        for pos_i = pos
            find_i = find(trial.ret.obj == trial.enc.obj(pos_i));
            if isempty(find_i); find_i = 6; end
            temp_what(end+1) = score_what(pos_i,find_i);

            find_i = find(trial.ret.basket == trial.enc.basket(pos_i));
            if isempty(find_i); find_i = 6; end
            temp_where(end+1) = min(score_where(pos_i,find_i));
        end

        metric.what.prob(trial_idx) = mean(temp_what);
        metric.where.prob(trial_idx) = mean(temp_where);
        metric.full.prob(trial_idx) = mean([temp_what, temp_where]);

        % penalty-based metrics
        temp_what = [];
        temp_where = [];
        for pos_i = pos
            if trial.correct.obj_time(pos_i)
                temp_what(end+1) = 1;
            elseif trial.correct.obj(pos_i)
                temp_what(end+1) = time_score;
            else
                temp_what(end+1) = 0;
            end

            if trial.correct.space_time(pos_i)
                temp_where(end+1) = 1;
            elseif trial.correct.space(pos_i)
                temp_where(end+1) = time_score;
            else
                temp_where(end+1) = 0;
            end
        end

        metric.what.penalty(trial_idx) = mean(temp_what);
        metric.where.penalty(trial_idx) = mean(temp_where);
        metric.full.penalty(trial_idx) = mean([temp_what, temp_where]);

        % pure metrics (recognition error neglected)        
        correct_obj = trial.correct.obj_time(pos); 
        flag_obj = trial.correct.obj(pos) == 1;
        metric.what.pure(trial_idx) = mean( correct_obj(flag_obj) );

        correct_space = trial.correct.space_time(pos); 
        flag_space = trial.correct.space(pos) == 1;
        metric.where.pure(trial_idx) = mean( correct_space(flag_space) );

        metric.full.pure(trial_idx) = ( sum(correct_obj(flag_obj)) + sum(correct_space(flag_space)) ) / ( sum(flag_obj) + sum(flag_space) );
        

        % additional overall metrics
        metric.what_where(trial_idx) = mean( trial.correct.obj_space(pos) );

        correct_what = trial.correct.obj_time(pos);
        correct_where = trial.correct.space_time(pos);
        correct_what_where = trial.correct.obj_space(pos);
        correct_both = trial.correct.obj_space_time(pos);
        correct_what_recog = trial.correct.obj(pos);
        correct_where_recog = trial.correct.space(pos);

        metric.n_incorrect(trial_idx) = sum(~correct_both);

        metric.diagram{trial_idx} = [sum(correct_both),  ...
                                     sum(correct_what&~correct_both), sum(correct_where & ~correct_both), sum(correct_what_where & ~correct_both), ...
                                     sum(~correct_what&~correct_where&~correct_what_where) ]/5;

        metric.partial_em(trial_idx) = nanmean(correct_what(~correct_both) + correct_where(~correct_both) == 1);

        temp = correct_where(~correct_both) - correct_what(~correct_both);
        if isempty(temp); temp = nan; else; temp = mean(temp); end
        metric.where_bias(trial_idx) = temp;


        % confidence
        temp_conf = trial.conf_obj(pos); temp_correct = trial.correct.obj_time(pos)==1;
        temp_conf_what = temp_conf; temp_correct_what = temp_correct;
        metric.conf.what.overall(trial_idx) = mean(temp_conf);
        metric.conf.what.correct(trial_idx) = mean(temp_conf(temp_correct));
        metric.conf.what.incorrect(trial_idx) = mean(temp_conf(~temp_correct));
        metric.conf.what.n_correct(trial_idx) = sum(temp_correct);
        metric.conf.what.n_incorrect(trial_idx) = sum(~temp_correct);

        temp_conf = trial.conf_basket(pos); temp_correct = trial.correct.space_time(pos)==1;
        temp_conf_where = temp_conf; temp_correct_where = temp_where;
        metric.conf.where.overall(trial_idx) = mean(temp_conf);
        metric.conf.where.correct(trial_idx) = mean(temp_conf(temp_correct));
        metric.conf.where.incorrect(trial_idx) = mean(temp_conf(~temp_correct));
        metric.conf.where.n_correct(trial_idx) = sum(temp_correct);
        metric.conf.where.n_incorrect(trial_idx) = sum(~temp_correct);

        temp_correct = trial.correct.obj_space_time(pos) == 1;
        metric.conf.both.overall(trial_idx) = mean([temp_conf_what, temp_conf_where]);
        metric.conf.both.correct(trial_idx) = mean([temp_conf_what(temp_correct), temp_conf_where(temp_correct)]);
        metric.conf.both.incorrect(trial_idx) = mean([temp_conf_what(~temp_correct), temp_conf_where(~temp_correct)]);
        metric.conf.both.n_correct(trial_idx) = sum(temp_correct);
        metric.conf.both.n_incorrect(trial_idx) = sum(~temp_correct);

        
        % RTs
        try
            run_i = floor( (trial_i-1)/2 ) + 1;
            trial_ii = mod(trial_i-1,2)+1;
    
            marker = sbj.marker.marker_run(run_i);
    
            time_duration = marker.ret_enact_end(trial_ii) - marker.ret_enact_start(trial_ii);
            if trial_ii == 1; idx = 6; else; idx = 21; end
    
            time_what = [  marker.obj_sel(idx) - marker.ret_enact_start(trial_ii); ...
                           marker.obj_sel(idx+1:idx+4) - marker.move_finish(idx:idx+3) ];
            time_where = marker.basket_sel(idx:idx+4) - marker.obj_sel(idx:idx+4);
            time_point = time_what + time_where;
            
            metric.rt.overall.all(trial_idx) = time_duration;
            if metric.full.and < 0.19; temp = nan; else; temp = time_duration; end
            metric.rt.overall.cut1(trial_idx) = temp;
            if metric.full.and < 0.39; temp = nan; else; temp = time_duration; end
            metric.rt.overall.cut2(trial_idx) = temp;
            if metric.full.and < 0.59; temp = nan; else; temp = time_duration; end
            metric.rt.overall.cut3(trial_idx) = temp;
            if metric.full.and < 0.79; temp = nan; else; temp = time_duration; end
            metric.rt.overall.cut4(trial_idx) = temp;
    
            temp_correct = trial.correct.obj_space_time(pos) == 1;
    
            temp_time = time_point(pos);
            metric.rt.point.overall(trial_idx) = nanmean(temp_time);
            metric.rt.point.correct(trial_idx) = nanmean(temp_time(temp_correct));
            metric.rt.point.incorrect(trial_idx) = nanmean(temp_time(~temp_correct));
            metric.rt.point.n_correct(trial_idx) = sum(temp_correct);
            metric.rt.point.n_incorrect(trial_idx) = sum(~temp_correct);
    
            temp_time = time_what(pos);
            metric.rt.what.overall(trial_idx) = nanmean(temp_time);
            metric.rt.what.correct(trial_idx) = nanmean(temp_time(temp_correct));
            metric.rt.what.incorrect(trial_idx) = nanmean(temp_time(~temp_correct));
            metric.rt.what.n_correct(trial_idx) = sum(temp_correct);
            metric.rt.what.n_incorrect(trial_idx) = sum(~temp_correct);
    
            temp_time = time_where(pos);
            metric.rt.where.overall(trial_idx) = nanmean(temp_time);
            metric.rt.where.correct(trial_idx) = nanmean(temp_time(temp_correct));
            metric.rt.where.incorrect(trial_idx) = nanmean(temp_time(~temp_correct));
            metric.rt.where.n_correct(trial_idx) = sum(temp_correct);
            metric.rt.where.n_incorrect(trial_idx) = sum(~temp_correct);
    
            % log RTs    
            metric.logrt.overall.all(trial_idx) = log(time_duration);
            if metric.full.and < 0.19; temp = nan; else; temp = log(time_duration); end
            metric.logrt.overall.cut1(trial_idx) = temp;
            if metric.full.and < 0.39; temp = nan; else; temp = log(time_duration); end
            metric.logrt.overall.cut2(trial_idx) = temp;
            if metric.full.and < 0.59; temp = nan; else; temp = log(time_duration); end
            metric.logrt.overall.cut3(trial_idx) = temp;
            if metric.full.and < 0.79; temp = nan; else; temp = log(time_duration); end
            metric.logrt.overall.cut4(trial_idx) = temp;

            temp_time = time_point(pos);
            metric.logrt.point.overall(trial_idx) = nanmean(log(temp_time));
            metric.logrt.point.correct(trial_idx) = nanmean(log(temp_time(temp_correct)));
            metric.logrt.point.incorrect(trial_idx) = nanmean(log(temp_time(~temp_correct)));
            metric.logrt.point.n_correct(trial_idx) = sum(temp_correct);
            metric.logrt.point.n_incorrect(trial_idx) = sum(~temp_correct);
    
            temp_time = time_what(pos);
            metric.logrt.what.overall(trial_idx) = nanmean(log(temp_time));
            metric.logrt.what.correct(trial_idx) = nanmean(log(temp_time(temp_correct)));
            metric.logrt.what.incorrect(trial_idx) = nanmean(log(temp_time(~temp_correct)));
            metric.logrt.what.n_correct(trial_idx) = sum(temp_correct);
            metric.logrt.what.n_incorrect(trial_idx) = sum(~temp_correct);
    
            temp_time = time_where(pos);
            metric.logrt.where.overall(trial_idx) = nanmean(log(temp_time));
            metric.logrt.where.correct(trial_idx) = nanmean(log(temp_time(temp_correct)));
            metric.logrt.where.incorrect(trial_idx) = nanmean(log(temp_time(~temp_correct)));
            metric.logrt.where.n_correct(trial_idx) = sum(temp_correct);
            metric.logrt.where.n_incorrect(trial_idx) = sum(~temp_correct);

        catch

            metric.rt.overall.all(trial_idx) = nan;
            metric.rt.overall.cut1(trial_idx) = nan;
            metric.rt.overall.cut2(trial_idx) = nan;
            metric.rt.overall.cut3(trial_idx) = nan;
            metric.rt.overall.cut4(trial_idx) = nan;

            metric.rt.point.overall(trial_idx) = nan;
            metric.rt.point.correct(trial_idx) = nan;
            metric.rt.point.incorrect(trial_idx) = nan;
            metric.rt.point.n_correct(trial_idx) = nan;
            metric.rt.point.n_incorrect(trial_idx) = nan;
    
            metric.rt.what.overall(trial_idx) = nan;
            metric.rt.what.correct(trial_idx) = nan;
            metric.rt.what.incorrect(trial_idx) = nan;
            metric.rt.what.n_correct(trial_idx) = nan;
            metric.rt.what.n_incorrect(trial_idx) = nan;
    
            metric.rt.where.overall(trial_idx) = nan;
            metric.rt.where.correct(trial_idx) = nan;
            metric.rt.where.incorrect(trial_idx) = nan;
            metric.rt.where.n_correct(trial_idx) = nan;
            metric.rt.where.n_incorrect(trial_idx) = nan;
    
            metric.logrt.overall.all(trial_idx) = nan;
            metric.logrt.overall.cut1(trial_idx) = nan;
            metric.logrt.overall.cut2(trial_idx) = nan;
            metric.logrt.overall.cut3(trial_idx) = nan;
            metric.logrt.overall.cut4(trial_idx) = nan;

            metric.logrt.point.overall(trial_idx) = nan;
            metric.logrt.point.correct(trial_idx) = nan;
            metric.logrt.point.incorrect(trial_idx) = nan;
            metric.logrt.point.n_correct(trial_idx) = nan;
            metric.logrt.point.n_incorrect(trial_idx) = nan;
    
            metric.logrt.what.overall(trial_idx) = nan;
            metric.logrt.what.correct(trial_idx) = nan;
            metric.logrt.what.incorrect(trial_idx) = nan;
            metric.logrt.what.n_correct(trial_idx) = nan;
            metric.logrt.what.n_incorrect(trial_idx) = nan;
    
            metric.logrt.where.overall(trial_idx) = nan;
            metric.logrt.where.correct(trial_idx) = nan;
            metric.logrt.where.incorrect(trial_idx) = nan;
            metric.logrt.where.n_correct(trial_idx) = nan;
            metric.logrt.where.n_incorrect(trial_idx) = nan;
            
        end


    end

    metric_indiv_all{sbj_i} = metric;

end

%% combined metric

metric = struct();

% accuracies
metric.full.and = cellfun(@(x) nanmean(x.full.and), metric_indiv_all);
metric.full.sum = cellfun(@(x) nanmean(x.full.sum), metric_indiv_all);
metric.full.or = cellfun(@(x) nanmean(x.full.or), metric_indiv_all);
metric.full.tri = cellfun(@(x) nanmean(x.full.tri), metric_indiv_all);
metric.full.recog = cellfun(@(x) nanmean(x.full.recog), metric_indiv_all);
metric.full.pure = cellfun(@(x) nanmean(x.full.pure), metric_indiv_all);
metric.full.prob = cellfun(@(x) nanmean(x.full.prob), metric_indiv_all);
metric.full.penalty = cellfun(@(x) nanmean(x.full.penalty), metric_indiv_all);

metric.what.recog = cellfun(@(x) nanmean(x.what.recog), metric_indiv_all);
metric.what.when = cellfun(@(x) nanmean(x.what.when), metric_indiv_all);
metric.what.pure = cellfun(@(x) nanmean(x.what.pure), metric_indiv_all);
metric.what.prob = cellfun(@(x) nanmean(x.what.prob), metric_indiv_all);
metric.what.penalty = cellfun(@(x) nanmean(x.what.penalty), metric_indiv_all);

metric.where.recog = cellfun(@(x) nanmean(x.where.recog), metric_indiv_all);
metric.where.when = cellfun(@(x) nanmean(x.where.when), metric_indiv_all);
metric.where.pure = cellfun(@(x) nanmean(x.where.pure), metric_indiv_all);
metric.where.prob = cellfun(@(x) nanmean(x.where.prob), metric_indiv_all);
metric.where.penalty = cellfun(@(x) nanmean(x.where.penalty), metric_indiv_all);

% other measures
metric.what_where = cellfun(@(x) nanmean(x.what_where), metric_indiv_all);
metric.n_incorrect = cellfun(@(x) sum(x.n_incorrect), metric_indiv_all);
metric.diagram = cellfun(@(x) mean(cell2mat(x.diagram')), metric_indiv_all, 'uni', 0);
metric.partial_em = cellfun(@(x) nansum(x.partial_em .* x.n_incorrect) / sum(x.n_incorrect), metric_indiv_all);
metric.where_bias.point = cellfun(@(x) nansum(x.where_bias .* x.n_incorrect) / sum(x.n_incorrect), metric_indiv_all);
metric.where_bias.trial_all = cellfun(@(x) sum(x.where_bias > 0) - sum(x.where_bias < 0), metric_indiv_all);
metric.where_bias.trial = cellfun(@(x) sum(x.where_bias > 0 & x.full.and<0.79) - ...
                                       sum(x.where_bias < 0 & x.full.and<0.79), metric_indiv_all);
metric.where_bias.n_trial = cellfun(@(x) sum(x.full.and<0.79), metric_indiv_all);
metric.where_bias.acc_where = cellfun(@(x) nanmean(x.full.and(x.where_bias > 0 & x.full.and<0.79)), metric_indiv_all);
metric.where_bias.acc_what = cellfun(@(x) nanmean(x.full.and(x.where_bias < 0 & x.full.and<0.79)), metric_indiv_all);
metric.where_bias.acc_diff = metric.where_bias.acc_where - metric.where_bias.acc_what;

% confidence
metric.conf.where.overall = cellfun(@(x) nanmean(x.conf.where.overall), metric_indiv_all);
metric.conf.where.correct = cellfun(@(x) nansum(x.conf.where.correct.* x.conf.where.n_correct) / nansum(x.conf.where.n_correct), metric_indiv_all);
metric.conf.where.incorrect = cellfun(@(x) nansum(x.conf.where.incorrect.* x.conf.where.n_incorrect) / nansum(x.conf.where.n_incorrect), metric_indiv_all);
metric.conf.where.diff = metric.conf.where.correct - metric.conf.where.incorrect;
metric.conf.where.n_correct = cellfun(@(x) nansum(x.conf.where.n_correct), metric_indiv_all);
metric.conf.where.n_incorrect = cellfun(@(x) nansum(x.conf.where.n_incorrect), metric_indiv_all);

metric.conf.what.overall = cellfun(@(x) nanmean(x.conf.what.overall), metric_indiv_all);
metric.conf.what.correct = cellfun(@(x) nansum(x.conf.what.correct.* x.conf.what.n_correct) / nansum(x.conf.what.n_correct), metric_indiv_all);
metric.conf.what.incorrect = cellfun(@(x) nansum(x.conf.what.incorrect.* x.conf.what.n_incorrect) / nansum(x.conf.what.n_incorrect), metric_indiv_all);
metric.conf.what.diff = metric.conf.what.correct - metric.conf.what.incorrect;
metric.conf.what.n_correct = cellfun(@(x) nansum(x.conf.what.n_correct), metric_indiv_all);
metric.conf.what.n_incorrect = cellfun(@(x) nansum(x.conf.what.n_incorrect), metric_indiv_all);

metric.conf.both.overall = cellfun(@(x) nanmean(x.conf.both.overall), metric_indiv_all);
metric.conf.both.correct = cellfun(@(x) nansum(x.conf.both.correct.* x.conf.both.n_correct) / nansum(x.conf.both.n_correct), metric_indiv_all);
metric.conf.both.incorrect = cellfun(@(x) nansum(x.conf.both.incorrect.* x.conf.both.n_incorrect) / nansum(x.conf.both.n_incorrect), metric_indiv_all);
metric.conf.both.diff = metric.conf.both.correct - metric.conf.both.incorrect;
metric.conf.both.n_correct = cellfun(@(x) nansum(x.conf.both.n_correct), metric_indiv_all);
metric.conf.both.n_incorrect = cellfun(@(x) nansum(x.conf.both.n_incorrect), metric_indiv_all);

% RT
metric.rt.overall.all = cellfun(@(x) nanmean(x.rt.overall.all), metric_indiv_all);
metric.rt.overall.cut1 = cellfun(@(x) nanmean(x.rt.overall.cut1), metric_indiv_all);
metric.rt.overall.cut2 = cellfun(@(x) nanmean(x.rt.overall.cut2), metric_indiv_all);
metric.rt.overall.cut3 = cellfun(@(x) nanmean(x.rt.overall.cut3), metric_indiv_all);
metric.rt.overall.cut4 = cellfun(@(x) nanmean(x.rt.overall.cut4), metric_indiv_all);

metric.rt.point.overall = cellfun(@(x) nanmean(x.rt.point.overall), metric_indiv_all);
metric.rt.point.correct = cellfun(@(x) nansum(x.rt.point.correct.* x.rt.point.n_correct) / nansum(x.rt.point.n_correct), metric_indiv_all);
metric.rt.point.incorrect = cellfun(@(x) nansum(x.rt.point.incorrect.* x.rt.point.n_incorrect) / nansum(x.rt.point.n_incorrect), metric_indiv_all);

metric.rt.what.overall = cellfun(@(x) nanmean(x.rt.what.overall), metric_indiv_all);
metric.rt.what.correct = cellfun(@(x) nansum(x.rt.what.correct.* x.rt.what.n_correct) / nansum(x.rt.what.n_correct), metric_indiv_all);
metric.rt.what.incorrect = cellfun(@(x) nansum(x.rt.what.incorrect.* x.rt.what.n_incorrect) / nansum(x.rt.what.n_incorrect), metric_indiv_all);

metric.rt.where.overall = cellfun(@(x) nanmean(x.rt.where.overall), metric_indiv_all);
metric.rt.where.correct = cellfun(@(x) nansum(x.rt.where.correct.* x.rt.where.n_correct) / nansum(x.rt.where.n_correct), metric_indiv_all);
metric.rt.where.incorrect = cellfun(@(x) nansum(x.rt.where.incorrect.* x.rt.where.n_incorrect) / nansum(x.rt.where.n_incorrect), metric_indiv_all);

% log RT
metric.logrt.overall.all = cellfun(@(x) nanmean(x.logrt.overall.all), metric_indiv_all);
metric.logrt.overall.cut1 = cellfun(@(x) nanmean(x.logrt.overall.cut1), metric_indiv_all);
metric.logrt.overall.cut2 = cellfun(@(x) nanmean(x.logrt.overall.cut2), metric_indiv_all);
metric.logrt.overall.cut3 = cellfun(@(x) nanmean(x.logrt.overall.cut3), metric_indiv_all);
metric.logrt.overall.cut4 = cellfun(@(x) nanmean(x.logrt.overall.cut4), metric_indiv_all);

metric.logrt.point.overall = cellfun(@(x) nanmean(x.logrt.point.overall), metric_indiv_all);
metric.logrt.point.correct = cellfun(@(x) nansum(x.logrt.point.correct.* x.logrt.point.n_correct) / nansum(x.logrt.point.n_correct), metric_indiv_all);
metric.logrt.point.incorrect = cellfun(@(x) nansum(x.logrt.point.incorrect.* x.logrt.point.n_incorrect) / nansum(x.logrt.point.n_incorrect), metric_indiv_all);

metric.logrt.what.overall = cellfun(@(x) nanmean(x.logrt.what.overall), metric_indiv_all);
metric.logrt.what.correct = cellfun(@(x) nansum(x.logrt.what.correct.* x.logrt.what.n_correct) / nansum(x.logrt.what.n_correct), metric_indiv_all);
metric.logrt.what.incorrect = cellfun(@(x) nansum(x.logrt.what.incorrect.* x.logrt.what.n_incorrect) / nansum(x.logrt.what.n_incorrect), metric_indiv_all);

metric.logrt.where.overall = cellfun(@(x) nanmean(x.logrt.where.overall), metric_indiv_all);
metric.logrt.where.correct = cellfun(@(x) nansum(x.logrt.where.correct.* x.logrt.where.n_correct) / nansum(x.logrt.where.n_correct), metric_indiv_all);
metric.logrt.where.incorrect = cellfun(@(x) nansum(x.logrt.where.incorrect.* x.logrt.where.n_incorrect) / nansum(x.logrt.where.n_incorrect), metric_indiv_all);


%%

