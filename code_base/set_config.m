function [] = set_config()

config = struct();

config.base_3t = 'D:\SynologyDrive\0_research\_em_navigation_training'; % need to be modified
config.base_7t = 'G:\7T_EM_SPATIAL_NEW'; % need to be modified

config.behav_3t = '../data_behavior/training';
config.behav_7t = '../data_behavior/7t';
config.behav_us = '../data_behavior/behavior';

% color
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.color_em = [242, 112, 110] / 255;    % oklch(0.7,0.16,23)
config.color_where = [62, 186, 104] / 255; 
config.color_what = [134, 178, 224] / 255; % other

config.color_nav = [101, 181, 78] / 255; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

config.color_em2 = jh_color_modify(config.color_em, 'saturation',0.1);
config.color_where2 = jh_color_modify(config.color_where, 'saturation',0.1);
config.color_what2 = jh_color_modify(config.color_what, 'saturation',0.1);


config.color_ca23dg = [0.90, 0.67, 0.01];
config.color_ca1 = [0.46, 0.44, 0.70];
config.color_sub = config.color_em;

% visualization
config.edge_color = [.2 .2 .2];
config.line_width = .5;
config.font_size = 5.5;

config.err_line_width= 1.2;
config.err_cap_size = 2;
config.err_marker_size = 2.9;

config.regress_line_width = 1.2;
config.regress_marker_size = 3;

config.hist_line_width = .1;

config.fig_size = [3.8 3.5] * 0.9;

% functions
aux_func_get_residual = @(mdl) mdl.Residuals.Raw;
func_get_residual = @(x,y) aux_func_get_residual(fitlm(x(:),y(:)));

% load
assignin('base', 'config', config)
assignin('base', 'aux_func_get_residual', aux_func_get_residual)
assignin('base', 'func_get_residual', func_get_residual);

