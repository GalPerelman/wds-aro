clc
clear all
addpath('ROME_1.0.9\',...
        'ROME_1.0.9\utilityfuncs\',...
        'C:\Program Files\Mosek\10.0\toolbox\r2017a')

import ROME_1.0.9.*;

rome_begin;
model = rome_model();
model.Solver = 'MOSEK';

n = 150;
i = 1:1:n;
p = 1.15 + i*0.05/150;
delta = (0.05/450) * sqrt(2*i*n*(n+1));   
Gamma = 5;                               

x = newvar(n);
z = newvar(n, 'uncertain');                       

% rome_box(z, -1, 1);
rome_constraint(norm1(z) <= Gamma);

rome_maximize((p + delta.*z') * x);

rome_constraint(sum(x) == 1);
rome_constraint(x >= 0);
model.solve();

fprintf('Optimal objective value: %.5f\n\n', model.ObjVal);
obj = model.objective;
xx   = model.eval(x);
