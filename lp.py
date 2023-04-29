import os.path

import numpy as np
import pandas as pd
from rsome import ro
from rsome import grb_solver as grb

import utils


class LP:
    def __init__(self, sim):
        self.sim = sim
        self.model = ro.Model()
        self.x_fsp = self.model.dvar((len(self.sim.net.fsp), self.sim.T))
        self.x_vsp = self.model.dvar((len(self.sim.net.vsp), self.sim.T))
        self.build()

    def build(self):
        self.range_constraints()
        self.one_comb_only()
        self.mass_balance()
        self.vsp_initial_flow()
        self.vsp_total_vol()
        self.vsp_flow_change()
        self.max_power()
        self.obj_function()

    def range_constraints(self):
        self.model.st(0 <= self.x_fsp)
        self.model.st(self.x_fsp <= 1)

        for i, row in self.sim.net.vsp.iterrows():
            max_flow = row['max_flow']
            min_flow = row['min_flow']
            self.model.st(min_flow <= self.x_vsp[i, :])
            self.model.st(self.x_vsp[i, :] <= max_flow)

    def obj_function(self):
        obj_func = sum(self.sim.net.fsp.loc[:, "power"].values @ self.x_fsp * self.sim.data.loc[:, "tariff"].values)
        self.model.min(obj_func)

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

                lhs = lhs - (tank_demand[:t + 1]).sum()
                self.model.st(lhs >= min_vol_vector[t])
                self.model.st(lhs <= max_vol)

    def vsp_initial_flow(self):
        hour_of_the_day = self.sim.t1 % 24
        for i, row in self.sim.net.vsp.iterrows():
            if np.isnan(row['init_flow']):
                continue
            elif hour_of_the_day in [7, 13, 17, 20]:
                # In case that simulation start at time when tariff is change from previous hour
                # The initial vsp flow can be changed according to the vsp_flow_change_policy
                # usually simulation starts at time 0 but this modification is required for MPC (folding horizon runs)
                # This is a temporary (not general) solution.
                # The hours when tariff is changing should be extracted from the data
                continue
            else:
                self.model.st(self.x_vsp[i, 0] == row['init_flow'])

    def vsp_total_vol(self, daily=False):
        for i, row in self.sim.net.vsp.iterrows():
            if daily:
                # If total volume is daily (until day ends)
                start_hr = self.sim.t1
                day_end_hr = ((start_hr // 24) + 1) * 24
                self.model.st(self.x_vsp[i, :(day_end_hr - start_hr)].sum() + row['cumm_vol'] >= row['min_vol'])
                self.model.st(self.x_vsp[i, :(day_end_hr - start_hr)].sum() + row['cumm_vol'] <= row['max_vol'])
            else:
                # If total volume is for any 24 hours cycle
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

