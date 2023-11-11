from app import app
from flask import Flask, render_template, Response
import os
import cv2
from urllib.request import urlopen
import numpy as np

@app.route("/")
def hello_world():
    return "Hello, World!"

@app.route('/detect', methods=['POST'])
def detect_shape():
    image_url = "http://192.168.178.200:5000/api/front2/latest.jpg"
    resp = urlopen(image_url)
    image = np.asarray(bytearray(resp.read()), dtype="uint8")
    image = cv2.imdecode(image, cv2.IMREAD_COLOR) # The image object
    image = image[550:650,100:400]
    # convert the image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # apply thresholding to convert the grayscale image to a binary image
    ret,thresh = cv2.threshold(gray,100,255,0)

    # find the contours
    contours,hierarchy = cv2.findContours(thresh, cv2.RETR_TREE,cv2.CHAIN_APPROX_SIMPLE)
    triangle_count=0
    square_count=0
    coordinates = []
    for cnt in contours:
        approx = cv2.approxPolyDP(cnt, 0.1*cv2.arcLength(cnt, True), True)
        if cv2.contourArea(cnt) > 300:
            if len(approx) == 3:
                triangle_count=triangle_count+1
            if len(approx) == 4:
                square_count=square_count+1
                #coordinates.append([cnt])
                #return str(cv2.contourArea(cnt))
                #cv2.drawContours(image, [cnt], 0, (0, 0, 255), 3)
    #cv2.imwrite("result.png", image)
    return "{\"triangle\":" + str(triangle_count) + ",\"square\":" + str(square_count) + "}"
