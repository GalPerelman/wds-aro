
import utils
from simulation import Simulation
from lp import LP


class MPC:
    def __init__(self, data_folder, t1, horizon, n_steps, actual_demands, ignore_first_day, step_size=1, export_path=''):
        self.data_folder = data_folder
        self.t1 = t1
        self.t2 = self.t1 + horizon - 1
        self.horizon = horizon
        self.n_steps = n_steps
        self.actual_demands = actual_demands
        self.ignore_first_day = ignore_first_day
        self.step_size = step_size
        self.export_path = export_path

        self.results = {}
        self.cost_record = []
        self.sim = self.init_sim()

    def init_sim(self):
        return Simulation(self.data_folder, self.t1, self.t2)

    def run(self):
        for istep in range(self.n_steps):
            self.optimize()
            # get previous step initial volumes
            prev_init_volumes = self.sim.net.tanks.loc[:, 'init_vol']
            # go forward - set new t1, t2
            self.forward()
            # init new simulation - load electricity tariffs and nominal demands
            self.sim = self.init_sim()
            # set the tank level for the new sim
            self.set_tanks_for_next_period(prev_init_volumes)

        if self.export_path:
            self.export_all_results()

        if self.ignore_first_day:
            s = 24
        else:
            s = 0
        return sum(self.cost_record[-s:])

    def optimize(self):
        lp = LP(self.sim)
        obj, status, x_fsp, x_vsp = lp.solve()

        tanks_volume = self.sim.get_all_tanks_vol(x_fsp, x_vsp)
        facilities_flows = self.sim.get_facilities_flows(x_fsp, x_vsp)
        self.results[self.t1] = {'objective': obj, 'status': status, 'x_fsp': x_fsp, 'x_vsp': x_vsp,
                                 'tanks_volume': tanks_volume, 'facilities_flows': facilities_flows}

        self.cost_record.append(self.get_last_step_cost(x_fsp))

    def set_tanks_for_next_period(self, prev_init_volumes):
        last_step = self.get_last_step()
        for tank_idx, row in self.sim.net.tanks.iterrows():
            fsp_in = self.sim.net.fsp.loc[self.sim.net.fsp['in'] == tank_idx, 'name'].unique().tolist()
            fsp_out = self.sim.net.fsp.loc[self.sim.net.fsp['out'] == tank_idx, 'name'].unique().tolist()
            vsp_in = self.sim.net.vsp.loc[self.sim.net.vsp['in'] == tank_idx, 'name'].unique().tolist()
            vsp_out = self.sim.net.vsp.loc[self.sim.net.vsp['out'] == tank_idx, 'name'].unique().tolist()

            inflow = self.results[last_step]['facilities_flows'][fsp_in + vsp_in].sum(axis=1).iloc[0]
            outflow = self.results[last_step]['facilities_flows'][fsp_out + vsp_out].sum(axis=1).iloc[0]

            tank_consumer = self.sim.net.tanks.loc[tank_idx, 'demand']
            demand = self.actual_demands[tank_consumer].loc[last_step]
            tank_init_vol = prev_init_volumes[tank_idx]
            next_period_init_vol = tank_init_vol + inflow - outflow - demand
            self.sim.net.tanks.loc[tank_idx, 'init_vol'] = next_period_init_vol
            # self.sim.net.tanks.loc[tank_idx, 'final_vol'] = next_period_init_vol

    def forward(self):
        self.t1 += self.step_size
        self.t2 = self.t1 + self.horizon - 1

    def get_last_step(self):
        return max(self.results.keys())

    def get_last_step_cost(self, x_fsp):
        power = self.sim.net.fsp.loc[:, "power"].values
        tariff = self.sim.data.loc[self.t1, 'tariff']
        cost = power @ x_fsp[:, 0] * tariff
        return cost

    def export_all_results(self):
        utils.write_pkl(self.results, self.export_path)
