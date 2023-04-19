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