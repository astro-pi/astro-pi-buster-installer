from logzero import logger, logfile
from sense_hat import SenseHat
from ephem import readtle, degree
from picamera import PiCamera
from datetime import datetime, timedelta
from time import sleep
import random
import os
import csv

dir_path = os.path.dirname(os.path.realpath(__file__))

# Connect to the Sense Hat
sh = SenseHat()

# Set a logfile name
logfile(dir_path + "/teamname.log")

# Latest TLE data for ISS location
name = "ISS (ZARYA)"
l1 = "1 25544U 98067A   19336.91239465 -.00004070  00000-0 -63077-4 0  9991"
l2 = "2 25544  51.6431 244.7958 0006616 354.0287  44.0565 15.50078860201433"
iss = readtle(name, l1, l2)

# Set up camera
cam = PiCamera()
cam.resolution = (1296, 972)

def create_csv_file(data_file):
    "Create a new CSV file and add the header row"
    with open(data_file, 'w') as f:
        writer = csv.writer(f)
        header = ("Date/time", "Temperature", "Humidity")
        writer.writerow(header)

def add_csv_data(data_file, data):
    "Add a row of data to the data_file CSV"
    with open(data_file, 'a') as f:
        writer = csv.writer(f)
        writer.writerow(data)

def get_latlon():
    """
    A function to write lat/long to EXIF data for photographs.
    Returns (lat, long)
    """
    iss.compute() # Get the lat/long values from ephem
    long_value = [float(i) for i in str(iss.sublong).split(":")]
    if long_value[0] < 0:
        long_value[0] = abs(long_value[0])
        cam.exif_tags['GPS.GPSLongitudeRef'] = "W"
    else:
        cam.exif_tags['GPS.GPSLongitudeRef'] = "E"
    cam.exif_tags['GPS.GPSLongitude'] = '%d/1,%d/1,%d/10' % (long_value[0], long_value[1], long_value[2]*10)
    lat_value = [float(i) for i in str(iss.sublat).split(":")]
    if lat_value[0] < 0:
        lat_value[0] = abs(lat_value[0])
        cam.exif_tags['GPS.GPSLatitudeRef'] = "S"
    else:
        cam.exif_tags['GPS.GPSLatitudeRef'] = "N"
    cam.exif_tags['GPS.GPSLatitude'] = '%d/1,%d/1,%d/10' % (lat_value[0], lat_value[1], lat_value[2]*10)
    return (iss.sublat / degree, iss.sublong / degree)

# initialise the CSV file
data_file = dir_path + "/data.csv"
create_csv_file(data_file)
# store the start time
start_time = datetime.now()
# store the current time
# (these will be almost the same at the start)
now_time = datetime.now()
# run a loop for 2 minutes
photo_counter = 1

while (now_time < start_time + timedelta(minutes=178)):
    try:
        logger.info("{} iteration {}".format(datetime.now(), photo_counter))
        humidity = round(sh.humidity, 4)
        temperature = round(sh.temperature, 4)
        # get latitude and longitude
        lat, lon = get_latlon()
        # Save the data to the file
        data = (datetime.now(), photo_counter, humidity, temperature, lat, lon)
        add_csv_data(data_file, data)
        # use zfill to pad the integer value used in filename to 3 digits (e.g. 001, 002...)
        cam.capture(dir_path + "/photo_" + str(photo_counter).zfill(3) + ".jpg")
        photo_counter += 1
        # update the current time
        now_time = datetime.now()
    except Exception as e:
        logger.error('{}: {})'.format(e.__class__.__name__, e))
