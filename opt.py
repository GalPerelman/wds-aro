import os
import pandas as pd
import numpy as np
import pickle
from rsome import ro
import rsome as rso
from rsome import grb_solver as grb

import utils


class RO:
    def __init__(self, sim, uset_type, omega, delta):
        self.sim = sim
        self.uset_type = uset_type
        self.omega = omega              # omega = robustness, size of uncertainty set
        self.delta = delta              # level of uncertainty

        self.model = ro.Model()
        self.z, self.uset = self.declare_rand_variables()
        self.x_fsp, self.x_vsp = self.declare_decision_variables()
        self.build()

    def build(self):
        self.objective_func()
        self.one_comb_only()
        self.mass_balance()
        self.vsp_initial_flow()
        self.vsp_total_vol()
        self.vsp_flow_change()
        self.max_power()

    def declare_rand_variables(self):
        z = self.model.rvar((len(self.sim.net.tanks), self.sim.T))
        uset = rso.norm(z.reshape(-1), self.uset_type) <= self.omega
        return z, uset

    def declare_decision_variables(self):
        x_fsp = self.model.dvar((len(self.sim.net.fsp), self.sim.T))
        self.model.st(0 <= x_fsp)
        self.model.st(x_fsp <= 1)

        x_vsp = self.model.dvar((len(self.sim.net.vsp), self.sim.T))
        for i, row in self.sim.net.vsp.iterrows():
            self.model.st(x_vsp[i, :] >= row['min_flow'])
            self.model.st(x_vsp[i, :] <= row['max_flow'])
        return x_fsp, x_vsp

    def objective_func(self):
        """ vsp have no additional costs in the examples of this paper """
        obj_func = sum(self.sim.net.fsp.loc[:, "power"].values @ self.x_fsp * self.sim.data.loc[:, "tariff"].values)
        self.model.minmax(obj_func)

    def one_comb_only(self):
        for pump_station in self.sim.net.fsp['name'].unique():
            idx = self.sim.net.fsp.loc[self.sim.net.fsp['name'] == pump_station].index.to_list()
            self.model.st(sum([self.x_fsp[_, :] for _ in idx]) <= 1)

    def mass_balance(self):
        for tank_idx, row in self.sim.net.tanks.iterrows():
            tank_consumer = self.sim.net.tanks.loc[tank_idx, 'demand']
            tank_demand = self.sim.data[tank_consumer].values
            cum_tank_demand = self.sim.data[tank_consumer].values.cumsum()
            init_vol = self.sim.net.tanks.loc[tank_idx, "init_vol"]
            max_vol = self.sim.net.tanks.loc[tank_idx, "max_vol"]
            min_vol = self.sim.net.tanks.loc[tank_idx, "min_vol"]
            min_vol_vector = self.sim.get_min_vol_vector(tank_idx)

            fsp_inflow_idx = self.sim.net.fsp.loc[self.sim.net.fsp['in'] == tank_idx].index.to_list()
            fsp_outflow_idx = self.sim.net.fsp.loc[self.sim.net.fsp['out'] == tank_idx].index.to_list()
            vsp_inflow_idx = self.sim.net.vsp.loc[self.sim.net.vsp['in'] == tank_idx].index.to_list()
            vsp_outflow_idx = self.sim.net.vsp.loc[self.sim.net.vsp['out'] == tank_idx].index.to_list()

            fsp_inflow = self.sim.net.fsp.loc[fsp_inflow_idx, 'flow'].values
            fsp_outflow = self.sim.net.fsp.loc[fsp_outflow_idx, 'flow'].values
            for t in range(self.sim.T):
                lhs = init_vol
                if fsp_inflow_idx:
                    lhs += fsp_inflow @ (self.x_fsp[fsp_inflow_idx, :t + 1]).sum(axis=1)
                if vsp_inflow_idx:
                    lhs += (self.x_vsp[vsp_inflow_idx, :t + 1]).sum()
                if fsp_outflow_idx:
                    lhs -= fsp_outflow @ (self.x_fsp[fsp_outflow_idx, :t + 1]).sum(axis=1)
                if vsp_outflow_idx:
                    lhs -= (self.x_vsp[vsp_outflow_idx, :t + 1]).sum()

                lhs = lhs - ((self.delta * self.z[tank_idx - 1, :t + 1] + 1) * tank_demand[:t + 1]).sum()
                self.model.st((lhs >= min_vol_vector[t]).forall(self.uset))
                self.model.st((lhs <= max_vol).forall(self.uset))

    def vsp_initial_flow(self):
        for i, row in self.sim.net.vsp.iterrows():
            if np.isnan(row['init_flow']):
                continue
            else:
                self.model.st(self.x_vsp[i, 0] == row['init_flow'])

    def vsp_total_vol(self):
        for i, row in self.sim.net.vsp.iterrows():
            self.model.st(self.x_vsp[i, :].sum() >= row['min_vol'])
            self.model.st(self.x_vsp[i, :].sum() <= row['max_vol'])

    def vsp_flow_change(self):
        const_tariff = utils.get_constant_tariff_periods(self.sim.data['tariff']).astype(int)
        for i, row in self.sim.net.vsp.iterrows():
            if row['const_flow']:
                for j in range(max(const_tariff) + 1):
                    idx = np.where(const_tariff == j)[0]
                    mat = utils.get_mat_for_vsp_value_changes(self.sim.T, idx)
                    self.model.st(mat @ self.x_vsp[i, :].T == 0)
            else:
                continue

    def max_power(self):
        """
        This function is currently customized for Sopron network only
        The problem conditions are such that the only power constraint is
        Power Station D (Pump Stations 5 and 6) must be under 35 kW during the On-Peak periods
        The meaning is that Pump station 5 cannot be operated with 116 CMH (37.5 kW) during the ON-Peak periods
        """
        max_power_constr = pd.read_csv(os.path.join(self.sim.data_folder, 'max_power.csv'))
        for i, row in max_power_constr.iterrows():
            fsp_idx = self.sim.net.fsp.loc[self.sim.net.fsp['comb'] == row['comb']].index.values[0]
            mat = utils.get_mat_for_tariff(self.sim, tariff_name=row['tariff'])
            self.model.st(mat @ self.x_fsp[fsp_idx, :] == 0)

    def solve(self):
        self.model.solve(solver=grb, display=False)
        obj, status = self.model.solution.objval, self.model.solution.status
        x_fsp_val, x_vsp_val = self.x_fsp.get(), self.x_vsp.get()
        return obj, status, x_fsp_val, x_vsp_val


class ARO:
    def __init__(self, sim, uset_type, omega, delta, worst_case=False):
        self.sim = sim
        self.uset_type = uset_type
        self.omega = omega              # omega = robustness, size of uncertainty set
        self.delta = delta              # level of uncertainty
        self.worst_case = worst_case    # return worst_case or nominal objective value

        self.model = ro.Model()
        self.z, self.uset, self.nominal_uset = self.declare_rand_variables()
        self.x_fsp, self.x_vsp = self.declare_decision_variables()
        self.build()

    def build(self):
        self.objective_func()
        self.one_comb_only()
        self.mass_balance()
        self.vsp_initial_flow()
        self.vsp_total_vol()
        self.vsp_flow_change()
        self.max_power()

    def declare_rand_variables(self):
        z = self.model.rvar((len(self.sim.net.tanks), self.sim.T))
        uset = rso.norm(z.reshape(-1), self.uset_type) <= self.omega
        nominal_uset = (z == 0)
        return z, uset, nominal_uset

    def declare_decision_variables(self):
        x_fsp = self.model.ldr((len(self.sim.net.fsp), self.sim.T))
        for t in range(1, self.sim.T):
            x_fsp[:, t].adapt(self.z[:, :t])  # adaptation of the decision rule
        self.model.st((0 <= x_fsp).forall(self.uset))
        self.model.st((x_fsp <= 1).forall(self.uset))

        x_vsp = self.model.ldr((len(self.sim.net.vsp), self.sim.T))
        for t in range(1, self.sim.T):
            x_vsp[:, t].adapt(self.z[:, :t])  # adaptation of the decision rule
        for i, row in self.sim.net.vsp.iterrows():
            self.model.st((x_vsp[i, :] >= row['min_flow']).forall(self.uset))
            self.model.st((x_vsp[i, :] <= row['max_flow']).forall(self.uset))
        return x_fsp, x_vsp

    def objective_func(self):
        """ vsp have no additional costs in the examples of this paper """
        obj_func = sum(self.sim.net.fsp.loc[:, "power"].values @ self.x_fsp * self.sim.data.loc[:, "tariff"].values)
        if self.worst_case:
            print('Solving Worst Case')
            self.model.minmax(obj_func)
        else:
            print('Solving Nominal')
            self.model.minmax(obj_func, self.nominal_uset)

    def one_comb_only(self):
        for pump_station in self.sim.net.fsp['name'].unique():
            idx = self.sim.net.fsp.loc[self.sim.net.fsp['name'] == pump_station].index.to_list()
            self.model.st((sum([self.x_fsp[_, :] for _ in idx]) <= 1).forall(self.uset))

    def mass_balance(self):
        for tank_idx, row in self.sim.net.tanks.iterrows():
            tank_consumer = self.sim.net.tanks.loc[tank_idx, 'demand']
            tank_demand = self.sim.data[tank_consumer].values
            cum_tank_demand = self.sim.data[tank_consumer].values.cumsum()
            init_vol = self.sim.net.tanks.loc[tank_idx, "init_vol"]
            max_vol = self.sim.net.tanks.loc[tank_idx, "max_vol"]
            min_vol = self.sim.net.tanks.loc[tank_idx, "min_vol"]
            min_vol_vector = self.sim.get_min_vol_vector(tank_idx)

            fsp_inflow_idx = self.sim.net.fsp.loc[self.sim.net.fsp['in'] == tank_idx].index.to_list()
            fsp_outflow_idx = self.sim.net.fsp.loc[self.sim.net.fsp['out'] == tank_idx].index.to_list()
            vsp_inflow_idx = self.sim.net.vsp.loc[self.sim.net.vsp['in'] == tank_idx].index.to_list()
            vsp_outflow_idx = self.sim.net.vsp.loc[self.sim.net.vsp['out'] == tank_idx].index.to_list()

            fsp_inflow = self.sim.net.fsp.loc[fsp_inflow_idx, 'flow'].values
            fsp_outflow = self.sim.net.fsp.loc[fsp_outflow_idx, 'flow'].values
            for t in range(self.sim.T):
                lhs = init_vol
                if fsp_inflow_idx:
                    lhs += fsp_inflow @ (self.x_fsp[fsp_inflow_idx, :t + 1]).sum(axis=1)
                if vsp_inflow_idx:
                    lhs += (self.x_vsp[vsp_inflow_idx, :t + 1]).sum()
                if fsp_outflow_idx:
                    lhs -= fsp_outflow @ (self.x_fsp[fsp_outflow_idx, :t + 1]).sum(axis=1)
                if vsp_outflow_idx:
                    lhs -= (self.x_vsp[vsp_outflow_idx, :t + 1]).sum()

                if self.sim.net.tanks.loc[tank_idx, "uncertain"] == 1:
                    lhs = lhs - ((self.delta * self.z[tank_idx - 1, :t + 1] + 1) * tank_demand[:t + 1]).sum()
                    self.model.st((lhs >= min_vol_vector[t]).forall(self.uset))
                    self.model.st((lhs <= max_vol).forall(self.uset))
                else:
                    lhs = lhs - (tank_demand[:t + 1]).sum()
                    self.model.st((lhs >= min_vol_vector[t]).forall(self.uset))
                    self.model.st((lhs <= max_vol).forall(self.uset))

    def vsp_initial_flow(self):
        for i, row in self.sim.net.vsp.iterrows():
            if np.isnan(row['init_flow']):
                continue
            else:
                self.model.st((self.x_vsp[i, 0] == row['init_flow']).forall(self.uset))

    def vsp_total_vol(self):
        for i, row in self.sim.net.vsp.iterrows():
            self.model.st((self.x_vsp[i, :].sum() >= row['min_vol']).forall(self.uset))
            self.model.st((self.x_vsp[i, :].sum() <= row['max_vol']).forall(self.uset))

    def vsp_flow_change(self):
        const_tariff = utils.get_constant_tariff_periods(self.sim.data['tariff']).astype(int)
        for i, row in self.sim.net.vsp.iterrows():
            if row['const_flow']:
                for j in range(max(const_tariff) + 1):
                    idx = np.where(const_tariff == j)[0]
                    mat = utils.get_mat_for_vsp_value_changes(self.sim.T, idx)
                    self.model.st((mat @ self.x_vsp[i, :].T == 0).forall(self.uset))
            else:
                continue

    def max_power(self):
        """
        This function is currently customized for Sopron network only
        The problem conditions are such that the only power constraint is
        Power Station D (Pump Stations 5 and 6) must be under 35 kW during the On-Peak periods
        The meaning is that Pump station 5 cannot be operated with 116 CMH (37.5 kW) during the ON-Peak periods
        """
        max_power_constr = pd.read_csv(os.path.join(self.sim.data_folder, 'max_power.csv'))
        for i, row in max_power_constr.iterrows():
            fsp_idx = self.sim.net.fsp.loc[self.sim.net.fsp['comb'] == row['comb']].index.values[0]
            mat = utils.get_mat_for_tariff(self.sim, tariff_name=row['tariff'])
            self.model.st((mat @ self.x_fsp[fsp_idx, :] == 0).forall(self.uset))

    def solve(self):
        self.model.solve(solver=grb, display=False)
        obj, status = self.model.solution.objval, self.model.solution.status
        x_fsp_nominal = self.x_fsp(self.z.assign(np.zeros(self.z.shape)))
        if self.x_vsp.shape[0] > 0:
            x_vsp_nominal = self.x_vsp(self.z.assign(np.zeros(self.z.shape)))
        else:
            x_vsp_nominal = None
        return obj, status, x_fsp_nominal, x_vsp_nominal

    def get_ldr_coefficients(self, export_path=''):
        """ extract the constant of the linear decision rule
            each decision variable is affine linear rule such as: pi0 + sum(pi_i * d_i) where i=1,2...t-1
            pi0 is a scalar, pi is a matrix with shape x_shape * n_adaption_steps (T) * n_adaption_elements (n_tanks)
            the function return a dictionary as follow:
            {'x_fsp': {'pi0': pi0, 'pi': pi}, 'x_vsp': {'pi0': pi0, 'pi': pi}}
        """
        pi0 = self.x_fsp.get()
        pi = self.x_fsp.get(self.z)
        pi[np.isnan(pi)] = 0
        ldr = {'x_fsp': {'pi0': pi0, 'pi': pi}}

        if self.x_vsp.shape[0] > 0:
            pi0 = self.x_vsp.get()
            pi = self.x_vsp.get(self.z)
            pi[np.isnan(pi)] = 0
            ldr['x_vsp'] = {'pi0': pi0, 'pi': pi}

        if export_path:
            utils.write_pkl(ldr, export_path)

        return pi0, pi