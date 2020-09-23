from logzero import logger
import tester

@tester.test('numpy')
def test_numpy():
    # https://numpy.org/doc/stable/user/quickstart.html
    import numpy as np
    z =  np.array([1, 3, 5, 7]) *  np.array([0, 1, 2, 3])
    logger.debug(f'numpy: {z}')


@tester.test('matplotlib')
def test_matplotlib():
    import numpy as np
    import matplotlib.pyplot as plt
    x = np.linspace(0, 10, 100)
    plot = plt.plot(x, x, label='linear')
    logger.debug(f'matplotlib: {plot}')

@tester.test('pandas')
def test_pandas():
    # https://pandas.pydata.org/pandas-docs/stable/user_guide/cookbook.html
    import pandas
    df = pandas.DataFrame({
      'AAA': [4, 5, 6, 7],
      'BBB': [10, 20, 30, 40],
      'CCC': [100, 50, -30, -50]})
    logger.debug(f"pandas:\n{df}")

@tester.test('scipy')
def test_scipy():
    # https://docs.scipy.org/doc/scipy/reference/tutorial/fft.html
    import numpy as np
    import scipy
    from scipy.fftpack import fft
    x = np.array([1.0, 2.0, 1.0, -1.0, 1.5])
    logger.debug(f'scipy:\n{fft(x)}')

@tester.test('skimage')
def test_skimage():
    # https://scikit-image.org/
    logger.info('importing skimage')
    import skimage
    from skimage import data, filters
    image = data.coins()
    edges = filters.sobel(image)
    logger.debug(f'skimage:\n{edges}')

@tester.test('sklearn')
def test_sklearn():
    # https://scikit-learn.org/stable/getting_started.html
    import sklearn
    from sklearn.ensemble import RandomForestClassifier
    clf = RandomForestClassifier(random_state=0)
    X = [[ 1,  2,  3], [11, 12, 13]]
    y = [0, 1]
    clf.fit(X, y)
    logger.debug(f'sklearn: {clf.predict(X)}')

logger.info('Testing numerical modules')
tests = [test_numpy, test_matplotlib, test_pandas, test_scipy, test_skimage, test_sklearn]
for test in tests:
    test()

logger.info(f'Performed {tester.nbtests} tests')
if tester.failed:
    logger.error(f'{tester.failed} tests failed')
else:
    logger.info('All tests were successful')

