function func_load_data(dir_behav, exp_type, sess_i, data_dir_base)

% load sbj list
sbj_list = dir(dir_behav);
sbj_list = arrayfun(@(x) split(x.name,'.'), sbj_list(3:end), uni=0);
sbj_list = cellfun(@(x) x{1}, sbj_list, uni=0);

num = cellfun(@(x) str2double(regexp(x, '\d+', 'match', 'once')), sbj_list);
[~, idx] = sort(num);
sbj_list = sbj_list(idx);


% load data
data_all={};
for sbj_i = 1:length(sbj_list)
    load(fullfile(dir_behav, sprintf('%s.mat',sbj_list{sbj_i}))); 

    if strcmp(exp_type,'3t') && sess_i ~=0 % for single session analysis
        sbj.em = sbj.em.sess(sess_i);
        sbj.word = sbj.word.sess(sess_i);
        sbj.spatial = sbj.spatial.sess(end);
    end

    data_all{sbj_i} = sbj;
end

% exception
if strcmp(exp_type,'3t') && sess_i ==0
    valid_behav_sbj = ~cellfun(@(x) isempty(x.em.sess(1).valid_trial), data_all) & ...
                      ~cellfun(@(x) isempty(x.em.sess(2).valid_trial), data_all);

    valid_fmri_sbj = ~cellfun(@(x) isempty(x.em.sess(1).valid_fmri_trial), data_all) & ...
                      ~cellfun(@(x) isempty(x.em.sess(2).valid_fmri_trial), data_all);
else
    valid_behav_sbj = ~cellfun(@(x) isempty(x.em.valid_trial), data_all);
    valid_fmri_sbj = ~cellfun(@(x) isempty(x.em.valid_fmri_trial), data_all);
end

% exception handling
assignin('base', 'sbj_list', sbj_list)
assignin('base', 'data_all', data_all)
assignin('base', 'valid_behav_sbj', valid_behav_sbj)
assignin('base', 'valid_fmri_sbj', valid_fmri_sbj)

%%
aux_func_get_residual = @(mdl) mdl.Residuals.Raw;
func_get_residual = @(x,y) aux_func_get_residual(fitlm(x(:),y(:)));
func_get_residual_analytic = @(cov,data) data - [ones(size(data,1),1), cov] * ([ones(size(data,1),1), cov]\data);

assignin('base', 'aux_func_get_residual', aux_func_get_residual)
assignin('base', 'func_get_residual', func_get_residual)
assignin('base', 'func_get_residual_analytic', func_get_residual_analytic)


    