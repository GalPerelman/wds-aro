import os
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import time

import utils
from simulation import Simulation
import sampling_utils as smp
import uncertainty_utils as unc
from lp import LP
from mpc import MPC
import graphs
import opt


def price_of_robustness(sim, export_dir='', uset=2):
    df = pd.DataFrame()
    for omega in [1, 2, 3]:
        infeasible_flag = False  # to skip infeasible cases to reduce run times
        for sigma in [0, 0.05, 0.1, 0.15, 0.2, 0.25]:
            unc_set = unc.construct_uset(sim, sigma)
            # get worst-case: RO
            wc, status, x_fsp, x_vsp = opt.RO(sim, uset_type=uset, omega=omega, mapping_mat=unc_set.delta).solve()

            # get nominal adjustable solution: ARO
            if not infeasible_flag:
                aro = opt.ARO(sim, uset_type=uset, omega=omega, mapping_mat=unc_set.delta, worst_case=False)
                nom, status, x_fsp, x_vsp = aro.solve()
                # export ARO solution
                aro.get_ldr_coefficients(export_path=os.path.join(export_dir, f'ldr-omega-{omega}-sigma-{sigma}.pkl'))

                if status is None:
                    infeasible_flag = True

            # record results
            temp = pd.DataFrame({'uset': uset, 'omega': omega, 'sigma': sigma, 'nom': nom, 'wc': wc}, index=[len(df)])
            df = pd.concat([df, temp])
            print(df)

    if export_dir:
        df.to_csv(os.path.join(export_dir, f'por.csv'))


def get_sample(sim, n_days, n_sample, sigma=False, plot=False):
    nominal = np.tile(sim.get_nominal_demands(flatten=True), n_days)
    cov = smp.construct_demand_cov_for_sample(sim, n_days, sigma)
    sample = smp.multivariate_sample(mean=nominal, cov=cov, n=n_sample)
    if plot:
        plt.plot(sample, c='C0', alpha=0.3)
        plt.plot(nominal, c='k')
        plt.grid()
        plt.show()
    return sample


def monte_carlo_mpc(sim, n_days, n_sample, horizon, n_steps, ignore_n_hr, final_vol_constraint, opt_params,
                    export_path=''):
    costs = []
    sample = get_sample(sim, n_days, n_sample)
    for i in range(n_sample):
        single_sample = smp.decompose_sample(sample[:, i], sim)
        mpc = MPC(sim.data_folder,
                  t1=0,
                  horizon=horizon,
                  n_steps=n_steps,
                  actual_demands=single_sample,
                  ignore_n_hr=ignore_n_hr,
                  opt_params=opt_params,
                  final_vol_constraint=final_vol_constraint,
                  )

        cost = mpc.run()
        print(f'{i} --- {cost}')
        costs.append(cost)

    if export_path:
        df = pd.DataFrame({'cost': costs})
        df.to_csv(export_path)

    return costs


def monte_carlo_aro(sim, ldr_path, n_sample, export_path=''):
    n_days = int((sim.t2 - sim.t1) // 24) + 1
    nominal = np.tile(sim.get_nominal_demands(flatten=True), n_days)
    sample = get_sample(sim, n_days, n_sample)

    costs = []
    for i in range(n_sample):
        single_sample = smp.decompose_sample(sample[:, i], sim)
        single_sample = single_sample.drop('hr', axis=1).values
        nominal = sim.get_nominal_demands()  # .reshape(-1, n_days * 24).T

        # only divide non zeros else 0
        zeros = np.zeros(single_sample.shape)
        single_sample_perturbations = np.divide(single_sample - nominal, nominal, out=zeros, where=nominal != 0)
        all_vars = utils.get_all_variables_from_pkl(ldr_path, single_sample_perturbations)

        x_fsp = all_vars['x_fsp']
        cost = sim.get_cost(x_fsp)
        costs.append(sum(cost))

    if export_path:
        df = pd.DataFrame({'cost': costs})
        df.to_csv(export_path)

    return costs


def latency_analysis(sim, sigmas, latencies, export_path=''):
    df = pd.DataFrame()
    for sigma in sigmas:
        for l in latencies:
            unc_set = unc.construct_uset(sim, sigma)

            # get nominal adjustable solution: ARO
            aro = opt.ARO(sim, uset_type=2, omega=1, mapping_mat=unc_set.delta, worst_case=False, latency=l)
            nom, status, x_fsp, x_vsp = aro.solve()

            # record results
            temp = pd.DataFrame({'uset': 2, 'omega': 1, 'sigma': sigma, 'latency': l, 'nom': nom}, index=[len(df)])
            df = pd.concat([df, temp])

    if export_path:
        df.to_csv(export_path)


if __name__ == "__main__":
    np.random.seed(42)
    sim_pw = Simulation('data/pump-well', 0, 23)
    sim_sopron = Simulation('data/sopron', 0, 23)

    """ Base results - price of robustness """
    # price_of_robustness(sim_pw, os.path.join('output', 'pump-well-ellipsoid'), uset=2)      # pump-well Ellipsoid
    # price_of_robustness(sim_pw, os.path.join('output', 'pump-well-box'), uset=np.inf)       # pump-well Box
    # price_of_robustness(sim_sopron, os.path.join('output', 'sopron-ellipsoid'), uset=2)   # sopron Ellipsoid
    # price_of_robustness(sim_sopron, os.path.join('output', 'sopron-box'), uset=np.inf)           # sopron Box

    """ Deterministic folding horizon (MPC) - Monte Carlo """
    # export_path = os.path.join('output', 'pump-well-ellipsoid', 'mpc.csv')
    # opt_params = {'method': 'LP'}
    # costs = monte_carlo_mpc(sim_pw, n_days=2, n_sample=1000, horizon=24, n_steps=48, ignore_n_hr=24,
    #                         final_vol_constraint=True, opt_params=opt_params, export_path=False)
    # graphs.plot_monte_carlo_histogram(costs)

    # export_path = os.path.join('output', 'sopron-ellipsoid', 'mpc.csv')
    # opt_params = {'method': 'LP'}
    # costs = monte_carlo_mpc(sim_sopron, n_days=2, n_sample=1000, horizon=48, n_steps=24, ignore_n_hr=0,
    #                         final_vol_constraint=False, opt_params=opt_params, export_path='export_path')
    # df = pd.read_csv(os.path.join('output', 'sopron', 'mpc.csv'))
    # graphs.plot_monte_carlo_histogram(df['cost'])

    """ Robust folding horizon (MPC) - Monte Carlo """
    # export_path = os.path.join('output', 'pump-well-ellipsoid', 'ro-mpc.csv')
    # opt_params = {'method': 'RO', 'set_type': 2, 'omega': 1, 'sigma': 0.1}
    # costs = monte_carlo_mpc(sim_pw, n_days=2, n_sample=1000, horizon=24, n_steps=48, ignore_n_hr=24,
    #                         final_vol_constraint=True, opt_params=opt_params, export_path=export_path)

    # export_path = os.path.join('output', 'sopron-ellipsoid', 'ro-mpc.csv')
    # opt_params = {'method': 'RO', 'set_type': 2, 'omega': 1, 'sigma': 0.1}
    # costs = monte_carlo_mpc(sim_sopron, n_days=2, n_sample=1000, horizon=24, n_steps=24, ignore_n_hr=0,
    #                         final_vol_constraint=False, opt_params=opt_params, export_path=export_path)

    """ ARO - Monte Carlo  """
    # costs = monte_carlo_aro(sim_pw, ldr_path='output/pump-well-ellipsoid/ldr-omega-1-sigma-0.1.pkl', n_sample=1000,
    #                         export_path='output/pump-well-ellipsoid/aro-mc.csv')
    # graphs.plot_monte_carlo_histogram(costs)
    # costs = monte_carlo_aro(sim_sopron, 'output/sopron-ellipsoid/ldr-omega-1-sigma-0.1.pkl', n_sample=1000,
    #                         export_path='output/sopron-ellipsoid/aro-mc.csv')
    # graphs.plot_monte_carlo_histogram(costs)

    """ latency sensitivity analysis """
    # latency_analysis(sim_pw, sigmas=[0.05, 0.1, 0.15, 0.2, 0.25], latencies=[_ for _ in range(23)],
    #                  export_path='output/pump-well-ellipsoid/latency.csv')

    """ plots """
    # graphs.plot_price_of_robustness('output/pump-well-ellipsoid/por.csv', omega=1)
    # graphs.plot_multi_histograms({"MPC-LP": "output/pump-well-ellipsoid/mpc.csv",
    #                               "MPC-RO": "output/pump-well-ellipsoid/ro-mpc.csv",
    #                               "ARO": "output/pump-well-ellipsoid/aro-mc.csv"},
    #                              export_path='pump-well-hist.png')
    # graphs.plot_multi_histograms({"MPC-LP": "output/sopron-ellipsoid/mpc.csv",
    #                               "MPC-RO": "output/sopron-ellipsoid/ro-mpc.csv",
    #                               "ARO": "output/sopron-ellipsoid/aro-mc.csv"},
    #                              export_path='sopron-hist.png')
    # graphs.latency_analysis('output/pump-well-ellipsoid/latency.csv')

    
    plt.show()
