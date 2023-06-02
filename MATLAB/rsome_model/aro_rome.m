function [obj_val, x_fsp_ldr, x_vsp_ldr, model, z] = aro_rome(sim, uset_type, omega, delta)
    rome_begin;
    model = rome_model();
    model.Solver = 'MOSEK';

    n_fsp = height(sim.net.fsp);
    n_vsp = height(sim.net.vsp);
    n_tanks = height(sim.net.tanks);
    
    % declare uncertainty variables
    z = newvar(n_tanks * sim.T, 'uncertain');
    rome_constraint(norm2(z) <= omega);
    % rome_box(z, -1, 1);
    % rome_constraint(norm1(z)<=omega);   % Budget of uncertainty approach

    % declare decision variables for fixed speed pumps
    x_fsp = rome_empty_var(height(sim.net.fsp), sim.T);
    for t = 1:1:sim.T
        for j = 1:1:height(sim.net.fsp)
            x_fsp(j, t) = rome_linearrule(z(1:t-1));
        end
    end
    % newvar x_fsp(4, sim.T);  % for static RO
    rome_constraint(0 <= x_fsp);
    rome_constraint(x_fsp <= 1);

    % declare decision variables for varialbe speed pumps
    if n_vsp >= 1
        x_vsp = rome_empty_var(height(sim.net.vsp), sim.T);
        for t = 1:1:sim.T
            for j = 1:1:height(sim.net.vsp)
                x_vsp(j, t) = rome_linearrule(z(1:t-1));
            end
        end

        for i = 1:1:n_vsp
            max_flow = sim.net.vsp{i, "max_flow"};
            min_flow = sim.net.vsp{i, "min_flow"};
            rome_constraint(min_flow <= x_vsp(i, :));
            rome_constraint(x_vsp(i, :) <= max_flow);
        end
    end

    % Objective function
    % vsp have no costs - can be added in the future
    obj_func = sum((sim.net.fsp{:, "power"}' * x_fsp(:, :))' .* sim.data{:, "tariff"});
    rome_minimize(obj_func);
    
    % Only one comb at every time step
    facilities = unique(sim.net.fsp.facility);
    for i = 1:1:size(unique(sim.net.fsp.facility), 1)
        mat = zeros(1, n_fsp);
        facility_idx = sim.net.fsp{sim.net.fsp.facility == facilities(i), "comb"};
        mat(facility_idx') = 1;
        rome_constraint((mat * x_fsp)' <= ones(24, 1));
    end

    % Mass-balance constraints
    for tt=1:sim.T
        lhs = sim.net.tanks{1, "init_vol"} + sim.net.fsp{:, "flow"}' * sum(x_fsp(:, 1:tt), 2);
        tank_consumer = sim.net.tanks{1, "demand"};
        tank_demand = table2array(sim.data(:, tank_consumer));
        cum_demand = sum( (1 + delta * z(1:tt)) .* tank_demand(1:tt));
        min_vol_vector = sim.get_min_vol_vector(1, 1);
        rome_constraint(lhs - cum_demand >= min_vol_vector(tt));
        rome_constraint(lhs - cum_demand <= sim.net.tanks{1, "max_vol"});
    end



    % for tank_idx = 1:1:height(sim.net.tanks)
    %     lhs = sim.net.tanks{tank_idx, "init_vol"};
    %     % fsp flows
    %     for i = 1:1:height(sim.net.fsp.facility)
    %         if sim.net.fsp{i, "in"} == tank_idx
    %             % fsp inflows
    %             mat = sim.net.get_cumulative_mat(sim.T, 1);
    %             lhs = lhs + sim.net.fsp{i, "flow"} * mat * x_fsp(i, :)';
    %         elseif sim.net.fsp{i, "out"} == tank_idx
    %             % fsp outflows
    %             mat = sim.net.get_cumulative_mat(sim.T, -1);
    %             lhs = lhs + sim.net.fsp{i, "flow"} * mat * x_fsp(i, :)';
    %         else
    %             continue
    %         end
    %     end
    % 
    %     % vsp flows
    %     for i = 1:1:height(sim.net.vsp)
    %         if sim.net.vsp{i, "in"} == tank_idx
    %             % vsp inflows
    %             mat = sim.net.get_cumulative_mat(sim.T, 1);
    %             lhs = lhs + mat * x_vsp(i, :)';
    %         elseif sim.net.vsp{i, "out"} == tank_idx
    %             % vsp outflows
    %             mat = sim.net.get_cumulative_mat(sim.T, -1);
    %             lhs = lhs + mat * x_vsp(i, :)';
    %         else
    %             continue
    %         end
    %     end
    % 
    %     tank_consumer = sim.net.tanks{tank_idx, "demand"};
    %     tank_demand = table2array(sim.data(:, tank_consumer));
    % 
    %     z_tank = z((tank_idx-1)*sim.T+1: tank_idx*sim.T);
    %     tank_demand = (1 + delta * z_tank) .* tank_demand;
    %     mat = sim.net.get_cumulative_mat(sim.T, 1);
    %     cum_demand = mat * tank_demand;
    %     min_vol_vector = sim.get_min_vol_vector(tank_idx, 1);
    %     rome_constraint(lhs - cum_demand >= min_vol_vector);
    %     rome_constraint(lhs - cum_demand <= sim.net.tanks{tank_idx, "max_vol"});
    % end

    % vsp initial flow
    for i = 1:1:height(sim.net.vsp)
        if isnan(sim.net.vsp{i, "init_flow"})
            continue
        else
            rome_constraint(x_vsp(i, 1) == sim.net.vsp{i, "init_flow"});
        end
    end

    % vsp total volume constraints
    for i = 1:1:height(sim.net.vsp)
        min_vol = sim.net.vsp{i, "min_vol"};
        max_vol = sim.net.vsp{i, "max_vol"};

        rome_constraint(sum(eye(sim.T) * x_vsp(i, :)') >= min_vol);
        rome_constraint(sum(eye(sim.T) * x_vsp(i, :)') <= max_vol);
    end

    % vsp change in flow
    const_tariffs = utils.get_constant_tariff_periods(sim.data.tariff);
    for i = 1:1:height(sim.net.vsp)
        if sim.net.vsp{i, "const_flow"} == 1
            for j = 1:1:max(const_tariffs)
                idx = find(const_tariffs == j);
                idx = idx(1:end-1);
                mat = utils.get_mat_for_value_canges(sim.T, idx);
                rome_constraint(mat * x_vsp(i, :)' == 0);
            end
        else
            continue
        end
    end
    

    model.solve;
    obj_val = model.ObjVal;
    x_fsp_ldr = model.eval(x_fsp);
    if n_vsp >= 1
        x_vsp_ldr = model.eval(x_vsp);
    else
        x_vsp_ldr = 0;
end

