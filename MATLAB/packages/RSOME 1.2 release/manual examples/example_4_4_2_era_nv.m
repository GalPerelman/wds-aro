%% Parameters
Ubar = 100;                               % Upper bounds of random demands
S = 500;                                  % Number of samples 
Uhat = Ubar * rand(1, S);                 % Empirical data of demands

p = 1.5;                                  % Selling price of the product
c = 1.0;                                  % Production cost of the product
theta = Ubar*0.01;                        % The Wasserstein ball radius

%% Create an RSOME model
model = rsome('newsvendor');              % Create a model named "newsvendor"

%% Random variables and a Warsserstein ambiguity set
u = model.random;                         % Random demand
v = model.random;                         % Auxiliary random variable 
P = model.ambiguity(S);                   % Create an ambiguity set P
for n = 1:S
    P(n).suppset(0 <= u, u <= Ubar, ...   
                 norm(u - Uhat(n)) <= v); % Support set for each scenario
end
P.exptset(expect(v) == theta);
pr=P.prob;                                % pr for all scenario probabilities
P.probset(1/S == pr);                     % The probability set 
model.with(P);                            % Ambiguity set of the model is P

%% Decisions and event-wise recourse adaptation
w = model.decision;                       % Non-adaptive decision variable w
y = model.decision;                       % Recourse decision y
for n = 1:S
    y.evtadapt(n);                        % Decision y adapts to each scenario
end
y.affadapt(u);
y.affadapt(v);                            % Decision y affinely depends on (u, v)

model.max((p-c)*w - expect(y));           % Obj. as the worst-case expectation
model.append(y >= 0);                       
model.append(y >= p * (w-u));             % y expresses the adaptive term
model.append(w >= 0);                     % Variable w is non-negative

%% Solution
model.solve;                              % Solve the model