clc
clear all
close all

addpath('ROME_1.0.9\',...
        'ROME_1.0.9\utilityfuncs\',...
        'C:\Program Files\Mosek\10.0\toolbox\r2017a')

import ROME_1.0.9.*;
disp('Solve inventory example with ROME')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rome_begin;
model = rome_model();
model.Solver = 'MOSEK';

v0 = 1000;
d0 = [131, 127, 128, 137, 188, 216, 242, 245, 213, 217, 237, 202, 212,...
      200, 185, 196, 212, 237, 283, 290, 236, 190, 185, 155]';

c = [1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1]';

z = newvar(24, 'uncertain'); 
rome_constraint(norm2(z) <= 1);
% rome_box(z, -0.1, 0.1);

d = d0 .* (1 + 0.1*z);
x = rome_empty_var(24);
for t = 1:24
    x(t) = rome_linearrule(z(1:t-1));
end

rome_constraint(x <= 300);
rome_constraint(0 <= x);

mat=tril(ones(24, 24));
rome_constraint(v0 + mat * x - mat * d <= 3000);
rome_constraint(v0 + mat * x - mat * d >= 500);
rome_constraint(v0 + sum(x) - sum(d) >= v0);
rome_minimize(c' * x)

model.solve;
obj = model.objective;
x_sol = model.eval(x);

sz = size(x_sol.LDRAffineMap,2) - 1;
z_sample = zeros(sz,1);
xx = x_sol.insert(z_sample);
xx = reshape(xx, x_sol.Size(1), []);

fprintf('%.1f | %.1f | %.4f\n', obj, c' * xx, c' * xx/obj);
vol = v0 + mat * xx - mat * d0;
plot(vol);
grid();


