clc
clear all
close all

addpath('ROME_1.0.9\',...
        'ROME_1.0.9\utilityfuncs\',...
        'C:\Program Files\Mosek\10.0\toolbox\r2017a')

import ROME_1.0.9.*;


N = 30;
c = 20;
dmax = 20;
Gamma = 20*sqrt(N);
xy = 10*rand(2, N);
t = ((xy(1, :) - xy(1, :)') .^ 2 + (xy(2, :) - xy(2, :)') .^ 2) .^ 0.5;

rome_begin;
model = rome_model();
model.Solver = 'MOSEK';

d = newvar(N, 'uncertain');
rome_box(d, 0, dmax);
rome_constraint(norm1(d) <= Gamma);

x = newvar(N);
y = newvar(N, N, d, 'linearrule');

rome_minimize(sum(c.*x) + sum(sum((t*y))));
rome_constraint(d <= sum(y, 1)' - sum(y, 2) + x);
rome_constraint(y >= 0);
rome_constraint(x >= 0);
rome_constraint(x <= 20);
model.solve;

fprintf('Optimal objective value: %.4f\n', model.ObjVal);


