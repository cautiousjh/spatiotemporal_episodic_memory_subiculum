function [] = func_stats_multiple(metric, is_fdr)

if nargin < 2
    is_fdr = false;
end

if ~iscell(metric)
    metric = {metric};
end
n_data = numel(metric);

p      = nan(1, n_data);
p2     = nan(1, n_data);
d      = nan(1, n_data);
p_ks   = nan(1, n_data);
stats_all  = cell(1, n_data);
stats2_all = cell(1, n_data);

for data_i = 1:n_data
    temp = metric{data_i};

    [~, p(data_i), ~, stats_all{data_i}] = ttest(temp, 0);
    d_struct = meanEffectSize(temp, 'effect', 'cohen');
    d(data_i) = d_struct.Effect;

    z_temp = (temp - nanmean(temp)) ./ nanstd(temp);
    p_ks(data_i) = kstest(z_temp);

    [p2(data_i), ~, stats2_all{data_i}] = signrank(temp, 0, 'method', 'approximate');
end

p_used  = p;
p2_used = p2;

if is_fdr
    [~, ~, ~, p_fdr]  = fdr_bh(p);
    [~, ~, ~, p2_fdr] = fdr_bh(p2);
    p_used  = p_fdr;
    p2_used = p2_fdr;
end

for data_i = 1:n_data
    temp   = metric{data_i};
    stats  = stats_all{data_i};
    stats2 = stats2_all{data_i};

    str_sig_param = sig_str(p_used(data_i));
    str_sig_non   = sig_str(p2_used(data_i));

    fprintf('\n%d',data_i)
    fprintf(['\n %.3f ± %.3f\n' , ...
             ' %4s param - t(%d) = %.3f, P = %g, d = %.3f, p_ks = %.3f \n' , ...
             ' %4s nonparam - z = %.3f, P = %g, r = %.3f \n'], ...
            nanmean(temp), ...
            nanstd(temp) / sqrt(sum(~isnan(temp))), ...
            str_sig_param, stats.df, stats.tstat, p_used(data_i), d(data_i), p_ks(data_i), ...
            str_sig_non,   stats2.zval, p2_used(data_i), ...
            stats2.zval / sqrt(sum(~isnan(temp))));
end

end

function str = sig_str(p)
if p < 0.001
    str = '***';
elseif p < 0.01
    str = '**';
elseif p < 0.05
    str = '*';
elseif p < 0.1
    str = '+';
else
    str = '';
end
end
