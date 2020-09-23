import logzero
logzero.loglevel(20) # info
from logzero import logger

nbtests = failed = 0

def test(name):
    def wrapper(test_function):
        def tester():
            global nbtests, failed
            logger.info(f'testing {name}')
            nbtests += 1
            try:
                test_function()
                logger.info(f'{name} test complete')
            except Exception as e:
                logger.error(f'{name} test failed')
                logger.error(f'{e.__class__.__name__}: {e}')
                failed += 1
        return tester
    return wrapper
