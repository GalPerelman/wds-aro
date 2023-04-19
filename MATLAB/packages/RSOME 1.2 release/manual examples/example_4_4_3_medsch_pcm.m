%% Parameters
n = 8;                                       % The number of patients
c = 2;                                       % Cost parameter

mu = 30 + 30*rand(n, 1);                     % Mean values of service time
sigma = 0.3*mu .* rand(n, 1);                % Std. deviations of service time
T = sum(mu) + 0.5*norm(sigma);               % Total working hours

%% Create a RSOME model
model = rsome;                               % Create a model     

%% Random variables and a partial cross moment ambiguity set
u = model.random(n);                         % Random service time
v = model.random(n+1);                       % Auxiliary random variables
P = model.ambiguity;                         % Create an ambiguity set
P.suppset(u >= 0, ...                              
          (u-mu).^2 <= v(1:end-1),...
          sum((u-mu)).^2 <= v(end));         % Lifted support for u
P.exptset(expect(u) <= mu, ...
          expect(v(1:end-1)) <= sigma.^2, ... 
          expect(v(end)) <= sum(sigma.^2));  % Partial cross moments
model.with(P);

%% Decisions and event-wise recourse adaptations
w = model.decision(n);                       % Scheduled appointment time 
y = model.decision(n+1);                     % Recourse decision y as waiting time 
y.affadapt(u);                               % y affinely depends on u
y.affadapt(v);                               % y affinely depends on v

%% Objective function
model.min(expect(sum(y(1:end-1)) + c*y(end)));  

%% Constraints
model.append(y(2:end) >= y(1:end-1) + u - w);   
model.append(y >= 0);                           
model.append(sum(w) <= T);
model.append(w >= 0);


%% Solution
model.solve;                                 % Solve the model