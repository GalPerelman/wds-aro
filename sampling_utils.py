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

    mat = np.zeros((std.shape[0] * std.shape[1], std.shape[0] * std.shape[1]))
    np.fill_diagonal(mat, all_std)
    cov = mat @ np.eye(std.shape[0] * std.shape[1]) @ mat
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
    """
    Construct gaussian (multivariate normal) sample based on mean and cov
    :param mean:    vector of nominal values (n_consumers * T, 1)
    :param cov:     cov matrix (n_consumers * T, n_consumers * T)
    :param n:       sample size
    :return:        sample matrix
    """
    m = len(mean)
    # check for 0 rows - certain entries (std=0)
    certain_idx = np.all(cov == 0, axis=1)
    uncertain_idx = np.logical_not(np.all(cov == 0, axis=1))

    # select only uncertain consumers
    cov = cov[uncertain_idx, :]
    cov = cov[:, uncertain_idx]
    mean = mean[uncertain_idx]

    delta = np.linalg.cholesky(cov)
    z = np.random.normal(size=(n, len(mean)))
    x = mean.reshape(-1, 1) * (1 + (z.dot(delta)).T)

    # restore certain entries
    sample = np.zeros((m, n))
    sample[np.argwhere(uncertain_idx)[:, 0], :] = x
    return sample


def decompose_sample(sample, sim):
    """
    Convert a single sample to a workable df
    The random sampling function returns a 1D very long vector as follows:
    [consumer-1-day-1, consumer-2-day-1 ... consumerN-day1,
    consumer-1-day-2, consumer-2-day-2 ... consumerN-day2,
    ...
    consumer-1-day-DD, consumer2-day-DD ... consumer-N-day-DD]

    The function returns a df with index corresponding to simulation time range where columns are consumers
    """
    df = pd.DataFrame()
    n = int(len(sample) / (sim.net.n_tanks * sim.T))
    for i in range(n):
        block = sample[i*sim.T*sim.net.n_tanks: (i+1)*sim.T*sim.net.n_tanks]
        block = block.reshape(sim.T, sim.net.n_tanks, order='F')
        df = pd.concat([df, pd.DataFrame(block, columns=sim.net.tanks.loc[:, 'demand'])], axis=0)

    df = df.rename_axis(None, axis=1)
    df.reset_index(inplace=True, names=['hr'])
    return df