import os
import pandas as pd
import numpy as np


def construct_demand_cov(sim):
    """
    Hourly cov matrix for all simulation consumers
    The cov matrix shape is T * n_tanks where every T block is the cov of the i consumer
    This structure allows to add correlation coefficients between time steps and between consumers
    """
    std = pd.read_csv(os.path.join(sim.data_folder, 'demands_std.csv'), index_col=0)
    all_std = std.values.flatten(order='F')

    cov = np.zeros((std.shape[0] * std.shape[1], std.shape[0] * std.shape[1]))
    np.fill_diagonal(cov, all_std)
    return cov


def construct_demand_cov_for_sample(sim, n=1):
    """
    Construct cov matrix for MPC optimization
    The basic cov matrix represent the hourly variance of each consumer
    The sample cov matrix is used to build sample for n days
    """
    demand_cov = construct_demand_cov(sim)
    m = demand_cov.shape[0]
    cov = np.zeros((demand_cov.shape[0] * n, demand_cov.shape[0] * n))

    for i in range(n):
        cov[i*m: (i+1)*m, i*m: (i+1)*m] = demand_cov

    return cov


def multivariate_sample(mean, cov, n):
    delta = np.linalg.cholesky(cov)
    z = np.random.normal(size=(n, len(mean)))
    x = mean + (z.dot(delta)).T
    return x