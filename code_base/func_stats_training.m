function [] = func_stats_training(metric1, metric2, group, sex)

metric = metric2 - metric1;
metric = round(metric,10);

fprintf('\n\n[STATS]\n')
temp = metric(group==1);
[~,p,~,stats] = ttest(temp,0); d = meanEffectSize(temp,'effect','cohen'); d = d.Effect; str = sig_str(p);
p_ks = kstest((temp-nanmean(temp))/nanstd(temp)); [p2,~,stats2] = signrank(temp,0, 'method','approximate'); str2 = sig_str(p2);
fprintf(['\ntraining exp: %.3f ± %.3f\n' ...
         ' %4s param - t(%d) = %.3f, P = %.3f, d = %.3f, p_ks = %.3f \n' ...
         ' %4s nonparam - z = %.3f, P = %.3f, r = %.3f \n'], mean(temp), std(temp)/sqrt(sum(~isnan(temp))), ...
         str, stats.df, p, stats.tstat, d, p_ks, ...
         str2, stats2.zval, p2, stats2.zval/sqrt(sum(~isnan(temp))))


temp = metric(group==0);
[~,p,~,stats] = ttest(temp,0); d = meanEffectSize(temp,'effect','cohen'); d = d.Effect; str = sig_str(p);
p_ks = kstest((temp-nanmean(temp))/nanstd(temp)); [p2,~,stats2] = signrank(temp,0, 'method','approximate'); str2 = sig_str(p2);
fprintf(['\ntraining ctrl: %.3f ± %.3f\n' ...
         ' %4s param - t(%d) = %.3f, P = %.3f, d = %.3f, p_ks = %.3f \n' ...
         ' %4s nonparam - z = %.3f, P = %.3f, r = %.3f \n'], mean(temp), std(temp)/sqrt(sum(~isnan(temp))), ...
         str, stats.df, p, stats.tstat, d, p_ks, ...
         str2, stats2.zval, p2, stats2.zval/sqrt(sum(~isnan(temp))))

temp1 = metric(group==0); temp2 = metric(group==1);
[~,p,~,stats] = ttest2(temp1,temp2); d = meanEffectSize(temp1, temp2, 'effect','cohen'); d = d.Effect; str = sig_str(p);
[p2,~,stats2] = ranksum(temp1, temp2, 'method','approximate'); str2 = sig_str(p2);
fprintf(['\ntraining comparison: \n' ...
         ' %4s param - t(%d) = %.3f, P = %.3f, d = %.3f\n' ...
         ' %4s nonparam - z = %.3f, P = %.3f, r = %.3f  \n'],  ...
         str, stats.df, stats.tstat, p, d, ...
         str2, stats2.zval, p2, stats2.zval/sqrt(sum(~isnan(temp1))+sum(~isnan(temp2))))


temp1 = metric1(group==0); temp2 = metric1(group==1);
[~,p,~,stats] = ttest2(temp1,temp2); d = meanEffectSize(temp1, temp2, 'effect','cohen'); d = d.Effect; str = sig_str(p);
[p2,~,stats2] = ranksum(temp1, temp2, 'method','approximate'); str2 = sig_str(p2);
fprintf(['\n\n sess1 diff: \n' ...
         ' %4s param - t(%d) = %.3f, P = %.3f, d = %.3f\n' ...
         ' %4s nonparam - z = %.3f, P = %.3f, r = %.3f  \n'],  ...
         str, stats.df, stats.tstat, p, d, ...
         str2, stats2.zval, p2, stats2.zval/sqrt(sum(~isnan(temp1))+sum(~isnan(temp2))))

temp1 = metric1(~isnan(group)&sex==1); temp2 = metric1(~isnan(group)&sex==0);
[~,p,~,stats] = ttest2(temp1,temp2); d = meanEffectSize(temp1, temp2, 'effect','cohen'); d = d.Effect; str = sig_str(p);
[p2,~,stats2] = ranksum(temp1, temp2, 'method','approximate'); str2 = sig_str(p2);
fprintf(['\n sess1 sex diff: \n' ...
         ' %4s param - t(%d) = %.3f, P = %.3f, d = %.3f\n' ...
         ' %4s nonparam - z = %.3f, P = %.3f, r = %.3f  \n'],  ...
         str, stats.df, stats.tstat, p, d, ...
         str2, stats2.zval, p2, stats2.zval/sqrt(sum(~isnan(temp1))+sum(~isnan(temp2))))


flag = ~isnan(group);
var = {metric1(flag), metric2(flag)}; var_name = {'pre','post'};
cov = {group(flag), sex(flag)}; cov_name = {'group','sex'};
[tbl,str,p,F,df,sumSq] = jh_rmanova(var, cov, [], var_name, cov_name, 'pre-post~group+sex'); fprintf(str)
[tbl,str,p,F,df,sumSq] = jh_rmanova(var, cov, [], var_name, cov_name, 'pre-post~group*sex'); fprintf(str)
cov = {group(flag)}; cov_name = {'group'};
[tbl,str,p,F,df,sumSq] = jh_rmanova(var, cov, [], var_name, cov_name, 'pre-post~group'); fprintf(str)

% [p,tbl,stats] = friedman([metric_sess1(group==1)', metric_sess8(group==1)' ])
% [p,tbl,stats] = friedman([metric_sess1(group==0)', metric_sess8(group==0)' ])

function str = sig_str(p)
if p<0.005
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
