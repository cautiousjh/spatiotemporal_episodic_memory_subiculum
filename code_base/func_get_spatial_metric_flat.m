function metric_all = func_get_spatial_metric_flat(data_all, type_acc)

metric_all = [];

for sbj_i = 1:length(data_all)
    sbj = data_all{sbj_i};

    for sess_i = 1:7
        try
            if strcmp(type_acc, 'acc_coin')
                acc = cell2mat(arrayfun(@(x) x.err_adjust, sbj.spatial.sess(sess_i).trials, 'uni',0));
            elseif strcmp(type_acc, 'acc_resp')
                acc = cell2mat(arrayfun(@(x) x.err_adjust_resp, sbj.spatial.sess(sess_i).trials, 'uni',0));
                acc = mean(arrayfun(@(x) mean(x.err_adjust_resp), sbj.spatial.sess(sess_i).trials));
            elseif strcmp(type_acc, 'err_coin')
                acc = cell2mat(arrayfun(@(x) x.err, sbj.spatial.sess(sess_i).trials, 'uni',0));
            elseif strcmp(type_acc, 'err_resp')
                acc = cell2mat(arrayfun(@(x) x.err_resp, sbj.spatial.sess(sess_i).trials, 'uni',0));
            end
        catch
            acc = [];
        end
        metric_all = [metric_all,acc];
    end    

end