from logzero import logger
import tester

@tester.test('opencv')
def test_opencv():
    import numpy as np
    import cv2
    img = np.zeros((512,512,3), np.uint8)
    img = cv2.line(img,(0,0),(511,511),(255,0,0),5)
    img = cv2.rectangle(img,(384,0),(510,128),(0,255,0),3)
    img = cv2.circle(img,(447,63), 63, (0,0,255), -1)

@tester.test('exif')
def test_exif():
    import exif


logger.info('Testing image-related modules')
tests = [test_opencv, test_exif]
for test in tests:
    test()

logger.info(f'Performed {tester.nbtests} tests')
if tester.failed:
    logger.error(f'{tester.failed} tests failed')
else:
    logger.info('All tests were successful')
