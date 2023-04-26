import numpy as np
import pickle


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


def write_pkl(data, export_path):
    with open(export_path, 'wb') as f:
        pickle.dump(data, f)


def read_pkl(pkl_path):
    with open(pkl_path, 'rb') as f:
        data = pickle.load(f)
        return data


def extract_values_from_ldr(pi0, pi, sample):
    pi = np.multiply(pi, sample)
    for _ in range(len(pi.shape) - len(pi0.shape)):
        pi = pi.sum(axis=-1)

    return pi0 + pi


def get_all_variables_from_pkl(pkl_path, sample):
    ldr = read_pkl(pkl_path)

    all_vars = {}
    for var_name, var_ldr in ldr.items():
        x = extract_values_from_ldr(ldr[var_name]['pi0'], ldr[var_name]['pi'], sample=sample)
        all_vars[var_name] = x

    return all_vars
