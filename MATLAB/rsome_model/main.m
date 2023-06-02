clc
close all
clear all
% addpath('RSOME 1.2 release','C:\gurobi1001\win64\matlab')
addpath('ROME_1.0.9\',...
        'ROME_1.0.9\utilityfuncs\',...
        'C:\Program Files\Mosek\10.0\toolbox\r2017a')

import ROME_1.0.9.*;

data_folder = 'data\pw';
sim = Simulation;
sim = sim.init(data_folder, 1, 24);

[obj, x_fsp, x_vsp, model] = lp(sim);
fprintf('Deterministic Optimal Solution: %.1f\n\n', obj);
vol = sim.get_tank_vol(x_fsp, x_vsp, 1);
plot(vol,'DisplayName','LP');
grid();
hold on

[obj, x_fsp, x_vsp, model] = ro(sim, 2, 1, 0.1);
fprintf('Robust Optimal Solution: %.1f\n\n', obj);
vol = sim.get_tank_vol(x_fsp, x_vsp, 1);
plot(vol,'DisplayName','RO');
grid();
hold on

% ARO returns worst case
[obj, x_fsp, x_vsp, z_val, model, x, z] = aro(sim, 2, 1, 0.1);
fprintf('Adjustable Robust Optimal Solution: %.1f\n\n', obj);
vol = sim.get_tank_vol(x_fsp, x_vsp, 1);
plot(vol,'DisplayName','ARO');
grid();
hold on


[obj_val, x_fsp_ldr, x_vsp_ldr, model, z] = aro_rome(sim, 2, 1, 0.1);
fprintf('Optimal Worst Case ARO: %.1f\n\n', obj_val);
x_val  = squeeze(linearpart(x_fsp_ldr));
xx = utils.extract_ldr_solution(x_fsp_ldr);
cost = sim.get_total_cost(xx);
fprintf('Optimal Nominal ARO: %.1f\n\n', cost);
sz = size(x_fsp_ldr.LDRAffineMap,2) - 1;

% z = zeros(sz,1);
% x = x_fsp_ldr.insert(z);
% x = reshape(x, x_fsp_ldr.Size(1), []);

fprintf('%.3f\n', cost/obj_val);
vol = sim.get_tank_vol(xx, 0, 1);
plot(vol)
grid()

% figure()
% a = [];
% for jj=1:500
%     r = normrnd(0,0.5,sz,1);
%     x = x_fsp_ldr.insert(r);
%     x = reshape(x, x_fsp_ldr.Size(1), []);
%     cost = sim.get_total_cost(x);
% 
%     a=[a;cost];
% end
% histogram(a)


% fprintf('%.2f - %.2f - %.2f %.3f\n', i, obj, obj_val, cost)

% x_sol = x_fsp_ldr.insert(zeros(1,25));
xx = reshape(xx, 4, []);
% tariff = sim.data.tariff';
% power = sim.net.fsp{:, "power"};
% cost = sum(tariff .* power .* x_sol, 'all')
% sim.get_total_cost(x_sol)


