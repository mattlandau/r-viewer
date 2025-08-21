sub init()
    print "!!welcome GLT GridLoadTask"
  m.top.functionName = "getcontent"
end sub

sub getcontent()
    print "GridLoadTask GLT getcontent starting"
    m.top.isRunning = true
    m.content = createObject("roSGNode", "ContentNode")

    if (m.global.VideoWalls.count() = 0)
        print "!!error in getcontent"
        m.top.error = true
        m.top.isRunning = false
        return
    else
        print "!!success in getcontent"
        m.top.error = false
    end if

    selectedVideoWallIndex = m.global.SelectedVideoWallIndex
    print "selectedVideoWallIndex: "; selectedVideoWallIndex.ToStr()
    idealDeviceCount = 0
    actualDeviceCount = 0
    deviceCount = m.global.VideoWalls[selectedVideoWallIndex].deviceList.count()
    print "deviceCount: "; deviceCount.ToStr()

    for i = 0 to deviceCount - 1
        print "deviceList item "; i.ToStr(); ": "; m.global.VideoWalls[selectedVideoWallIndex].deviceList[i]
        placeholderItem = m.content.createChild("ContentNode")
        placeholderItem.setField("hdgridposterurl", "pkg:/images/thumbnail-placeholder.png")
    end for
    m.top.content = m.content

    if (selectedVideoWallIndex >= 0)
        print m.global.VideoWalls[selectedVideoWallIndex].displayName

    
        if (m.global.VideoWalls[selectedVideoWallIndex].deviceList = invalid)
            print "no Cameras to show in this video wall, zeroDevices true"
            m.top.zeroDevices = true
            m.top.isRunning = false
            return
        end if
        
        print "deviceList count: "; deviceCount.ToStr()
        i = 0
        for each device in m.global.VideoWalls[selectedVideoWallIndex].deviceList           
            frameUri = GetFrameUri(device)
            tempItem = m.content.GetChild(i)
            if (frameUri <> "error")
                imageURI = FetchJpegImage(frameUri, idealDeviceCount)

                tempItem.setField("hdgridposterurl", imageURI)
                print "adding Field device uuid: "; device; " imageURI: "; imageURI
                tempItem.AddField("cameraUUID", "string", false)
                tempItem.setField("cameraUUID", device)
                actualDeviceCount = actualDeviceCount + 1
            else
                print "!!error in GetFrameURI"
            end if
            deviceName = GetCameraDetails(device)
            if (deviceName <> invalid)
                tempItem.setField("title", deviceName)
            else
                print "!!error in GetCameraDetails"
            end if
            idealDeviceCount = idealDeviceCount + 1
            print "idealDeviceCount: "; idealDeviceCount.ToStr(); " actualDeviceCount: "; actualDeviceCount.ToStr()
            m.top.content = m.content
            i = i + 1
        end for
        print "Grid getcontent ending, devicesCount: "; deviceCount.ToStr(); " actualDeviceCount: "; actualDeviceCount.ToStr(); " idealDeviceCount: "; idealDeviceCount.ToStr()
    end if
    m.top.content = m.content
    
    if (idealDeviceCount = 0)
        m.top.zeroDevices = true
        print "!!error in getcontent, no devices"
    else 
        m.top.zeroDevices = false
    end if
    print "GridLoadTask getcontent ending; actualDeviceCount: "; actualDeviceCount.ToStr(); " idealDeviceCount: "; idealDeviceCount.ToStr()
    m.top.isRunning = false
end sub

Function GetFrameURI(cameraUUID as string) As String
    print "!!welcome GLT GetFrameURI"
    cachedFrameURIStem = getCachedFrameURIStem(cameraUUID)
    timestampS = GetUnixEpochSeconds(60)
    timestampMs = timestampS * 1000

    if (cachedFrameURIStem <> "invalid")
        print "!!cached frame URI found"
        frameURI = cachedFrameURIStem + "frame/" + cameraUUID + "/" + timestampMs.ToStr() + "/thumb.jpeg?d=2"
        print "frameURI from cache: "; frameURI
        return frameURI
    end if

    url = "https://api2.rhombussystems.com/api/video/getExactFrameUri"
    apiKey = m.global.APIKey
    print("GLT getting url: " + url)
    print "howdy url "; url; " cameraUUID "; cameraUUID
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.setRequest("POST")
    
    requestBody = { 
        "cameraUuid": cameraUUID,
        "timestampMs": timestampMs,
        "downscaleFactor": 2
    }

    request.setHeaders( {
        "accept": "application/json",
        "content-type": "application/json",
        "x-auth-apikey": apiKey,
        "x-auth-scheme": "api-token"
    })

    port = createObject("roMessagePort")
    request.SetMessagePort(port)
    
    responseCode = request.AsyncPostFromString(formatJson(requestBody))
    print "responseCode: "
    print responseCode
    if (responseCode <> 200)
        print "!!error in GetFrameURI"
        return "error"
    end if
    print("2 about to wait")
    response = wait(0, port)
    if (response = invalid)
        print "!!error in GetFrameURI"
        return "error"
    end if
    print response.GetResponseCode()
    print response.GetFailureReason()
    print("2 done waiting")
    responseCode = response.GetResponseCode()
    print "2 responseCode: "
    print(responseCode)
    if (responseCode <> 200)
        print "!!error in GetFrameURI"
        return "error"
    end if
    print "2 failReason: "
    failReason = response.GetFailureReason()
    print(failReason)
    responseBody = ParseJSON(response.GetString())
    if (responseBody = invalid)
        print "responseBody is invalid"
        return "error"
    end if
    print "frameUri: "; responseBody.frameUri
    if (responseBody.frameUri = invalid)
        m.result = m.global.PlaceholderImage
    else
        m.result = responseBody.frameUri
        
    end if

    saveFrameURIStem(cameraUUID, m.result)

    return m.result
end function

function getCachedFrameURIStem(cameraUUID as string) as String
    print "!!welcome GLT getCachedFrameURI"
    if (m.global.DeviceURIStems[cameraUUID] = invalid)
            print "getCachedFrameURIStem: cache miss"
            return "invalid"
        else
            print "DeviceURIStems: "; m.global.DeviceURIStems[cameraUUID].ToStr()
            print "getCachedFrameURIStem: cache hit"
            return m.global.DeviceURIStems[cameraUUID].ToStr()
        end if
end function

sub saveFrameURIStem(cameraUUID as string, frameURI as string)
    print "!!welcome GLT saveFrameURIStem"
    splitter = CreateObject("roRegex", "frame", "")
    frameURIStem = splitter.Split(frameURI)[0]
    print "frameURIStem: "; frameURIStem.ToStr()
    myTempAssociativeArray = m.global.DeviceURIStems
    myTempAssociativeArray[cameraUUID] = frameURIStem
    m.global.setField("DeviceURIStems", myTempAssociativeArray)

    print "DeviceURIStems: "; m.global.DeviceURIStems[cameraUUID].ToStr()
    print "DeviceURIStems assoc: "; myTempAssociativeArray[cameraUUID].ToStr()
end sub

Function FetchJpegImage(url as String, counter as Integer) As String
    print "!!welcome GLT FetchJpegImage, url: "; url; " counter: "; counter.ToStr()
    if (url = m.global.PlaceholderImage)
        return m.global.PlaceholderImage
    end if
    apiKey = m.global.APIKey
    print("getting url: " + url)
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.setRequest("GET")
    print("howdy!!! url " + url)
    request.setHeaders( {
        "content-type": "image/jpeg",
        "x-auth-apikey": apiKey,
        "x-auth-scheme": "api-token"
    })

    m.global.Timestamp = GetUnixEpochSeconds(60)
    refreshCounterString = ZeroPadInteger(m.global.RefreshCounter, 8)
    tmpPath = "tmp:/" + refreshCounterString + "--grid_item_" + counter.ToStr() + "-" + m.global.Timestamp.ToStr() + ".jpeg"
    print "tmpPath: "; tmpPath
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    success = request.AsyncGetToFile(tmpPath)
    response = wait(0, port)
    if (response <> invalid)
        success = (response.GetResponseCode() = 200)
    else
        success = false
    end if
    print request.GetFailureReason()
    print success

    if (success)
        print "Image saved to: "; tmpPath
        return tmpPath  ' Return file path of the saved image
    else
        print "Failed to download image."
        return ""
    end if
End Function

function ZeroPadInteger(num as Integer, length as Integer) as String
    numStr = num.ToStr()
    paddingNeeded = length - numStr.Len()
    return String(paddingNeeded, "0") + numStr
end function

Function GetUnixEpochSeconds(offsetSeconds as Integer) As LongInteger
    
 dt = CreateObject("roDateTime")
    dt.Mark()
    result = (dt.AsSeconds() - offsetSeconds)
    print "getunixepoch: "; result.ToStr()
    return result
End Function


function getCachedDeviceName(cameraUUID as string) as String
    print "!!welcome GLT getCachedFrameURI"
    if (m.global.DeviceNames[cameraUUID] = invalid)
        print "getCachedDeviceName: cache miss"
        return "invalid"
    else
        print "DeviceName: "; m.global.DeviceNames[cameraUUID].ToStr()
        print "getCachedDeviceName: cache hit"
        return m.global.DeviceNames[cameraUUID].ToStr()
    end if
end function

sub saveDeviceName(cameraUUID as string, deviceName as string)
    print "!!welcome GLT saveDeviceName, saving - cameraUUID: "; cameraUUID; " deviceName: "; deviceName
    myTempAssociativeArray = m.global.DeviceNames
    myTempAssociativeArray[cameraUUID] = deviceName
    m.global.setField("DeviceNames", myTempAssociativeArray)
end sub

function GetCameraDetails(cameraUUID as string) as Object
    print "!!welcome GLT GetCameraDetails"

    cachedDeviceName = getCachedDeviceName(cameraUUID)
    if (cachedDeviceName <> "invalid")
        return cachedDeviceName
    end if

    url = "https://api2.rhombussystems.com/api/camera/getDetails"    
    apiKey = m.global.APIKey
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.setRequest("POST")

    requestBody = { 
        "cameraUuids": [ cameraUUID ]
    }

    request.setHeaders( {
        "accept": "application/json",
        "content-type": "application/json",
        "x-auth-apikey": apiKey,
        "x-auth-scheme": "api-token"
    })

    port = createObject("roMessagePort")
    request.SetMessagePort(port)
    responseCode = request.AsyncPostFromString(formatJson(requestBody))
    response = wait(0, port)
    if (response = invalid)
        print "!!error in GetCameraDetails"
        return invalid
    end if
    responseCode = response.GetResponseCode()
    print responseCode
    if (responseCode <> 200)
        failReason = response.GetFailureReason()
        print(failReason)
        print "!!welcome GetCameraDetails GLT - error in GetCameraDetails - "; failReason; ", url: "; url
        return invalid
    end if
    print "!!welcome GetCameraDetails GLT - success in GetCameraDetails, url: "; url
    
    responseBody = ParseJSON(response.GetString())

    print "GetCameraDetails: camera name: "; responseBody.cameras[0].name
    saveDeviceName(cameraUUID, responseBody.cameras[0].name)
    
    return responseBody.cameras[0].name
end function
