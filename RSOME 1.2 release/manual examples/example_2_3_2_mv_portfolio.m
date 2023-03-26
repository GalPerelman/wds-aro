n  = 150;                                % Number of stocks 
p  = 1.15+ 0.05/150*(1:n)';              % Mean returns
sigma = 0.05/450*sqrt(2*(1:n)'*n*(n+1)); % Standard deviations
phi = 5;                                 % Trade-off constant

model = rsome('mean-var portfolio');     % Create a model

x = model.decision(n);                   % Decisions as fractions of investment

model.max(p'*x - phi*sumsqr(sigma.*x));  % Define objective
model.append(sum(x)==1);                 % Constraint of x
model.append(x>=0);                      % Bound of x

model.solve;                             % Solve the problem
