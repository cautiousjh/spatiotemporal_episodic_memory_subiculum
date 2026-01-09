function [] = func_stats_compare(metric1, metric2)

fprintf('\n\n[STATS]')
temp1 = metric1; temp2 = metric2;
[~,p,~,stats] = ttest2(temp1,temp2); d = meanEffectSize(temp1, temp2, 'effect','cohen'); d = d.Effect; str = sig_str(p);
[p2,~,stats2] = ranksum(temp1, temp2, 'method','approximate'); str2 = sig_str(p2);
fprintf(['\n\n compare: \n' ...
         ' %4s param - t(%d) = %.3f, p = %.3f, d = %.3f\n' ...
         ' %4s nonparam - z = %.3f, p = %.3f, r = %.3f  \n'],  ...
         str, stats.df, stats.tstat, p, d, ...
         str2, stats2.zval, p2, stats2.zval/sqrt(sum(~isnan(temp1))+sum(~isnan(temp2))))

function str = sig_str(p)
if p<0.001
    str = '***';
elseif p<0.01
    str = '**';
elseif p<0.05
    str = '*';
elseif p<0.1
    str = '+';
else
    str = '';
end
