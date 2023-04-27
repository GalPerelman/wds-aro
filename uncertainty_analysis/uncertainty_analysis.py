import pandas as pd
import numpy as np
import math
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse
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


def plot_daily_pattern(data: pd.DataFrame):
    fig, ax = plt.subplots()
    ax.plot(data.values.T, c='C0', alpha=0.3)
    ax.plot(data.mean(axis=0).droplevel(0), c='k')
    ax.set_ylabel('Demand (CMH)')
    ax.set_xlabel('Time')
    ax.grid()


def eigsorted(cov):
    """ https://stackoverflow.com/a/20127387 """
    vals, vecs = np.linalg.eigh(cov)
    order = vals.argsort()[::-1]
    return vals[order], vecs[:, order]


def plot_confidence_ellipsoids(x, y, ax=None):
    if ax is None:
        fig, ax = plt.subplots()

    cov = np.cov(x, y)
    vals, vecs = eigsorted(cov)
    theta = np.degrees(np.arctan2(*vecs[:, 0][::-1]))

    for i in [1, 2, 3, 4, 5, 6]:
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


def plot_residuals(residuals, t):
    fig, axes = plt.subplots(nrows=t, ncols=t, figsize=(8, 6))
    min_lim, max_lim = np.quantile(residuals, 0.01) * 0.85, np.quantile(residuals, 0.99) * 1.15
    n = int(math.ceil(max_lim / 100.0)) * 100
    for i in range(t):
        for j in range(t):
            if i != j:
                x, y = residuals[i], residuals[j]
                # mean_1, mean_2 = x.mean(), y.mean()
                # axes[i, j] = plot_bivariate_distribution(np.array([mean_1, mean_2]), np.cov(x, y), axes[i, j], n)
                axes[i, j] = plot_confidence_ellipsoids(residuals[i], residuals[j], axes[i, j])
                axes[i, j].scatter(residuals[i], residuals[j], alpha=0.4, c='dodgerblue', edgecolors='k',
                                   linewidths=0.5, zorder=5, s=15)
                axes[i, j].set_xlim(min_lim, max_lim)
                axes[i, j].set_ylim(min_lim, max_lim)

            if i == j:
                axes[i, j].hist(residuals[i], bins=10, alpha=0.5, color='dodgerblue', edgecolor='k', linewidth=0.5)

            axes[i, j].set_xticklabels([])
            axes[i, j].set_yticklabels([])

    for i, ax in enumerate(axes[0, :]):
        ax.set_title(f'Time {i}', fontsize=12)

    for i, ax in enumerate(axes[:, 0]):
        ax.set_ylabel(f'Time {i}', fontsize=12)

    plt.subplots_adjust(left=0.08, right=0.95, bottom=0.08, top=0.95, wspace=0.06, hspace=0.1)


if __name__ == "__main__":
    data_path = 'observed_demands.csv'
    pivoted_df, residuals = load_data(data_path)
    plot_daily_pattern(pivoted_df)
    plot_residuals(residuals, t=5)
    plt.show()