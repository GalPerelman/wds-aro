import numpy as np


def get_mat_for_vsp_value_changes(n, valid_idx):
    valid_idx = valid_idx[1:]
    mat = np.eye(n)
    rows, cols = np.indices((n, n))
    row_vals = np.diag(rows, k=-1)
    col_vals = np.diag(cols, k=-1)
    mat[row_vals, col_vals] = -1
    mat[0, 0] = 0

    mask = np.zeros((n, 1))
    mask[valid_idx] = 1
    mat = np.multiply(mat, mask)
    return mat


def get_constant_tariff_periods(tariff):
    diff = np.roll(tariff, 1) - tariff
    const_idx = np.zeros(diff.shape)
    const_idx[diff != 0.0] = 1
    const_idx = const_idx.cumsum()
    return const_idx


def get_mat_for_tariff(sim, tariff_name):
    """
    generates an eye matrix with ones only in the rows of requested tariff
    by multiplying the variables vector we will get the entries that corresponds to the tariff periods
    [[0, 0, 0..   OFF
     [0, 1, 0..   ON
     [0, 0, 0..]] OFF
    """
    mat = np.eye(sim.T)
    tariffs = sim.data['name'].values
    mask = np.where(tariffs == tariff_name, 1, 0)
    mat = np.multiply(mat, mask[:, np.newaxis])
    return mat
