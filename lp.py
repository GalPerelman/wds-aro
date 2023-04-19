import os
import pandas as pd
import numpy as np

from rsome import ro
import rsome as rso
from rsome import grb_solver as grb


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
        facilities = self.sim.net.fsp['facility'].unique()
        for i in range(len(facilities)):
            mat = np.zeros(len(self.sim.net.fsp))
            facility_idx = self.sim.net.fsp.loc[self.sim.net.fsp.facility == facilities[i]].index.values
            mat[facility_idx] = 1
            self.model.st((mat @ self.x_fsp).T <= np.ones((24, 1)))

    def mass_balance(self):
        for tank_idx, tank_row in self.sim.net.tanks.iterrows():
            lhs = tank_row["init_vol"]
            for j, fsp_row in self.sim.net.fsp.iterrows():
                if fsp_row["in"] == tank_idx:
                    mat = self.sim.net.get_cumulative_mat(self.sim.T, 1)
                    flow = fsp_row['flow']
                    lhs += flow * self.x_fsp[j, :] @ mat
                elif fsp_row["out"] == tank_idx:
                    mat = self.sim.net.get_cumulative_mat(self.sim.T, -1)
                    flow = fsp_row['flow']
                    lhs += flow * self.x_fsp[j, :] @ mat
                else:
                    continue

            for j, vsp_row in self.sim.net.vsp.iterrows():
                if vsp_row["in"] == tank_idx:
                    mat = self.sim.net.get_cumulative_mat(self.sim.T, 1)
                    lhs += self.x_vsp[j, :] @ mat
                elif vsp_row["out"] == tank_idx:
                    mat = self.sim.net.get_cumulative_mat(self.sim.T, -1)
                    lhs += self.x_vsp[j, :] @ mat
                else:
                    continue

            tank_consumer = self.sim.net.tanks.loc[tank_idx, 'demand']
            tank_demand = self.sim.data[tank_consumer] * 0.2
            mat = self.sim.net.get_cumulative_mat(self.sim.T, 1)
            cum_demand = mat @ tank_demand.values
            min_vol_vector = self.sim.get_min_vol_vector(tank_idx, 1)
            self.model.st(lhs >= min_vol_vector + cum_demand)
            self.model.st(lhs <= self.sim.net.tanks.loc[tank_idx, "max_vol"] + cum_demand)

    def solve(self):
        self.model.solve(solver=grb, display=False)
        obj, x, status = self.model.solution.objval, self.model.solution.x, self.model.solution.status
        print(status, obj)
        print(len(x))

