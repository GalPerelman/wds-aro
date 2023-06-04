import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse
from matplotlib.lines import Line2D
from scipy.stats import multivariate_normal


def load_data(path, filter_year=None):
    df = pd.read_csv(path, index_col=0)
    df.index = pd.to_datetime(df.index, dayfirst=True)
    df['hour'] = df.index.hour
    df['date'] = df.index.date
    if filter_year is not None:
        df = df.loc[df.index.year == filter_year]

    pivoted_df = pd.pivot(df, columns='hour', index='date')

    residuals = pivoted_df - pivoted_df.mean(axis=0)
    residuals.columns = residuals.columns.droplevel(0)
    return pivoted_df, residuals


def plot_daily_pattern(data: pd.DataFrame, ax=None):
    if ax is None:
        fig, ax = plt.subplots()
    ax.plot(data.values.T, c='C0', alpha=0.2)
    ax.plot(data.mean(axis=0).droplevel(0), c='k')
    ax.set_ylabel('Demand ($m^3$/hr)')
    ax.set_xlabel('Hour of the day')
    ax.grid()

    handles, labels = plt.gca().get_legend_handles_labels()
    observed = Line2D([0], [0], label='Daily observations', color='C0', alpha=0.4)
    mean = Line2D([0], [0], label='Hourly mean', color='k')
    handles.extend([observed, mean])
    plt.legend(handles=handles)

    return ax


def eigsorted(cov):
    """ https://stackoverflow.com/a/20127387 """
    vals, vecs = np.linalg.eigh(cov)
    order = vals.argsort()[::-1]
    return vals[order], vecs[:, order]


def plot_confidence_ellipsoids(x, y, ax=None):
    """
    theory: https://www.visiondummy.com/2014/04/draw-error-ellipse-representing-covariance-matrix
    plot:   https://stackoverflow.com/a/20127387
            https://matplotlib.org/stable/gallery/statistics/confidence_ellipse.html
            https://carstenschelp.github.io/2018/09/14/Plot_Confidence_Ellipse_001.html
            
    """
    if ax is None:
        fig, ax = plt.subplots()

    cov = np.cov(x, y)
    vals, vecs = eigsorted(cov)
    theta = np.degrees(np.arctan2(*vecs[:, 0][::-1]))

    for i in [1, 2, 3, 4, 5, 6, 7, 8]:
        w, h = 2 * i * np.sqrt(vals)
        ell = Ellipse(xy=(np.mean(x), np.mean(y)), width=w, height=h, angle=theta, color='grey', lw=0.5)
        ell.set_facecolor('none')
        ax.add_artist(ell)

    return ax


def plot_bivariate_distribution(mean, cov, ax, N):
    # Create a grid of points
    x, y = np.mgrid[-N:N:5, -N:N:5]
    pos = np.empty(x.shape + (2,))
    pos[:, :, 0] = x
    pos[:, :, 1] = y

    # Create a bivariate Gaussian distribution with the given mean and covariance
    rv = multivariate_normal(mean, cov)

    # Evaluate the bivariate Gaussian density at each point on the grid
    z = rv.pdf(pos)

    # Plot contours
    ax.contour(x, y, z, colors='grey', zorder=1, linewidths=0.5)
    return ax


def scatter_residuals(x, y, axes_lim=False, ax=None):
    if ax is None:
        fig, ax = plt.subplots()

    ax = plot_confidence_ellipsoids(x, y, ax)
    ax.scatter(x, y, alpha=0.4, c='dodgerblue', edgecolors='k', linewidths=0.5, zorder=5, s=15)
    if axes_lim:
        ax.set_xlim(-axes_lim, axes_lim)
        ax.set_ylim(-axes_lim, axes_lim)
    return ax


def plot_residuals(residuals, t, export_path=''):
    fig, axes = plt.subplots(nrows=t, ncols=t, figsize=(10, 8))
    # min_lim, max_lim = np.quantile(residuals, 0.01) * 0.7, np.quantile(residuals, 0.99) * 1.3
    min_lim, max_lim = residuals.min().min() * 1.2, residuals.max().max() * 0.5
    for i in range(t):
        for j in range(t):
            if i != j:
                x, y = residuals[i], residuals[j]
                axes[i, j] = plot_confidence_ellipsoids(x, y, axes[i, j])
                axes[i, j].scatter(x, y, alpha=0.4, c='dodgerblue', edgecolors='k', linewidths=0.5, zorder=5, s=15)
                axes[i, j].set_xlim(min_lim, max_lim)
                axes[i, j].set_ylim(min_lim, max_lim)

            if i == j:
                axes[i, j].hist(residuals[i], bins=10, alpha=0.5, color='dodgerblue', edgecolor='k', linewidth=0.5)

            axes[i, j].set_xticklabels([])
            axes[i, j].set_yticklabels([])

    for i, ax in enumerate(axes[0, :]):
        ax.set_title(f'Time {i}', fontsize=11)

    for i, ax in enumerate(axes[:, 0]):
        ax.set_ylabel(f'Time {i}', fontsize=11)

    plt.subplots_adjust(left=0.1, right=0.95, bottom=0.08, top=0.95, wspace=0.15, hspace=0.15)
    if export_path:
        plt.savefig(export_path)

    plt.show()


if __name__ == "__main__":
    data_path = 'observed_demands.csv'
    pivoted_df, residuals = load_data(data_path)
    plot_residuals(residuals, t=6, export_path='residuals.png')
    plot_daily_pattern(pivoted_df)
    plt.show()
