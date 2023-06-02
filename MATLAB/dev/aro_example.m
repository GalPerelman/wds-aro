clc
clear all
addpath('ROME_1.0.9', 'RSOME 1.2 release','C:\gurobi1001\win64\matlab')
disp('Solve inventory example with RSOME')

T = 24;
t = [1:1:24];
d0 = 1000 * (1 + 0.5*sin(pi*(t-1)/12));
alpha = [1;1.5;2];
c = alpha * (1 + 0.5*sin(pi*(t-1)/12));
 
P = 567;
Q = 13600;
vmin = 500;
vmax = 2000;
v = 500;
theta = 0.2;

model = rsome;
model.Param.solver = 'mosek';

d = model.random(T);
u = model.ambiguity;
u.suppset((1-theta)*d0' <= d, d <= (1+theta)*d0');
model.with(u);

p = model.decision(3, T);
for t = 1:1:T
    p(:, t).affadapt(d(1:t-1));
end 

model.min(sum(sum(c.*p)));
model.append(0 <= p);
model.append(p <= P);
model.append(sum(p, 2) <= Q);

for t = 1:1:T
    model.append(v + sum(sum(p(:, 1:t))) - sum(d(1:t)) >= vmin);
    model.append(v + sum(sum(p(:, 1:t))) - sum(d(1:t)) <= vmax);
end
model.solve()
fprintf('Optimal objective value: %.4f\n\n', model.get);




