function [obj_val, x_fsp_val, x_vsp_val, z_val, model, x_fsp, z] = aro(sim, uset_type, omega, delta)
    model = rsome();
    model.Param.solver = 'gurobi';
    model.Param.display = 0;
    
    n_fsp = height(sim.net.fsp);
    n_vsp = height(sim.net.vsp);
    n_tanks = height(sim.net.tanks);
    
    % declare decision variables for fixed speed pumps
    x_fsp = model.decision(height(sim.net.fsp), sim.T);
    model.append(0 <= x_fsp);
    model.append(x_fsp <= 1);
    
    % declare decision variables for varialbe speed pumps
    x_vsp = model.decision(height(sim.net.vsp), sim.T);
    for i = 1:1:n_vsp
        max_flow = sim.net.vsp{i, "max_flow"};
        min_flow = sim.net.vsp{i, "min_flow"};
        model.append(min_flow <= x_vsp(i, :));
        model.append(x_vsp(i, :) <= max_flow);
    end

    % declare random variables
    z = model.random(1, n_tanks * sim.T);
    % declare uncertainty set
    u = model.ambiguity;
    u.suppset(norm(z, uset_type) <= omega);
    model.with(u);

    % adapt uncertainty to decision variables
    if n_fsp >= 1
        for t = 2:1:sim.T
            x_fsp(:, t).affadapt(z(1:t-1));
        end
    end

    if n_vsp >= 1
        for t = 2:1:sim.T
            x_vsp(:, t).affadapt(z(1:t-1));
        end
    end
    
    % Objective function
    % vsp have no costs - can be added in the future
    obj_func = sum((sim.net.fsp{:, "power"}' * x_fsp(:, :))' .* sim.data{:, "tariff"});
    model.min(obj_func);
    
    % Only one comb at every time step
    facilities = unique(sim.net.fsp.facility);
    for i = 1:1:size(unique(sim.net.fsp.facility), 1)
        mat = zeros(1, n_fsp);
        facility_idx = sim.net.fsp{sim.net.fsp.facility == facilities(i), "comb"};
        mat(facility_idx') = 1;
        model.append((mat * x_fsp)' <= ones(24, 1));
    end

    % Mass-balance constraints
    for tank_idx = 1:1:height(sim.net.tanks)
        lhs = sim.net.tanks{tank_idx, "init_vol"};
        % fsp flows
        for i = 1:1:height(sim.net.fsp.facility)
            if sim.net.fsp{i, "in"} == tank_idx
                % fsp inflows
                mat = sim.net.get_cumulative_mat(sim.T, 1);
                lhs = lhs + sim.net.fsp{i, "flow"} * mat * x_fsp(i, :)';
            elseif sim.net.fsp{i, "out"} == tank_idx
                % fsp outflows
                mat = sim.net.get_cumulative_mat(sim.T, -1);
                lhs = lhs + sim.net.fsp{i, "flow"} * mat * x_fsp(i, :)';
            else
                continue
            end
        end

        % vsp flows
        for i = 1:1:height(sim.net.vsp)
            if sim.net.vsp{i, "in"} == tank_idx
                % vsp inflows
                mat = sim.net.get_cumulative_mat(sim.T, 1);
                lhs = lhs + mat * x_vsp(i, :)';
            elseif sim.net.vsp{i, "out"} == tank_idx
                % vsp outflows
                mat = sim.net.get_cumulative_mat(sim.T, -1);
                lhs = lhs + mat * x_vsp(i, :)';
            else
                continue
            end
        end

        tank_consumer = sim.net.tanks{tank_idx, "demand"};
        tank_demand = table2array(sim.data(:, tank_consumer));        
        tank_demand = (1 + delta * z((tank_idx-1)*sim.T+1: tank_idx*sim.T)') .* tank_demand;
        mat = sim.net.get_cumulative_mat(sim.T, 1);
        cum_demand = mat * tank_demand;
        min_vol_vector = sim.get_min_vol_vector(tank_idx, 1);
        model.append(lhs - cum_demand >= min_vol_vector);
        model.append(lhs - cum_demand <= sim.net.tanks{tank_idx, "max_vol"});

    end

    % vsp initial flow
    for i = 1:1:height(sim.net.vsp)
        if isnan(sim.net.vsp{i, "init_flow"})
            continue
        else
            model.append(x_vsp(i, 1) == sim.net.vsp{i, "init_flow"});
        end
    end
    
    % vsp total volume constraints
    for i = 1:1:height(sim.net.vsp)
        min_vol = sim.net.vsp{i, "min_vol"};
        max_vol = sim.net.vsp{i, "max_vol"};

        model.append(sum(eye(sim.T) * x_vsp(i, :)') >= min_vol);
        model.append(sum(eye(sim.T) * x_vsp(i, :)') <= max_vol);
    end

    % vsp change in flow
    const_tariffs = utils.get_constant_tariff_periods(sim.data.tariff);
    for i = 1:1:height(sim.net.vsp)
        if sim.net.vsp{i, "const_flow"} == 1
            for j = 1:1:max(const_tariffs)
                idx = find(const_tariffs == j);
                mat = utils.get_mat_for_value_canges(sim.T, idx);
                model.append(mat * x_vsp(i, :)' == 0);
            end
        else
            continue
        end
    end
    
    % Solve
    model.solve
    if model.Solution.status == 'OPTIMAL'
        obj_val = model.get;
        x_fsp_val = x_fsp.get;
        x_vsp_val = x_vsp.get;
        z_val = z.get;
    else
        fprintf('NOT FEASIBLE\n')
        obj_val = 999999;
        x_fsp_val = [];
        x_vsp_val = [];
    end
end

