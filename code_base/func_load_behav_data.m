function [data_all, age, sex, group] = func_load_behav_data(path_name, is_training)

if nargin < 2
    is_training = false;
end


file_list = dir(path_name);
file_list(1:2) = [];
file_list = arrayfun(@(x) fullfile(x.folder, x.name), file_list, uni=0);


data_all = {};
for sbj_i = 1:length(file_list)
    load(fullfile(path_name, sprintf('%03d.mat',sbj_i)));
    data_all{sbj_i} = sbj;
end


if ~is_training && contains(path_name,'training') || contains(path_name,'3t')
    for data_i = 1:length(data_all)
        data_all{data_i}.em = data_all{data_i}.em.sess(1);
    end
end

age = cellfun(@(x) x.age, data_all);
sex = cellfun(@(x) x.sex==1 || x.sex=='M', data_all);

try
    group = cellfun(@(x) x.type, data_all);
catch
    group = [];
end

