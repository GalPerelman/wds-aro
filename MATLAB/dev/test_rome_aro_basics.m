clc
clear all
close all

addpath('ROME_1.0.9\', 'ROME_1.0.9\utilityfuncs\', 'C:\Program Files\Mosek\10.0\toolbox\r2017a')
import ROME_1.0.9.*;
disp('Solve inventory example with ROME')
T = 24;
t = 1:1:24;
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

p1_1 = newvar(1);
p1_2 = rome_linearrule(1, d(1));
p1_3 = rome_linearrule(1, d(1:2));
p1_4 = rome_linearrule(1, d(1:3));
p1_5 = rome_linearrule(1, d(1:4));
p1_6 = rome_linearrule(1, d(1:5));
p1_7 = rome_linearrule(1, d(1:6));
p1_8 = rome_linearrule(1, d(1:7));
p1_9 = rome_linearrule(1, d(1:8));
p1_10 = rome_linearrule(1, d(1:9));
p1_11 = rome_linearrule(1, d(1:10));
p1_12 = rome_linearrule(1, d(1:11));
p1_13 = rome_linearrule(1, d(1:12));
p1_14 = rome_linearrule(1, d(1:13));
p1_15 = rome_linearrule(1, d(1:14));
p1_16 = rome_linearrule(1, d(1:15));
p1_17 = rome_linearrule(1, d(1:16));
p1_18 = rome_linearrule(1, d(1:17));
p1_19 = rome_linearrule(1, d(1:18));
p1_20 = rome_linearrule(1, d(1:19));
p1_21 = rome_linearrule(1, d(1:20));
p1_22 = rome_linearrule(1, d(1:21));
p1_23 = rome_linearrule(1, d(1:22));
p1_24 = rome_linearrule(1, d(1:23));

p2_1 = newvar(1);
p2_2 = rome_linearrule(1, d(1));
p2_3 = rome_linearrule(1, d(1:2));
p2_4 = rome_linearrule(1, d(1:3));
p2_5 = rome_linearrule(1, d(1:4));
p2_6 = rome_linearrule(1, d(1:5));
p2_7 = rome_linearrule(1, d(1:6));
p2_8 = rome_linearrule(1, d(1:7));
p2_9 = rome_linearrule(1, d(1:8));
p2_10 = rome_linearrule(1, d(1:9));
p2_11 = rome_linearrule(1, d(1:10));
p2_12 = rome_linearrule(1, d(1:11));
p2_13 = rome_linearrule(1, d(1:12));
p2_14 = rome_linearrule(1, d(1:13));
p2_15 = rome_linearrule(1, d(1:14));
p2_16 = rome_linearrule(1, d(1:15));
p2_17 = rome_linearrule(1, d(1:16));
p2_18 = rome_linearrule(1, d(1:17));
p2_19 = rome_linearrule(1, d(1:18));
p2_20 = rome_linearrule(1, d(1:19));
p2_21 = rome_linearrule(1, d(1:20));
p2_22 = rome_linearrule(1, d(1:21));
p2_23 = rome_linearrule(1, d(1:22));
p2_24 = rome_linearrule(1, d(1:23));

p3_1 = newvar(1);
p3_2 = rome_linearrule(1, d(1));
p3_3 = rome_linearrule(1, d(1:2));
p3_4 = rome_linearrule(1, d(1:3));
p3_5 = rome_linearrule(1, d(1:4));
p3_6 = rome_linearrule(1, d(1:5));
p3_7 = rome_linearrule(1, d(1:6));
p3_8 = rome_linearrule(1, d(1:7));
p3_9 = rome_linearrule(1, d(1:8));
p3_10 = rome_linearrule(1, d(1:9));
p3_11 = rome_linearrule(1, d(1:10));
p3_12 = rome_linearrule(1, d(1:11));
p3_13 = rome_linearrule(1, d(1:12));
p3_14 = rome_linearrule(1, d(1:13));
p3_15 = rome_linearrule(1, d(1:14));
p3_16 = rome_linearrule(1, d(1:15));
p3_17 = rome_linearrule(1, d(1:16));
p3_18 = rome_linearrule(1, d(1:17));
p3_19 = rome_linearrule(1, d(1:18));
p3_20 = rome_linearrule(1, d(1:19));
p3_21 = rome_linearrule(1, d(1:20));
p3_22 = rome_linearrule(1, d(1:21));
p3_23 = rome_linearrule(1, d(1:22));
p3_24 = rome_linearrule(1, d(1:23));

rome_minimize(c(1,1)*p1_1 + c(1,2)*p1_2 + c(1,3)*p1_3 + c(1,4)*p1_4 + c(1,5)*p1_5 + c(1,6)*p1_6...
            + c(1,7)*p1_7 + c(1,8)*p1_8 + c(1,9)*p1_9 + c(1,10)*p1_10 + c(1,11)*p1_11 + c(1,12)*p1_12...
            + c(1,13)*p1_13 + c(1,14)*p1_14 + c(1,15)*p1_15 + c(1,16)*p1_16 + c(1,17)*p1_17 + c(1,18)*p1_18...
            + c(1,19)*p1_19 + c(1,20)*p1_20 + c(1,21)*p1_21 + c(1,22)*p1_22 + c(1,23)*p1_23 + c(1,24)*p1_24...
            ...
            + c(2,1)*p2_1 + c(2,2)*p2_2 + c(2,3)*p2_3 + c(2,4)*p2_4 + c(2,5)*p2_5 + c(2,6)*p2_6...
            + c(2,7)*p2_7 + c(2,8)*p2_8 + c(2,9)*p2_9 + c(2,10)*p2_10 + c(2,11)*p2_11 + c(2,12)*p2_12...
            + c(2,13)*p2_13 + c(2,14)*p2_14 + c(2,15)*p2_15 + c(2,16)*p2_16 + c(2,17)*p2_17 + c(2,18)*p2_18...
            + c(2,19)*p2_19 + c(2,20)*p2_20 + c(2,21)*p2_21 + c(2,22)*p2_22 + c(2,23)*p2_23 + c(2,24)*p2_24...
            ...
            + c(3,1)*p3_1 + c(3,2)*p3_2 + c(3,3)*p3_3 + c(3,4)*p3_4 + c(3,5)*p3_5 + c(3,6)*p3_6...
            + c(3,7)*p3_7 + c(3,8)*p3_8 + c(3,9)*p3_9 + c(3,10)*p3_10 + c(3,11)*p3_11 + c(3,12)*p3_12...
            + c(3,13)*p3_13 + c(3,14)*p3_14 + c(3,15)*p3_15 + c(3,16)*p3_16 + c(3,17)*p3_17 + c(3,18)*p3_18...
            + c(3,19)*p3_19 + c(3,20)*p3_20 + c(3,21)*p3_21 + c(3,22)*p3_22 + c(3,23)*p3_23 + c(3,24)*p3_24);

rome_constraint(0 <= p1_1);
rome_constraint(0 <= p1_2);
rome_constraint(0 <= p1_3);
rome_constraint(0 <= p1_4);
rome_constraint(0 <= p1_5);
rome_constraint(0 <= p1_6);
rome_constraint(0 <= p1_7);
rome_constraint(0 <= p1_8);
rome_constraint(0 <= p1_9);
rome_constraint(0 <= p1_10);
rome_constraint(0 <= p1_11);
rome_constraint(0 <= p1_12);
rome_constraint(0 <= p1_13);
rome_constraint(0 <= p1_14);
rome_constraint(0 <= p1_15);
rome_constraint(0 <= p1_16);
rome_constraint(0 <= p1_17);
rome_constraint(0 <= p1_18);
rome_constraint(0 <= p1_19);
rome_constraint(0 <= p1_20);
rome_constraint(0 <= p1_21);
rome_constraint(0 <= p1_22);
rome_constraint(0 <= p1_23);
rome_constraint(0 <= p1_24);

rome_constraint(0 <= p2_1);
rome_constraint(0 <= p2_2);
rome_constraint(0 <= p2_3);
rome_constraint(0 <= p2_4);
rome_constraint(0 <= p2_5);
rome_constraint(0 <= p2_6);
rome_constraint(0 <= p2_7);
rome_constraint(0 <= p2_8);
rome_constraint(0 <= p2_9);
rome_constraint(0 <= p2_10);
rome_constraint(0 <= p2_11);
rome_constraint(0 <= p2_12);
rome_constraint(0 <= p2_13);
rome_constraint(0 <= p2_14);
rome_constraint(0 <= p2_15);
rome_constraint(0 <= p2_16);
rome_constraint(0 <= p2_17);
rome_constraint(0 <= p2_18);
rome_constraint(0 <= p2_19);
rome_constraint(0 <= p2_20);
rome_constraint(0 <= p2_21);
rome_constraint(0 <= p2_22);
rome_constraint(0 <= p2_23);
rome_constraint(0 <= p2_24);

rome_constraint(0 <= p3_1);
rome_constraint(0 <= p3_2);
rome_constraint(0 <= p3_3);
rome_constraint(0 <= p3_4);
rome_constraint(0 <= p3_5);
rome_constraint(0 <= p3_6);
rome_constraint(0 <= p3_7);
rome_constraint(0 <= p3_8);
rome_constraint(0 <= p3_9);
rome_constraint(0 <= p3_10);
rome_constraint(0 <= p3_11);
rome_constraint(0 <= p3_12);
rome_constraint(0 <= p3_13);
rome_constraint(0 <= p3_14);
rome_constraint(0 <= p3_15);
rome_constraint(0 <= p3_16);
rome_constraint(0 <= p3_17);
rome_constraint(0 <= p3_18);
rome_constraint(0 <= p3_19);
rome_constraint(0 <= p3_20);
rome_constraint(0 <= p3_21);
rome_constraint(0 <= p3_22);
rome_constraint(0 <= p3_23);
rome_constraint(0 <= p3_24);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rome_constraint(p1_1 <= P);
rome_constraint(p1_2 <= P);
rome_constraint(p1_3 <= P);
rome_constraint(p1_4 <= P);
rome_constraint(p1_5 <= P);
rome_constraint(p1_6 <= P);
rome_constraint(p1_7 <= P);
rome_constraint(p1_8 <= P);
rome_constraint(p1_9 <= P);
rome_constraint(p1_10 <= P);
rome_constraint(p1_11 <= P);
rome_constraint(p1_12 <= P);
rome_constraint(p1_13 <= P);
rome_constraint(p1_14 <= P);
rome_constraint(p1_15 <= P);
rome_constraint(p1_16 <= P);
rome_constraint(p1_17 <= P);
rome_constraint(p1_18 <= P);
rome_constraint(p1_19 <= P);
rome_constraint(p1_20 <= P);
rome_constraint(p1_21 <= P);
rome_constraint(p1_22 <= P);
rome_constraint(p1_23 <= P);
rome_constraint(p1_24 <= P);

rome_constraint(p2_1 <= P);
rome_constraint(p2_2 <= P);
rome_constraint(p2_3 <= P);
rome_constraint(p2_4 <= P);
rome_constraint(p2_5 <= P);
rome_constraint(p2_6 <= P);
rome_constraint(p2_7 <= P);
rome_constraint(p2_8 <= P);
rome_constraint(p2_9 <= P);
rome_constraint(p2_10 <= P);
rome_constraint(p2_11 <= P);
rome_constraint(p2_12 <= P);
rome_constraint(p2_13 <= P);
rome_constraint(p2_14 <= P);
rome_constraint(p2_15 <= P);
rome_constraint(p2_16 <= P);
rome_constraint(p2_17 <= P);
rome_constraint(p2_18 <= P);
rome_constraint(p2_19 <= P);
rome_constraint(p2_20 <= P);
rome_constraint(p2_21 <= P);
rome_constraint(p2_22 <= P);
rome_constraint(p2_23 <= P);
rome_constraint(p2_24 <= P);

rome_constraint(p3_1 <= P);
rome_constraint(p3_2 <= P);
rome_constraint(p3_3 <= P);
rome_constraint(p3_4 <= P);
rome_constraint(p3_5 <= P);
rome_constraint(p3_6 <= P);
rome_constraint(p3_7 <= P);
rome_constraint(p3_8 <= P);
rome_constraint(p3_9 <= P);
rome_constraint(p3_10 <= P);
rome_constraint(p3_11 <= P);
rome_constraint(p3_12 <= P);
rome_constraint(p3_13 <= P);
rome_constraint(p3_14 <= P);
rome_constraint(p3_15 <= P);
rome_constraint(p3_16 <= P);
rome_constraint(p3_17 <= P);
rome_constraint(p3_18 <= P);
rome_constraint(p3_19 <= P);
rome_constraint(p3_20 <= P);
rome_constraint(p3_21 <= P);
rome_constraint(p3_22 <= P);
rome_constraint(p3_23 <= P);
rome_constraint(p3_24 <= P);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rome_constraint(p1_1 + p1_2 + p1_3 + p1_4 + p1_5 + p1_6 + p1_7 + p1_8 + p1_9 + p1_10 + p1_11 + p1_12...
              + p1_13 + p1_14 + p1_15 + p1_16 + p1_17 + p1_18 + p1_19 + p1_20 + p1_21 + p1_22 + p1_23 + p1_24 <= Q);
rome_constraint(p2_1 + p2_2 + p2_3 + p2_4 + p2_5 + p2_6 + p2_7 + p2_8 + p2_9 + p2_10 + p2_11 + p2_12...
              + p2_13 + p2_14 + p2_15 + p2_16 + p2_17 + p2_18 + p2_19 + p2_20 + p2_21 + p2_22 + p2_23 + p2_24 <= Q);
rome_constraint(p3_1 + p3_2 + p3_3 + p3_4 + p3_5 + p3_6 + p3_7 + p3_8 + p3_9 + p3_10 + p3_11 + p3_12...
              + p3_13 + p3_14 + p3_15 + p3_16 + p3_17 + p3_18 + p3_19 + p3_20 + p3_21 + p3_22 + p3_23 + p3_24 <= Q);

p1 = [p1_1, p1_2, p1_3, p1_4, p1_5, p1_6, p1_7, p1_8, p1_9, p1_10, p1_11, p1_12...
             , p1_13, p1_14, p1_15, p1_16, p1_17, p1_18, p1_19, p1_20, p1_21, p1_22, p1_23, p1_24];
p2 = [p2_1, p2_2, p2_3, p2_4, p2_5, p2_6, p2_7, p2_8, p2_9, p2_10, p2_11, p2_12...
             , p2_13, p2_14, p2_15, p2_16, p2_17, p2_18, p2_19, p2_20, p2_21, p2_22, p2_23, p2_24];
p3 = [p3_1, p3_2, p3_3, p3_4, p3_5, p3_6, p3_7, p3_8, p3_9, p3_10, p3_11, p3_12...
             , p3_13, p3_14, p3_15, p3_16, p3_17, p3_18, p3_19, p3_20, p3_21, p3_22, p3_23, p3_24];		
			 
for t = 1:T
    rome_constraint(v + sum(p1(1:t)) + sum(p2(1:t)) + sum(p3(1:t)) - sum(d(1:t)) >= vmin);
    rome_constraint(v + sum(p1(1:t)) + sum(p2(1:t)) + sum(p3(1:t)) - sum(d(1:t)) <= vmax);
end
% 
model.solve;
fprintf('Optimal objective value: %.4f\n', model.ObjVal);

x1 = [];
x2 = [];
x3 = [];
for i = 1:T
    xx = model.eval(p1(i));
    xx = xx.insert(d0(1:t));
    x1 = [x1; xx];

    xx = model.eval(p2(i));
    xx = xx.insert(d0(1:t));
    x2 = [x2; xx];

    xx = model.eval(p3(i));
    xx = xx.insert(d0(1:t));
    x3 = [x3; xx];
end

sum([x1 x2 x3] .* c', 'all')
% x_sol = model.eval(p); % Get the solution object
% xx = x_sol.insert(d0);
% xx = reshape(xx, 3, []);
% cost = sum(c .* xx, 'all');