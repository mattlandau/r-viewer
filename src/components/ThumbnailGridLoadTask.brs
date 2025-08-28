sub init()
    print "DEBUGLOG: GLT ThumbnailGridLoadTask"
    m.top.functionName = "LoadGrid"
end sub

sub LoadGrid()
    print "DEBUGLOG: ThumbnailGridLoadTask GLT LoadGrid starting"
    m.content = createObject("roSGNode", "ContentNode")
    m.top.conent = m.content

    if (m.global.VideoWalls.count() = 0)
        print "!!error in LoadGrid"
        m.top.error = true
        return
    else
        print "!!success in LoadGrid"
        m.top.error = false
    end if

    selectedVideoWallIndex = m.global.SelectedVideoWallIndex
    print "selectedVideoWallIndex: "; selectedVideoWallIndex.ToStr()
    idealDeviceCount = 0
    actualDeviceCount = 0
    deviceCount = m.global.VideoWalls[selectedVideoWallIndex].deviceList.count()
    print "deviceCount: "; deviceCount.ToStr()

    for i = 0 to deviceCount - 1
        m.content.createChild("ContentNode")
    end for
    m.top.content = m.content

    if (selectedVideoWallIndex >= 0)
        print m.global.VideoWalls[selectedVideoWallIndex].displayName

    
        if (m.global.VideoWalls[selectedVideoWallIndex].deviceList = invalid)
            print "no Cameras to show in this video wall, zeroDevices true"
            m.top.zeroDevices = true
            ' m.top.isRunning = false
            return
        end if
        
        print "deviceList count: "; deviceCount.ToStr()
        i = 0
        for each device in m.global.VideoWalls[selectedVideoWallIndex].deviceList           
            frameUri = GetFrameUri(device)
            print "getChildCount: "; m.content.getChildCount().ToStr()
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
end sub

Function GetFrameURI(cameraUUID as string) As String
    print "DEBUGLOG: GLT GetFrameURI"
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
    print("GetFrameURI - about to wait")
    response = wait(0, port)
    if (response = invalid)
        print "!!error in GetFrameURI"
        return "error"
    end if
    print("GetFrameURI - done waiting")
    responseCode = response.GetResponseCode()
    print "GetFrameURI - responseCode: " + responseCode.ToStr()
    if (responseCode <> 200)
        print "!!error in GetFrameURI"
        return "error"
    end if
    failReason = response.GetFailureReason()
    print "GetFrameURI failReason: " + failReason.ToStr()
    responseBody = ParseJSON(response.GetString())
    if (responseBody = invalid)
        print "GetFrameURI responseBody is invalid"
        return "error"
    end if
    print "GetFrameURI frameUri: "; responseBody.frameUri
    if (responseBody.frameUri = invalid)
        m.result = m.global.PlaceholderImage
    else
        m.result = responseBody.frameUri
        
    end if

    saveFrameURIStem(cameraUUID, m.result)

    return m.result
end function

function getCachedFrameURIStem(cameraUUID as string) as String
    print "DEBUGLOG: GLT getCachedFrameURI"
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
    print "DEBUGLOG: GLT saveFrameURIStem"
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
    print "DEBUGLOG: GLT FetchJpegImage, url: "; url; " counter: "; counter.ToStr()
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
    print "Did request fail?" + request.GetFailureReason()
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
    print "DEBUGLOG: GLT getCachedFrameURI"
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
    print "DEBUGLOG: GLT saveDeviceName, saving - cameraUUID: "; cameraUUID; " deviceName: "; deviceName
    myTempAssociativeArray = m.global.DeviceNames
    myTempAssociativeArray[cameraUUID] = deviceName
    m.global.setField("DeviceNames", myTempAssociativeArray)
end sub

function GetCameraDetails(cameraUUID as string) as Object
    print "DEBUGLOG: GLT GetCameraDetails"

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
        print "DEBUGLOG: GetCameraDetails GLT - error in GetCameraDetails - "; failReason; ", url: "; url
        return invalid
    end if
    print "DEBUGLOG: GetCameraDetails GLT - success in GetCameraDetails, url: "; url
    
    responseBody = ParseJSON(response.GetString())

    print "GetCameraDetails: camera name: "; responseBody.cameras[0].name
    saveDeviceName(cameraUUID, responseBody.cameras[0].name)
    
    return responseBody.cameras[0].name
end function
