import os
import pandas as pd
import numpy as np


class Network:
    def __init__(self, data_folder):
        self.data_folder = data_folder

        self.fsp = pd.read_csv(os.path.join(self.data_folder, 'fsp.csv'))
        self.vsp = pd.read_csv(os.path.join(self.data_folder, 'vsp.csv'))
        self.tanks = pd.read_csv(os.path.join(self.data_folder, 'tanks.csv'), index_col='tank')

        self.n_fsp = len(self.fsp)
        self.n_vsp = len(self.vsp)
        self.n_tanks = len(self.tanks)

        self.fsp_names = self.fsp.loc[:, 'name']
        self.vsp_names = self.vsp.loc[:, 'name']

    @staticmethod
    def get_cumulative_mat(n, multiplier):
        """ multiplier can be flow direction 1 or -1 """
        return np.tril(np.ones((n, n))) * multiplier