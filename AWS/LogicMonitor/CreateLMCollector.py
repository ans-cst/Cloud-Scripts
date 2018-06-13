#!/usr/bin/env python
# pylint: disable=invalid-name

"""This script installs and configures a LogicMonitor Collector
 Group and Collectors using the LogicMonitor rest API"""

# File Name  : CreateLMCollector.py
# Author     : Nathan Gaskill - nathan.gaskill@ansgroup.co.uk
# Owner      : ANS Group
# Web:       : http://www.ans.co.uk  


import os
import sys
import urllib
import hashlib
import base64
import time
import hmac
import requests
from urllib.parse import quote

#Parameters
accessId = sys.argv[1]
accessKey = sys.argv[2]
collectorSize = sys.argv[3]
lmHost = sys.argv[4]
customerName = sys.argv[5]

#Variables
path = r"/ans"

#Get current time in milliseconds
epoch = str(int(time.time() * 1000))

def signedHeaders(requestVars):
    """function to sign headers"""
    #Construct signature
    hmacstring = hmac.new(accessKey.encode(), msg=requestVars.encode(), digestmod=hashlib.sha256).hexdigest()
    signature = base64.b64encode(hmacstring.encode())

    #Construct headers
    auth = 'LMv1 ' + accessId + ':' + signature.decode() + ':' + epoch
    headers = {'Content-Type':'application/json', 'Authorization':auth}

    return headers


def createLmCollector(collectorGroupId, customerName, backupAgentId):
    """function to create LogicMonitor collector"""
    print("Creating LogicMonitor Collector")

    if backupAgentId:
    
        collectorType = "Primary"
        body = '{"collectorGroupId": '+ str (collectorGroupId) +',"description": "' + customerName + ' - ' + collectorType + '","backupAgentId":'+ str (backupAgentId) +'}'
    else:
        collectorType = "Secondary"
        body = '{"collectorGroupId": '+ str (collectorGroupId) +',"description": "' + customerName + ' - ' + collectorType + '"}'
    
    #Request Info
    httpVerb = 'POST'
    resourcePath = '/setting/collectors'
    queryParams = ''
    data = body

    #Construct URL
    url = 'https://'+ lmHost +'.logicmonitor.com/santaba/rest' + resourcePath + queryParams

    #Concatenate Request details
    requestVars = httpVerb + epoch + data + resourcePath

    #Make request
    response = requests.post(url, data=data, headers=signedHeaders(requestVars))
    responseJson = response.json()
    if response.status_code == 200:
        return responseJson['data']['id']
    else:
        raise Exception('Error creating LogicMonitor collector')

def getLmCollector(customerName):
    """function to get LogicMonitor collector Id"""
    print("Getting LogicMonitor Collector Id")

    #Request Info
    httpVerb = 'GET'
    resourcePath = '/setting/collectors'
    queryParams = '?fields=id,description,hostname&filter=description:' + quote(customerName + ' - Secondary')
    data = ''

    #Construct URL
    url = 'https://'+ lmHost +'.logicmonitor.com/santaba/rest' + resourcePath + queryParams

    #Concatenate Request details
    requestVars = httpVerb + epoch + data + resourcePath

    #Make request
    response = requests.get(url, data=data, headers=signedHeaders(requestVars))
    responseJson = response.json()
    if response.status_code == 200 and responseJson['data']['total'] == 1:
        return responseJson['data']['items'][0]['id']
    else:
        return 0

def createDirectory():
    print("Checking Directory")
    if not os.path.exists(path):
        print("Creating Directory")
        os.makedirs(path)

def downloadLmInstaller(collectorId):
    """function to download LogicMonitor installer"""
    print("Downloading LogicMonitor Collector")
    #Request Info
    httpVerb = 'GET'
    resourcePath = '/setting/collectors/' + str (collectorId) +'/installers/Linux64'
    queryParams = '?collectorSize=' + collectorSize
    data = ''

    #Construct URL
    url = 'https://'+ lmHost +'.logicmonitor.com/santaba/rest' + resourcePath + queryParams

    #Concatenate Request details
    requestVars = httpVerb + epoch + data + resourcePath

    #Make request
    response = requests.get(url, stream=True, headers=signedHeaders(requestVars))

    with open(path + '/LogicMonitorSetup.bin', 'wb') as fileStream:
        for chunk in response.iter_content(chunk_size=1024): 
            if chunk: # filter out keep-alive new chunks
                fileStream.write(chunk)
    
    if response.status_code == 200 and os.path.exists(path + '/LogicMonitorSetup.bin'):
        print("Downloaded LogicMonitor Collector")
    else:
        raise Exception('Somthing went wrong downloading collector')    

def getCollectorGroup(customerName):
    """function to get LogicMonitor collector group Id"""

    #Request Info
    httpVerb = 'GET'
    resourcePath = '/setting/collectors/groups'
    queryParams = '?fields=id,name,description&filter=name:' + quote(customerName)
    data = ''

    #Construct URL
    url = 'https://'+ lmHost +'.logicmonitor.com/santaba/rest' + resourcePath + queryParams

    #Concatenate Request details
    requestVars = httpVerb + epoch + data + resourcePath

    #Make request
    response = requests.get(url, data=data, headers=signedHeaders(requestVars))
    responseJson = response.json()
    if response.status_code == 200 and responseJson['data']['total'] == 1:
        return responseJson['data']['items'][0]['id']
    else:
        return 0    

def createCollectorGroup(customerName):
    """function to get LogicMonitor collector group Id"""

    #Request Info
    httpVerb = 'POST'
    resourcePath = '/setting/collectors/groups'
    queryParams = ''
    data = '{"name": "' + customerName +'", "description": "' + customerName +' Collector Group"}'

    #Construct URL
    url = 'https://'+ lmHost +'.logicmonitor.com/santaba/rest' + resourcePath + queryParams

    #Concatenate Request details
    requestVars = httpVerb + epoch + data + resourcePath

    #Make request
    response = requests.post(url, data=data, headers=signedHeaders(requestVars))
    
    responseJson = response.json()
    if response.status_code == 200:
        return responseJson['data']['id']
    else:
        raise Exception('Somthing went wrong creating customer group')

def updateCollectorDeviceGroup(deviceId,deviceGroupId):
    """function update LogicMonitor collectors device group"""

    #Request Info
    httpVerb = 'PATCH'
    resourcePath = '/device/devices/' + str(deviceId)
    queryParams = '?patchFields=hostGroupIds'
    data = '{"hostGroupIds":' + str(deviceGroupId) + '}'

    #Construct URL
    url = 'https://'+ lmHost +'.logicmonitor.com/santaba/rest' + resourcePath + queryParams

    #Concatenate Request details
    requestVars = httpVerb + epoch + data + resourcePath

    #Make request
    response = requests.patch(url, data=data, headers=signedHeaders(requestVars))
   
    responseJson = response.json()
    if response.status_code == 200:
        print("Updated collectors device group id")
    else:
        raise Exception('Somthing went wrong updating customer group')


def getLmCollectorDeviceId(collectorId):
    """function to get LogicMonitor collector Id"""
    print("Getting LogicMonitor Collector Device Id")

    #Request Info
    httpVerb = 'GET'
    resourcePath = '/setting/collectors/'+ str(collectorId)
    queryParams = ''
    data = ''

    #Construct URL
    url = 'https://'+ lmHost +'.logicmonitor.com/santaba/rest' + resourcePath + queryParams

    #Concatenate Request details
    requestVars = httpVerb + epoch + data + resourcePath

    #Make request
    response = requests.get(url, data=data, headers=signedHeaders(requestVars))
    responseJson = response.json()
    if response.status_code == 200:
        print("Collector Device Id: " + str(responseJson['data']['collectorDeviceId']))
        return responseJson['data']['collectorDeviceId']
    else:
        raise Exception('Somthing went wrong getting collectors device id')

# ***************************** Script *************************** #
# Create Collector Group if it does not exist
if getCollectorGroup(customerName) == 0:
    createCollectorGroup(customerName)

# Get Collector Group Id
collectorGroupId = getCollectorGroup(customerName)

# Check if Secondary collector exists, then create a Secondary or Primary on test result
if getLmCollector(customerName) == 0:
    #Create a Secondary Collector in LogicMonitor
    backupAgentId = ''
    collectorId = createLmCollector(collectorGroupId, customerName, backupAgentId)
else:
    #Create a Primary Collector in LogicMonitor
    backupAgentId = getLmCollector(customerName)
    collectorId = createLmCollector(collectorGroupId, customerName, backupAgentId)

# Create Directory
createDirectory()

# Download Installer
downloadLmInstaller(collectorId)

# Install Collector
os.system('chmod 777 ' + path + '/LogicMonitorSetup.bin')
os.system(path + '/LogicMonitorSetup.bin -y')

# Get DeviceId from Collector
deviceId = getLmCollectorDeviceId(collectorId)

# Get device group id from customer
deviceGroupId = getCustomerDeviceGrpBySosId()

# Update collectors device group
updateCollectorDeviceGroup(deviceId, deviceGroupId)