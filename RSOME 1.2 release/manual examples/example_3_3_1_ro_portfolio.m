%% Parameters
n  = 150;                                % Number of stocks 
p  = 1.15 + 0.05/150*(1:n)';             % Mean return
sigma = 0.05/450*sqrt(2*n*(n+1)*(1:n)'); % Maximum deviation
Gamma = 3;                               % Gamma as the budget of uncertainty

%% RSOME model
model = rsome('portfolio');              % Create a model, named "portfolio"

%% Random variables and the ambiguity set
z = model.random(n);                     % Random deviation z 
P = model.ambiguity;                     % Create P as the ambiguity set
P.suppset(norm(z, Inf) <= 1, ...
          norm(z, 1) <= Gamma);          % Uncertainty set of z
model.with(P);                           % Set P as the ambiguity set of model 

%% Decision variables
x = model.decision(n);                   % Decision x as fractions of investment

%% Objective function and constraints
model.max((p+sigma.*z)' * x)             % Define the objective function
model.append(sum(x) == 1);               % Constraint of x
model.append(x >= 0);                    % x are non-negative

%% Solution
model.solve;                             % Solve the problem