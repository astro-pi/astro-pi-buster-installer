from logzero import logger
import tester

@tester.test('reverse_geocoder')
def test_geocoder():
    import reverse_geocoder
    logger.debug(f'reverse_geocoder: {reverse_geocoder.search((0, 0))}')

@tester.test('osgeo')
def test_osgeo():
    # https://pcjericks.github.io/py-gdalogr-cookbook
    from osgeo import ogr, osr, gdal
    logger.debug(int(gdal.VersionInfo('VERSION_NUM')))
    point = ogr.Geometry(ogr.wkbPoint)
    point.AddPoint(1198054.34, 648493.09)
    logger.debug(f'osgeo: {point.ExportToWkt()}')
    cnt = ogr.GetDriverCount()
    formatsList = []  # Empty List
    for i in range(cnt):
        driver = ogr.GetDriver(i)
        driverName = driver.GetName()
        if not driverName in formatsList:
            formatsList.append(driverName)
    formatsList.sort() # Sorting the messy list of ogr drivers
    logger.debug(f'osgeo: {formatsList}')
    
@tester.test('geopandas')
def test_geopandas():
    import geopandas
    world = geopandas.read_file(geopandas.datasets.get_path('naturalearth_lowres'))
    cities = geopandas.read_file(geopandas.datasets.get_path('naturalearth_cities'))
    logger.debug(f'geopandas: {world.head()}')

@tester.test('earthpy')
def test_earthpy():
    import numpy as np
    import earthpy.plot as ep
    arr = np.random.randint(4, size=(3, 5, 5))
    ep.plot_bands(arr)

logger.info('Testing geo-related modules')
tests = [test_geocoder, test_osgeo, test_geopandas, test_earthpy]
for test in tests:
    test()

logger.info(f'Performed {tester.nbtests} tests')
if tester.failed:
    logger.error(f'{tester.failed} tests failed')
else:
    logger.info('All tests were successful')
