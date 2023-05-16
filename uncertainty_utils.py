import os

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from typing import Union

import graphs


class Constructor:
    def __init__(self, t, n, std, corr_type, temporal_rho, spatial_rho):
        self.t = t
        self.n = n
        self.std = std
        self.corr_type = corr_type
        self.temporal_rho = temporal_rho
        self.spatial_rho = spatial_rho

        self.corr_mat = self.build_corr_mat()
        self.cov = self.build_cov()
        self.delta = self.cov_to_mapping()

    def build_corr_mat(self):
        if self.corr_type == 'decline':
            mat = decline_correlation_mat(self.t, self.temporal_rho)
        elif self.corr_type == 'constant':
            mat = constant_correlation_mat(self.t, self.temporal_rho)
        return mat

    def build_cov(self, force_pd=True):
        mat = np.zeros((self.t * self.n, self.t * self.n))
        for i, std_i in enumerate(self.std.T):
            consumer_cov = get_cov_from_std(std_i, self.corr_mat)
            mat[i * self.t: i * self.t + self.t, i * self.t: i * self.t + self.t] = consumer_cov
            for j, std_j in enumerate(self.std.T):
                if j == i:
                    continue
                else:
                    # correlation between elements - only at same time steps
                    np.fill_diagonal(mat[i * self.t: i * self.t + self.t, j * self.t: j * self.t + self.t],
                                     np.multiply(std_i, std_j) * self.spatial_rho)

        if force_pd and not is_pd(mat):
            mat = nearest_positive_defined(mat)

        return mat

    def cov_to_mapping(self):
        if not is_pd(self.cov):
            print(f'Warning: COV matrix not positive defined')
            cov = nearest_positive_defined(self.cov)
        else:
            cov = self.cov

        mat = np.linalg.cholesky(cov)
        return mat


def nearest_positive_defined(mat):
    """
    source: https://stackoverflow.com/questions/43238173/python-convert-matrix-to-positive-semi-definite
    """
    b = (mat + mat.T) / 2
    _, s, v = np.linalg.svd(b)

    h = np.dot(v.T, np.dot(np.diag(s), v))
    mat2 = (b + h) / 2
    mat3 = (mat2 + mat2.T) / 2
    if is_pd(mat3):
        return mat3

    spacing = np.spacing(np.linalg.norm(mat))
    k = 1
    while not is_pd(mat3):
        mineig = np.min(np.real(np.linalg.eigvals(mat3)))
        mat3 += np.eye(mat.shape[0]) * (-mineig * k**2 + spacing)
        k += 1

    return mat3


def is_pd(mat):
    """
    Returns true when input is positive-definite, via Cholesky
    source: https://stackoverflow.com/questions/43238173/python-convert-matrix-to-positive-semi-definite
    """
    try:
        _ = np.linalg.cholesky(mat)
        return True
    except np.linalg.LinAlgError:
        return False


def get_cov_from_std(std, rho):
    n = len(std)
    sigma = np.zeros((n, n))
    np.fill_diagonal(sigma, std)

    if isinstance(rho, (int, float)):
        corr = constant_correlation_mat(n, rho)
    elif isinstance(rho, np.ndarray):
        corr = rho

    cov = sigma @ corr @ sigma
    return cov


def constant_correlation_mat(size, rho):
    mat = np.ones((size, size)) * rho
    diag = np.diag_indices(size)
    mat[diag] = 1.
    return mat


def decline_correlation_mat(size, rho):
    mat = np.zeros((size, size))
    for i in range(size):
        for j in range(size - i):
            if rho == 0:
                rr = 0
            else:
                rr = np.exp(- j * rho)  # Exponential decline

            mat[i, i + j] = rr
            mat[j + i, i] = rr

    np.fill_diagonal(mat, 1)
    return mat


def construct_uset(sim, sigma):
    nominal_demands = sim.get_nominal_demands(flatten=False)
    std_as_percentage = np.full((24, 1), sigma)
    std = nominal_demands * std_as_percentage
    unc_set = Constructor(t=nominal_demands.shape[0], n=nominal_demands.shape[1], std=std,
                              corr_type='decline', temporal_rho=0.6, spatial_rho=0.8)
    return unc_set


if __name__ == "__main__":
    """ sopron example """
    std_as_percentage = pd.read_csv('data/sopron/demands_std.csv', index_col=0).iloc[:24].values
    nom = pd.read_csv('data/sopron/demands.csv', index_col=0).iloc[:24].values
    std = nom * std_as_percentage
    uset = Constructor(t=nom.shape[0], n=nom.shape[1], std=std, corr_type='decline', temporal_rho=0.4, spatial_rho=0.8)
    cov = nearest_positive_defined(uset.cov)






# def build_cov_from_std(std, rho: Union[int, float, np.array] = 0):
#     n = len(std)
#     sigma = np.zeros((n, n))
#     np.fill_diagonal(sigma, std)
#
#     corr_mat = get_temporal_correlation_mat(len(std), rho)
#     cov = sigma @ corr_mat @ sigma
#     return cov
#
#
# def constant_correlation_mat(size, rho):
#     mat = np.ones((size, size)) * rho
#     diag = np.diag_indices(size)
#     mat[diag] = 1.
#     return mat
#
#
# def get_corr_matrix(size, rho=None):
#     if isinstance(rho, float):
#         return constant_correlation_mat(len(self.elements), self.elements_correlation)
#     elif isinstance(self.elements_correlation, np.ndarray):
#         if not validate_symmetric(self.elements_correlation):
#             raise Exception("Correlation matrix is not symmetric")
#         else:
#             return self.elements_correlation
#     if self.elements_correlation is None:
#         return np.zeros((len(self.elements), len(self.elements)))
