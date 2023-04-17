model = rsome;                          % Create an RSOME model

%% Random variables and an ambiguity set with NS=10 scenarios
z = model.random(3, 5);                 % Random variables z
S = 10;                                 % Number of scenarios
P = model.ambiguity(S);                 % Create an ambiguity set
for s = 1:S
    P(s).suppset(z == rand(3, 5));      % Support of each scenario
end
model.with(P);                          % The ambiguity set of model is P

%% Non-adaptive decisions x
w = model.decision(2, 3);               % Non-adaptive decision w

%% Event-wise static adaptive decisions x
x = model.decision(2, 3);               % Decision x
for s = 1:S
    x.evtadapt(s);                      % x adapts to each scenario
end 

%% Event-wise affinely adaptive decisions y
y = model.decision(2, 3);               % Decision y
y.evtadapt(1:3);                        % y adapt to an event with scenarios 1:3
y.evtadapt(4:5);                        % y adapt to an event with scenarios 4:5
y.evtadapt(6:10);                       % y adapt to an event with scenarios 6:10
y.affadapt(z(1:3));                     % y also affinely depends on z(1:3)