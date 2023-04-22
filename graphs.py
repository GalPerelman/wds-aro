import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import ticker as mtick


def plot_all_tanks(nrows, ncols, sim, x_fsp, x_vsp):
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


def plot_all_vsp(nrows, ncols, x_vsp):
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols)
    axes = axes.ravel()
    for i in range(x_vsp.shape[0]):
        axes[i].plot(x_vsp[i, :])
        axes[i].grid()
        axes[i].set_title(f'VSP {i + 1}')

    fig.tight_layout()
    return fig


def plot_all_fsp(nrows, ncols, x_fsp):
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols)
    axes = axes.ravel()
    for i in range(x_fsp.shape[0]):
        axes[i].plot(x_fsp[i, :])
        axes[i].grid()
        axes[i].set_title(f'FSP {i + 1}')

    return fig


def correlation_matrix(mat, major_ticks=False, norm=False):
    if norm:
        mat = (mat - mat.min()) / (mat.max() - mat.min())

    cmap = plt.get_cmap('Blues')
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


