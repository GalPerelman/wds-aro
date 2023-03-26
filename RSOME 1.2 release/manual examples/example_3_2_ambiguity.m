NS = 5;                                     % number of scenarios
mu = rand(3, NS);                           % the expectation of random varaibles
sigma = mu*0.2;                             % the standard deviation of random variables

model = rsome('ambiguity');                 % create a AROMA model

u = model.random(3);
v = model.random(3);

P =model.ambiguity(NS);                     % create an ambiguity set with NS scenarios 
for n = 1:NS
    P(n).suppset(0 <= u, u <= 1, ... 
                (u-mu(:, n)).^2 <= v);      % support of z and u for each scenario
    P(n).exptset(expect(u) == mu(:, n), ...
                 expect(v) == sigma(:, n)); % conditional expectation set for each scenario
end
P.exptset(expect(u) == 0.5);                % the expectation set of z 
pr=P.prob;                                  % pr is a N*1 vector of scenario probabilities
P.probset(pr == 1/NS);                      % the feasible set of scenario probabilities

model.with(P);                              % the ambiguity set of the model is P