from logzero import logger
import tester

@tester.test('gpiozero')
def test_gpiozero():
    import gpiozero
    temperature_dev = gpiozero.CPUTemperature()
    logger.debug(f'gpiozero: {temperature_dev.value}')

@tester.test('colorzero')
def test_colorzero():
    import colorzero
    logger.debug(f'colorzero: {str(colorzero.Color("red"))}')

@tester.test('evdev')
def test_evdev():
    # https://python-evdev.readthedocs.io/en/latest/usage.html
    import evdev
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    for device in devices:
        logger.debug(f'evdev: {device.path}, {device.name}, {device.phys}')
        device.close()

@tester.test('pisense')
def test_pisense():
    # https://pisense.readthedocs.io/en/latest/demos.html
    from pisense import SenseHAT, SenseEnviron, array
    from colorzero import Color
    from time import sleep
    hat = SenseHAT()
    rainbow = array([
        Color(h=(x + y) / 14, s=1, v=1)
        for x in range(8)
        for y in range(8)])
    hat.screen.array = rainbow
    sleep(2)
    logger.debug(f'pisense: {hat.environ.humidity}')

@tester.test('sense_hat')
def test_sensehat():
    from time import sleep
    from sense_hat import SenseHat
    sense = SenseHat()
    logger.debug(f'sense_hat: {sense.get_humidity()}')
    sense.clear((0, 128, 64))
    sleep(2)
    sense.clear()

@tester.test('picamera')
def test_picamera():
    import os
    from time import sleep
    from picamera import PiCamera
    with PiCamera() as camera:
        camera.start_preview()
        sleep(2)
        camera.capture('test.jpg')
        os.remove('test.jpg')

logger.info('Testing RPi-related modules')
tests = [test_gpiozero, test_colorzero, test_evdev, test_pisense, test_sensehat, test_picamera]
for test in tests:
    test()

logger.info(f'Performed {tester.nbtests} tests')
if tester.failed:
    logger.error(f'{tester.failed} tests failed')
else:
    logger.info('All tests were successful')
