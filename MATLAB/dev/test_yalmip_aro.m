clc
clear all
close all

addpath(genpath('C:\Users\User\Documents\GitHub\YALMIP-master'));
addpath('C:\gurobi1001\win64\matlab')

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
theta = 0.03;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d = sdpvar(T,1);
constr = [(1-theta)*d0 <= d <= (1+theta)*d0, uncertain(d)];

% x = sdpvar(3, T);
% pi = sdpvar(3,T,T);
% 
% for j=1:size(x,1)
%     for t=1:T
%         if t == 1
%             constr = [constr, x(j, t) == pi(j,1,1)];
%         else
%             % size((pi(j, t, 2:t)'))
%             % size(d(1:t-1))
%             constr = [constr, x(j, t) == pi(j,t,1) + sum(pi(j, t, 2:t)' .* d(1:t-1))];
%         end
%     end
% end

x = sdpvar(1, T);
pi = sdpvar(T,T);
for
constr = [constr, x(1) == pi(1, 1)];
constr = [constr, x(2) == pi(2, 2)*d(1)];
constr = [constr, x(3) == pi(2, 2)*d(1) + pi(2, 2:3)*d(1:2)];
constr = [constr, x(4) == pi(2, 2)*d(1) + pi(2, 2:3)*d(1:2)];
constr = [constr, x(5) == pi(2, 2)*d(1) + pi(2, 2:3)*d(1:2)];
constr = [constr, x(6) == pi(2, 2)*d(1) + pi(2, 2:3)*d(1:2)];

objective = sum(sum(c.*x));
constr = [constr, x >= 0];
constr = [constr, x <= P];
for t=1:T
    constr = [constr, v + sum(sum(x(:, 1:t))) - sum(d(1:t)) >= vmin];
    constr = [constr, v + sum(sum(x(:, 1:t))) - sum(d(1:t)) <= vmax];
end
% [constr, sum(x(:, 1:T), 'all') - sum(d(1:T)) >= 0];

options = sdpsettings('solver', 'gurobi', 'verbose', 0, 'debug', 1);
diagnostics = optimize(constr ,objective, options);
fprintf('Nominal solution: %.1f\n', value(objective));

xx = value(x);
pi_val = value(pi);
vol = v + cumsum(sum(xx, 1)') - cumsum(d0(1:T));
plot(vol)

if diagnostics.problem == 0
 disp('Solver thinks it is feasible')
elseif diagnostics.problem == 1
 disp('Solver thinks it is infeasible')
else
 disp('Something else happened')
end

% x = [];
% for t = 1:T
%     x(t) = sum(pi(1:t-1));
% end 

% objective = c(2,:)' * x;

% for t = 1:T
%     constr = [constr, x(t) >= 0];
%     constr = [constr, x(t) <= 3*P];
% end 

% constr = [constr, x <= P*3];
% constr = [constr, 0 <= x(1)];
% constr = [constr, pi(1) >= 0];
% for t = 1:T
    % v
    % sum(x(1:t))
    % sum(d(1:t))
    % vmin
    % constr = [constr, v + sum(x(1:t)) - sum(d(1:t)) >= vmin];
%     constr = [constr, v + sum(x(1:t)) - sum(d(1:t)) <= vmax];
% end

% options = sdpsettings('solver', 'gurobi', 'verbose', 0, 'debug', 1);
% optimize(constr ,objective, options);
% fprintf('Nominal solution: %.1f\n', -value(obj));
