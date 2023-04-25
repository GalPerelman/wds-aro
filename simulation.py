import os
import numpy as np
import pandas as pd

from network import Network


class Simulation:
    def __init__(self, data_folder, t1, t2):
        self.data_folder = data_folder
        self.t1 = t1
        self.t2 = t2

        self.net = Network(data_folder)
        self.time_range = np.arange(t1, t2+1, 1)
        self.T = len(self.time_range)

        self.elec = pd.read_csv(os.path.join(data_folder, 'tariffs.csv'))
        self.demands = pd.read_csv(os.path.join(data_folder, 'demands.csv'))
        self.data = self.build()
        self.n_comb_facilities = len(self.net.fsp['name'].unique())

    def build(self):
        df = pd.DataFrame(index=self.time_range)
        df['hour'] = df.index.to_series() % self.T
        df = pd.merge(df, self.elec, left_on='hour', right_on='time', how='inner').drop('time', axis=1)
        df = pd.merge(df, self.demands, left_on='hour', right_on='time', how='inner').drop('time', axis=1)
        df.index = self.time_range
        return df

    def get_total_max_inflow(self, tank_idx):
        fsp_inflows = self.net.fsp.loc[self.net.fsp['in'] == tank_idx, :]
        max_fsp_inflow = fsp_inflows[['name', 'flow']].groupby('name').max()
        total_max_fsp_inflow = max_fsp_inflow['flow'].sum()

        vsp_inflows = self.net.vsp.loc[self.net.vsp['in'] == tank_idx, :]
        max_vsp_inflow = vsp_inflows[['name', 'max_flow']].groupby('name').max()
        total_max_vsp_inflow = max_vsp_inflow['max_flow'].sum()

        return total_max_fsp_inflow + total_max_vsp_inflow

    def get_tank_demand(self, tank_idx):
        tank_consumer = self.net.tanks.loc[tank_idx, "demand"]
        return self.data[tank_consumer]

    def get_min_vol_vector(self, tank_idx, is_dynamic=True):
        static_min_vol = self.net.tanks.loc[tank_idx, "min_vol"]
        final_vol = self.net.tanks.loc[tank_idx, "final_vol"]
        if not is_dynamic:
            min_vol = static_min_vol * np.ones(self.T, 1)
        else:
            q_max = self.get_total_max_inflow(tank_idx)
            demand = self.get_tank_demand(tank_idx)
            dynamic_min = [final_vol]
            for i, t in enumerate(self.time_range[::-1]):
                dynamic_min = [max(static_min_vol, dynamic_min[0] + demand.loc[t] - q_max)] + dynamic_min

            min_vol = dynamic_min[1:]
        return min_vol

    def get_tank_vol(self, tank_idx, x_fsp, x_vsp):
        mat = np.tril(np.ones((self.T, self.T)))
        tank_consumer = self.net.tanks.loc[tank_idx, 'demand']
        cum_tank_demand = self.data[tank_consumer].values.cumsum()
        lhs = self.net.tanks.loc[tank_idx, "init_vol"]

        for fsp_idx, row_fsp in self.net.fsp.iterrows():
            if row_fsp['in'] == tank_idx:
                lhs += row_fsp['flow'] * mat @ x_fsp[fsp_idx, :].T
            elif row_fsp['out'] == tank_idx:
                lhs += -1 * row_fsp['flow'] * mat @ x_fsp[fsp_idx, :].T
            else:
                continue

        for vsp_idx, row_vsp in self.net.vsp.iterrows():
            if row_vsp['in'] == tank_idx:
                lhs += mat @ x_vsp[vsp_idx, :].T
            elif row_vsp['out'] == tank_idx:
                lhs += -1 * mat @ x_vsp[vsp_idx, :].T
            else:
                continue

        vol = lhs - cum_tank_demand
        return vol

    def get_all_tanks_vol(self, x_fsp, x_vsp):
        df = pd.DataFrame()
        for tank_idx, row in self.net.tanks.iterrows():
            vol = self.get_tank_vol(tank_idx, x_fsp, x_vsp)
            df = pd.concat([df, pd.DataFrame({tank_idx: vol}, index=self.time_range)], axis=1)
        return df

    def get_facilities_flows(self, x_fsp, x_vsp):
        df = pd.DataFrame()
        for facility in self.net.fsp['name'].unique():
            facility_idx = self.net.fsp.loc[self.net.fsp['name'] == facility].index
            flows = self.net.fsp.loc[facility_idx, 'flow'].values
            facility_flow = (x_fsp[facility_idx, :] * flows[:, np.newaxis]).sum(axis=0)
            df = pd.concat([df, pd.DataFrame({facility: facility_flow}, index=self.time_range)], axis=1)

        for i, row in self.net.vsp.iterrows():
            df = pd.concat([df, pd.DataFrame({row['name']: x_vsp[i, :]}, index=self.time_range)], axis=1)

        return df

    def get_cost(self, x):
        power = self.net.fsp.loc[:, "power"].values
        power = power @ x

        cost = power * self.data.loc[:, "tariff"].values
        return cost

    def get_nominal_demands(self):
        consumers = self.net.tanks['demand']
        demands = self.data[consumers]
        demands = demands.values.flatten("F")
        return demands


