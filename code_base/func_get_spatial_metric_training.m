function [metric, metric_cov] = func_get_spatial_metric_training(data_all, type_acc, type_metric, sess_start, sess_end, target_coin)

if nargin<=3
    sess_start = 1;
    sess_end = 7;
    target_coin = 1:8;
elseif nargin <= 5
    target_coin = 1:8;
end

metric = [];
metric_cov = [];

for sbj_i = 1:length(data_all)
    sbj = data_all{sbj_i};

    % get accuracy for each trial
    sess_sbj = [];
    acc_sbj = [];
    for sess_i = 1:8
        acc_sess = [];
        for trial_i = 1:length(sbj.spatial.sess(sess_i).trials)
            try
                if strcmp(type_acc, 'acc_coin')
                    acc = mean(sbj.spatial.sess(sess_i).trials(trial_i).err_adjust(target_coin));
                elseif strcmp(type_acc, 'acc_resp')
                    acc = mean(sbj.spatial.sess(sess_i).trials(trial_i).err_adjust_resp(target_coin));
                elseif strcmp(type_acc, 'err_coin')
                    acc = mean(sbj.spatial.sess(sess_i).trials(trial_i).err(target_coin));
                elseif strcmp(type_acc, 'err_resp')
                    acc = mean(sbj.spatial.sess(sess_i).trials(trial_i).err_resp(target_coin));
                elseif isnumeric(type_acc)
                    acc = mean(sbj.spatial.sess(sess_i).trials(trial_i).err_adjust(target_coin) > type_acc);
                end
            catch
                acc = nan;
            end
            acc_sess = [acc_sess, acc];
        end
        acc_sbj = [acc_sbj, acc_sess];
        sess_sbj = [sess_sbj, repmat(sess_i, 1,length(acc_sess))];
    end

    % get metric
    flag = sess_sbj>=sess_start & sess_sbj<=sess_end;    
    sess = sess_sbj(flag);
    acc = acc_sbj(flag);        

    metric_cov(sbj_i) = mean(acc(sess==sess_start));
    sess = (sess-sess_start)/(max(sess)-sess_start);

    if strcmp(type_metric, 'slope')
        mdl = polyfit(sess, acc, 1);
        metric(sbj_i) = mdl(1);
    elseif strcmp(type_metric, 'corr')
        metric(sbj_i) = corr(sess(:), acc(:));
    elseif strcmp(type_metric, 'auc')
        sess_temp = unique(sess);
        acc_temp = arrayfun(@(x) mean(acc(sess==x)), sess_temp);
        metric(sbj_i) = mean((acc_temp(1:end-1)+acc_temp(2:end)))/2 - acc_temp(1);
    end

end