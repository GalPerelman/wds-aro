%% Parameters
Ubar = 100;                             % Upper bounds of random demands
S = 500;                                % Number of samples 
Uhat = Ubar * rand(1, S);               % Empirical data of demands

p = 1.5;                                % Selling price of the product
c = 1.0;                                % Production cost of the product
theta = Ubar*0.01;                      % The Wasserstein distance

%% Create a RSOME model
model = rsome('newsvendor');            % Create a model object named "newsvendor"

%% Random variables and a type-1 Wasserstein ambiguity set
u = model.random;                       % Random demand
v = model.random;                       % Auxiliary random variable 
P = model.ambiguity(S);                 % Create an ambiguity set with S scenarios
for n = 1:S
    P(n).suppset(0 <= u, u <= Ubar, ...   
                 norm(u-Uhat(n)) <= v );% Define the support set for each scenario
end
P.exptset(expect(v) <= theta);
prob = P.prob;                          % pr for all scenario probabilities
P.probset(prob == 1/S);                 % The probability set of the ambiguity set
model.with(P);                          % The ambiguity set of the model is P

%% Decision
w = model.decision;                     % Define a decision variable w

%% Objective function
loss = maxfun({p*(w-u), 0});            % Profit loss due to unsold products
model.max((p-c)*w - expect(loss));      % Objective as the worst-case expectation

%% Constraints
model.append(w >= 0);                   % The variable w is non-negative

%% Solution
model.solve;                            % Solve the model