%% Parameters
S = 8;                              % Number of scenarios
A = 1 + [0.25, 0.14; ...
         0.06, 0.12];               % Outcomes of investment returns
a = cell(1, S);                     % A cell array for uncertain returns
for s = 1:S
    s1 = ceil(s/4);
    s2 = mod(ceil(s/2)-1, 2) + 1;
    s3 = mod(s-1, 2) + 1;
    a{s} = [A(s1, :)', ...
            A(s2, :)', ...
            A(s3, :)'];             % Outcome of returns in scenario s
end
tau = 80;
d = 55;

%% Create an RSOME model 
model = rsome('sp model');          % Create a model named "sp model"  

%% Random variables and an ambiguity set with eight scenarios
z = model.random(2, 3);             % Random return of investments as z
P = model.ambiguity(S);             % Create a ambiguity set P
for s = 1:S
    P(s).suppset(z == a{s});        % Support of u as a fixed value
end
pr = P.prob;                        % pr as the vector of scenario probabilities
P.probset(pr == 1/S);               % Equal probabilities of all scenarios
model.with(P);                      % Ambiguity set of model is P

%% Decisions and decision tree
tree = P.tree(4);                   % A decision tree with 4 stages
tree(3).mergechild({1:2, 3:4, ...
                    5:6, 7:8});     % Define event set for stage 3
tree(2).mergechild({1:2, 3:4});     % Define event set for stage 2
tree(1).mergechild({1:2});          % Define event set for stage 1

w = tree(1).decision(2);            % Nonadaptive decisions as the root
x = tree(2:3).decision(2);          % Adaptive decisions x for stages 2 and 3
xu = tree(4).decision;              % Deficit variable \underline{x} for stage 4
xo = tree(4).decision;              % Excess variable \overline{x} for stage 4

%% Objective function
model.max(expect(xo - 4*xu));       % Objective function as the expected utility

%% Constraints
model.append(w >= 0);
model.append(w(1) + w(2) == d);
model.append(x(1).stage(2) + x(2).stage(2) - z(:, 1)'*w == 0);
model.append(x(1).stage(3) + x(2).stage(3) - z(:, 2)'*x.stage(2) == 0);
model.append(z(:, 3)'*x.stage(3) - xo + xu == tau);
model.append(x.stage(2) >= 0);
model.append(x.stage(3) >= 0);
model.append(xu >= 0);
model.append(xo >= 0);

%% Solution
model.solve;                        % Solve the stochastic model