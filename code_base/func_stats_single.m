function [] = func_stats_single(metric, str)

if nargin == 1
    str = '[STATS]';
end

fprintf('\n%s',str)
temp = metric;

[~,p,~,stats] = ttest(temp,0); 
d = meanEffectSize(temp,'effect','cohen'); 
d = d.Effect; 
str = sig_str(p);

p_ks = kstest((temp-nanmean(temp))/nanstd(temp)); 

[p2,~,stats2] = signrank(temp,0, 'method','approximate'); 
str2 = sig_str(p2);

fprintf(['\n %.3f ± %.3f\n' ...
         ' %4s param - t(%d) = %.3f, P = %g, d = %.3f, p_ks = %.3f \n' ...
         ' %4s nonparam - z = %.3f, P = %g, r = %.3f \n'], ...
         nanmean(temp), nanstd(temp)/sqrt(sum(~isnan(temp))), ...
         str, stats.df, stats.tstat, p, d, p_ks, ...
         str2, stats2.zval, p2, stats2.zval/sqrt(sum(~isnan(temp))))

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
