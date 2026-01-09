function metric_all = func_get_spatial_metric_sess_wise(data_all, type_acc, target_coin)

if nargin < 3
    target_coin = 1:8;
end

metric_all = {};

for sbj_i = 1:length(data_all)
    sbj = data_all{sbj_i};

    acc = [];
    for sess_i = 1:8
        try
            if strcmp(type_acc, 'acc_coin')
                acc = mean(arrayfun(@(x) mean(x.err_adjust(target_coin)), sbj.spatial.sess(sess_i).trials));
            elseif strcmp(type_acc, 'acc_resp')
                acc = mean(arrayfun(@(x) mean(x.err_adjust_resp(target_coin)), sbj.spatial.sess(sess_i).trials));
            elseif strcmp(type_acc, 'err_coin')
                acc = mean(arrayfun(@(x) mean(x.err(target_coin)), sbj.spatial.sess(sess_i).trials));
            elseif strcmp(type_acc, 'err_resp')
                acc = mean(arrayfun(@(x) mean(x.err_resp(target_coin)), sbj.spatial.sess(sess_i).trials));
            elseif isnumeric(type_acc)
                acc = mean(arrayfun(@(x) mean(x.err_adjust(target_coin)>type_acc), ...
                           sbj.spatial.sess(sess_i).trials));
%                 acc = mean(arrayfun(@(x) sum(x.err_adjust>type_acc(2)) / sum(x.err_adjust>type_acc(1)), ...
%                            sbj.spatial.sess(sess_i).trials));
            end
        catch
            acc = nan;
        end
        metric_all{sess_i}(sbj_i) = acc;
    end    

end