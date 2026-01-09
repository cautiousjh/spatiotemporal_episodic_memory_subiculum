function [] = func_stats_training_order(metric_pre, metric_post, group, sex)

tail = 'right';

metric = cellfun(@(x,y) y-x, metric_pre, metric_post, 'uni', 0);

data_exp = cellfun(@(x) x(group==1), metric, 'uni', 0);
data_ctrl = cellfun(@(x) x(group==0), metric, 'uni', 0);

data_pre_exp = cellfun(@(x) x(group==1), metric_pre, 'uni', 0);
data_pre_ctrl = cellfun(@(x) x(group==0), metric_pre, 'uni', 0);

fprintf('\n\n[STATS]\n');

[~,p] = cellfun(@(x) ttest(x,0,'tail',tail), data_exp); 
fprintf('\nexp  ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']\n')

[~,p] = cellfun(@(x) ttest(x,0,'tail',tail), data_ctrl); 
fprintf('\nctrl  ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']\n')


[~,p] = cellfun(@(x,y) ttest2(x,y), data_exp, data_ctrl); 
fprintf('\ncomparison  ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']\n')

[~,p] = cellfun(@(x,y) ttest2(x,y), data_pre_exp, data_pre_ctrl); 
fprintf('\npre-training comparison  ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']\n')

p = cellfun(@(x) signrank(x,0,'method','approximate', 'tail',tail), data_exp); 
fprintf('\nexp (nonparam) ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']\n')

p = cellfun(@(x) signrank(x,0,'method','approximate', 'tail',tail), data_ctrl); 
fprintf('\nctrl (nonparam) ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']\n')


p = cellfun(@(x,y) ranksum(x,y,'method','approximate'), data_exp, data_ctrl); 
fprintf('\ncomparison (nonparam)  ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']\n')

p = cellfun(@(x,y) ranksum(x,y,'method','approximate'), data_pre_exp, data_pre_ctrl); 
fprintf('\npre-training comparison (nonparam)  ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s ',p(i),sig_str(p(i))); end; fprintf(']\n')


fprintf('\n\n\n ADDITIONAL FOR COPY ');
p = cellfun(@(x) signrank(x,0,'method','approximate', 'tail',tail), data_exp); 
fprintf('\nexp (nonparam) ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s\t',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s\t',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s\t',p(i),sig_str(p(i))); end; fprintf(']\n')
p = cellfun(@(x) signrank(x,0,'method','approximate', 'tail',tail), data_ctrl); 
fprintf('\nctrl (nonparam) ');
fprintf('\n     p = [ '); for i = 1:5; fprintf('%.3f%-3s\t',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\np_corr = [ '); p=p*5; for i = 1:5; fprintf('%.3f%-3s\t',p(i),sig_str(p(i))); end; fprintf(']')
fprintf('\n p_fdr = [ '); [~,~,~,p] = fdr_bh(p/5); for i = 1:5; fprintf('%.3f%-3s\t',p(i),sig_str(p(i))); end; fprintf(']\n')


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
