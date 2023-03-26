%% Parameters
n = 8;                                         % The number of patients
c = 2;                                         % Cost parameter
S = 256;                                       % Sample size S
theta = S^(-1/8);                              % Robustness parameter

mu = 30 + 30*rand(n, 1);                       % Mean values of service time
sigma = 0.3*mu .* rand(n, 1);                  % Std. deviations of service time
T = sum(mu) + 0.5*norm(sigma);                 % Total working hours

Uhat = mu*ones(1, S) + ...
       diag(sigma)*randn(n, S);                % Randomly generated sample   

%% Create a RSOME model
model = rsome;

%% Random variables and the type-infinity Wasserstein ambiguity set
u = model.random(n);
P = model.ambiguity(S);                        % Crate an S-scenario ambiguity set
for s = 1:S
    P(s).suppset(u >= 0, ...
                 norm(u-Uhat(:, s)) <= theta); % Conditional support for u
end
pr = P.prob;                                   % Vector of scenario probabilities
P.probset(pr == 1/S);                          % Set of scenario probabilities
model.with(P);

%% Decisions and event-wise recourse adaptations
w = model.decision(n);                         % Scheduled appointment time 
y = model.decision(n+1);                       % Recourse decision y as waiting time
for s = 1:S
    y.evtadapt(s);                             % Adaptation to each scenario
end
y.affadapt(u);                                 % y affinely depends on u

%% Objective function
model.min(expect(sum(y(1:end-1)) + c*y(end)));

%% Constraints
model.append(y(2:end) >= y(1:end-1) + u - w);
model.append(y >= 0);
model.append(sum(w) <= T);
model.append(w >= 0);

%% Solution
model.solve;                                   % Solve the problem