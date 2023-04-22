import os
import pandas as pd

from simulation import Simulation
from lp import LP


class MPC:
    def __init__(self, data_folder, start_hour, horizon, num_steps, actual_demands):
        self.data_folder = data_folder
        self.horizon = horizon
        self.num_steps = num_steps
        self.actual_demands = actual_demands
        self.t1 = start_hour
        self.t2 = self.t1 + horizon - 1

        self.results = {}
        self.sim = self.init_sim()

    def init_sim(self):
        return Simulation(self.data_folder, self.t1, self.t2)

    def run(self):
        for istep in range(self.num_steps):
            self.optimize()
            self.set_tanks_for_next_period()

    def optimize(self):
        lp = LP(self.sim)
        obj, status, x_fsp, x_vsp = lp.solve()

        tanks_volume = self.sim.get_all_tanks_vol(x_fsp, x_vsp)
        facilities_flows = self.sim.get_all_flows(x_fsp, x_vsp)
        self.results[self.t1] = {'objective': obj, 'status': status, 'x_fsp': x_fsp, 'x_vsp': x_vsp,
                                 'tanks_volume': tanks_volume, 'facilities_flows': facilities_flows}

    def set_tanks_for_next_period(self):
        for tank_idx, row in self.sim.net.tanks.iterrows():
            fsp_in = self.sim.net.fsp.loc[self.sim.net.fsp['in'] == tank_idx, 'name'].to_list()
            fsp_out = self.sim.net.fsp.loc[self.sim.net.fsp['out'] == tank_idx, 'name'].to_list()
            vsp_in = self.sim.net.vsp.loc[self.sim.net.vsp['in'] == tank_idx, 'name'].to_list()
            vsp_out = self.sim.net.vsp.loc[self.sim.net.vsp['out'] == tank_idx, 'name'].to_list()

            inflow = self.results[self.t1]['facilities_flows'][fsp_in + vsp_in].sum(axis=1).iloc[0]
            outflow = self.results[self.t1]['facilities_flows'][fsp_out + vsp_out].sum(axis=1).iloc[0]

            tank_consumer = self.sim.net.tanks.loc[tank_idx, 'demand']
            demand = self.actual_demands[tank_consumer].iloc[0]