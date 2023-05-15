import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib import ticker as mtick
from typing import Iterable
import simulation


def plot_all_tanks(nrows: int, ncols: int, sim: simulation.Simulation, x_fsp: np.ndarray, x_vsp: np.ndarray):
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols)
    axes = axes.ravel()
    for i, ax in enumerate(axes):
        vol = sim.get_tank_vol(i + 1, x_fsp, x_vsp)
        axes[i].plot(vol)

        min_vol_vector = sim.get_min_vol_vector(i + 1)
        axes[i].plot(min_vol_vector, "k", linestyle="--")
        axes[i].hlines(sim.net.tanks.loc[i + 1, "max_vol"], 0, 23, "k", linestyles="--")

        axes[i].grid()
        axes[i].set_title(f'Tank {i + 1}')

    fig.tight_layout()
    return fig


def plot_all_vsp(nrows: int, ncols: int, x_vsp: np.ndarray):
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols)
    axes = axes.ravel()
    for i in range(x_vsp.shape[0]):
        axes[i].plot(x_vsp[i, :])
        axes[i].grid()
        axes[i].set_title(f'VSP {i + 1}')

    fig.tight_layout()
    return fig


def plot_all_fsp(nrows: int, ncols: int, x_fsp: np.ndarray):
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols)
    axes = axes.ravel()
    for i in range(x_fsp.shape[0]):
        axes[i].step(range(len(x_fsp[i, :])), x_fsp[i, :], where='post')
        axes[i].grid()
        axes[i].set_title(f'FSP {i + 1}')

    return fig


def plot_monte_carlo_histogram(values: Iterable):
    fig, ax = plt.subplots()
    ax.hist(values, bins=20, alpha=0.6, edgecolor='k')
    return ax


def correlation_matrix(mat: np.ndarray, major_ticks: bool = False, norm: bool = False, cmap_name: str = 'Blues'):
    if norm:
        mat = (mat - mat.min()) / (mat.max() - mat.min())

    cmap = plt.get_cmap(cmap_name)
    mat_norm = max(abs(mat.min()), abs(mat.max()))
    im = plt.imshow(mat, cmap=cmap, vmin=0, vmax=mat_norm)
    ax = plt.gca()

    ax.tick_params(which='minor', bottom=False, left=False)
    cbar = plt.colorbar(im, ticks=mtick.AutoLocator())

    # Major ticks
    if major_ticks:
        ax.set_xticks(np.arange(-0.5, mat.shape[0], major_ticks))
        ax.set_yticks(np.arange(-0.5, mat.shape[0], major_ticks))
        ax.set_xticklabels(np.arange(0, mat.shape[0] + major_ticks, major_ticks))
        ax.set_yticklabels(np.arange(0, mat.shape[0] + major_ticks, major_ticks))
        ax.grid(which='major', color='k', linestyle='-', linewidth=1)

    # Grid lines based on minor ticks
    ax.grid(which='minor', color='k', linestyle='-', linewidth=0.5, alpha=0.4)
    ax.set_xticks(np.arange(-0.5, mat.shape[0], 1), minor=True)
    ax.set_yticks(np.arange(-0.5, mat.shape[0], 1), minor=True)

    plt.subplots_adjust(top=0.9, bottom=0.13, left=0.055, right=0.9, hspace=0.2, wspace=0.2)


def plot_price_of_robustness(por_path: str, omega: float):
    df = pd.read_csv(por_path, index_col=0)
    deterministic = df.loc[df['sigma'] == 0, 'nom']

    df = df.loc[(df['omega'] == omega) & (df['sigma'] > 0)]

    fig, ax = plt.subplots()
    ax.hlines(deterministic, df['sigma'].min(), df['sigma'].max(), colors='k', linestyle='--', label='Deterministic')
    ax.plot(df['sigma'], df['nom'], marker='o',  mfc='white', label='ARO')
    ax.plot(df['sigma'], df['wc'], marker='o', mfc='white', label='RO')

    props = dict(boxstyle='round', facecolor='white', alpha=0.4, edgecolor='none')
    df['improve'] = 100 * (df['wc'] - df['nom']) / df['nom']
    for i, (sigma, nom) in enumerate(zip(df['sigma'], df['nom'])):
        text_str = f"{df['improve'].iloc[i]:.1f}%"
        ax.text(x=sigma-(sigma-0.05)/20, y=nom+10, s=text_str, bbox=props)

    ax.xaxis.set_major_formatter(mtick.FormatStrFormatter('%.2f'))
    ax.xaxis.set_major_locator(mtick.MultipleLocator(0.05))

    ax.set_xlabel('Level of uncertainty (%)')
    ax.set_ylabel('Energy Cost (€)')
    ax.grid()
    ax.legend()

