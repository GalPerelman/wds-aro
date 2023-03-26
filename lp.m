function [obj_val, x_val] = lp(sim)
    model = rsome();
    model.Param.solver = 'gurobi';
    
    n_combs = height(sim.net.fsp);
    x = model.decision(height(sim.net.fsp), sim.T);
    model.append(0 <= x);
    model.append(x <= 1);
    
    % Objective function
    obj_func = sum((sim.net.fsp{:, "power"}' * x(:, :))' .* sim.data{:, "tariff"});
    model.min(obj_func);
    
    % Only one comb at every time step
    facilities = unique(sim.net.fsp.facility);
    mat = zeros(1, n_combs);
    for i = 1:1:size(unique(sim.net.fsp.facility), 1)
        facility_idx = sim.net.fsp{sim.net.fsp.facility == facilities(i), "comb"};
        mat(facility_idx') = 1;
        model.append((mat * x)' <= ones(24, 1));
    end

    % Mass-balance constraints
    for tank_idx = 1:1:height(sim.net.tanks)
        lhs = sim.net.tanks{tank_idx, "init_vol"};
        for i = 1:1:height(sim.net.fsp.facility)
            if sim.net.fsp{i, "in"} == tank_idx
                mat = sim.net.get_cumulative_mat(sim.T, 1);
                lhs = lhs + sim.net.fsp{i, "flow"} * mat * x(i, :)';
            elseif sim.net.fsp{i, "out"} == tank_idx
                mat = sim.net.get_cumulative_mat(sim.T, -1);
                lhs = lhs + sim.net.fsp{i, "flow"} * mat * x(i, :)';
            else
                continue
            end
        end
        tank_consumer = sim.net.tanks{tank_idx, "demand"};
        cum_demand = table2array(cumsum(sim.data(:, tank_consumer)));
        min_vol_vector = sim.get_min_vol_vector(tank_idx, 1);
        model.append(lhs - cum_demand >= min_vol_vector);
        model.append(lhs - cum_demand <= sim.net.tanks{tank_idx, "max_vol"});

    end
    
    % Solve
    model.solve;
    obj_val = model.get;
    x_val = x.get;
end

