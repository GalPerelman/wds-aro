clc
clear all
close all

addpath('ROME_1.0.9\',...
        'ROME_1.0.9\utilityfuncs\',...
        'C:\Program Files\Mosek\10.0\toolbox\r2017a')

import ROME_1.0.9.*;
disp('Solve inventory example with ROME')
T = 24;
t = [1:1:24];
d0 = 1000 * (1 + 0.5*sin(pi*(t-1)/12))';
alpha = [1;1.5;2];
c = alpha * (1 + 0.5*sin(pi*(t-1)/12));

P = 567;
Q = 13600;
vmin = 500;
vmax = 2000;
v = 500;
theta = 0.20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rome_begin;
model = rome_model();
model.Solver = 'MOSEK';

d = newvar(T,1, 'uncertain');
rome_box(d, (1-theta)*d0, (1+theta)*d0);

p = rome_empty_var(3, T);
% p = [];
for t = 1:T
    for j = 1:3
        p(j, t) = rome_linearrule(d(1:t-1));
    end
end
% p = newvar(3, T);
% p_pattern = [true(T, 3), tril(true(T))];
% newvar p(3, T, d, 'Pattern', p_pattern) linearrule;

rome_minimize(sum(sum(c.*p)));
rome_constraint(0 <= p);
rome_constraint(p <= P);
rome_constraint(sum(p, 2) <= Q);

for t = 1:T
    rome_constraint(v + sum(sum(p(:, 1:t))) - sum(d(1:t,:)) >= vmin);
    rome_constraint(v + sum(sum(p(:, 1:t))) - sum(d(1:t,:)) <= vmax);
end

model.solve;
fprintf('Optimal objective value: %.4f\n', model.ObjVal);

x_sol = model.eval(p); % Get the solution object
xx = x_sol.insert(d0);
xx = reshape(xx, 3, []);
cost = sum(c .* xx, 'all');
% cost = sum(c(1, :)'.*xx(1:24) + c(2, :)'.*xx(25:48) + c(3, :)'.*xx(49:72));
fprintf('Optimal objective value: %.4f\n', cost);
rome_end
% c =  reshape(c',1,[]);
% c(:)'*xx;
fprintf('total demand: %.1f\n', sum(d0, 'all'));
fprintf('total production: %.1f\n', sum(xx, 'all'));


prod = sum(xx, 1)';
storage = v + cumsum(prod) - cumsum(d0);
plot(storage)
grid()
