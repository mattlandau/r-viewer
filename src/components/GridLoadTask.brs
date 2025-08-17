sub init()
    print "!!welcome GridLoadTask"
  m.top.functionName = "getcontent"
end sub

sub getcontent()
    print "GridLoadTask getcontent starting"
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

    if (selectedVideoWallIndex >= 0)
        print m.global.VideoWalls[selectedVideoWallIndex].displayName

        print "deviceList (25)"
        if (m.global.VideoWalls[selectedVideoWallIndex].deviceList = invalid)
            print "no Cameras to show in this video wall, zeroDevices true"
            m.top.zeroDevices = true
            m.top.isRunning = false
            return
        end if
        deviceCount = m.global.VideoWalls[selectedVideoWallIndex].deviceList.count()
        print "deviceList count: "; deviceCount.ToStr()

        for each device in m.global.VideoWalls[selectedVideoWallIndex].deviceList           
            frameUri = GetFrameUri(device)
            tempItem = m.content.createChild("ContentNode")
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
            details = GetCameraDetails(device)
            if (details <> invalid)
                cameraName = details.cameras[0].name
                tempItem.setField("title", cameraName)
            else
                print "!!error in GetCameraDetails"
            end if
            idealDeviceCount = idealDeviceCount + 1

        end for
        print "Grid getcontent ending, devicesCount: "; deviceCount.ToStr(); " actualDeviceCount: "; actualDeviceCount.ToStr(); " idealDeviceCount: "; idealDeviceCount.ToStr()
        if (actualDeviceCount < idealDeviceCount)
            print "getcontent (task) too few device shown"
            m.top.incompleteLoad = true
        else
            print "getcontent (task) correct device count shown"
            m.top.incompleteLoad = false
        end if

    end if
    m.top.content = m.content
    
    if (idealDeviceCount = 0)
        m.top.zeroDevices = true
        print "!!error in getcontent, no devices"
    else 
        m.top.zeroDevices = false
    end if
    print "GridLoadTAsk getcontent ending"
    m.top.isRunning = false
end sub

Function GetFrameURI(cameraUUID as string) As String
    url = "https://api2.rhombussystems.com/api/video/getExactFrameUri"
    apiKey = m.global.APIKey
    print("getting url: " + url)
    print "howdy url "; url; " cameraUUID "; cameraUUID
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.setRequest("POST")
    
    timestampMs = GetUnixEpochSeconds(60)
    print "using epoch: "
    print timestampMs * 1000
    requestBody = { 
        "cameraUuid": cameraUUID,
        "timestampMs": timestampMs * 1000,
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
    return m.result
end function


function GetCameraDetails(cameraUUID as string) as Object
    print "!!welcome GetCameraName"
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
        print "!!error in GetCameraDetails"
        return invalid
    end if
    print "!!success in GetCameraDetails"
    failReason = response.GetFailureReason()
    print(failReason)
    responseBody = ParseJSON(response.GetString())
    
    return responseBody
end function

Function FetchJpegImage(url as String, counter as Integer) As String
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
    success = request.GetToFile(tmpPath)
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
