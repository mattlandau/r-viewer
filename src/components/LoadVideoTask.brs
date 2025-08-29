sub Init()
    print "DEBUGLOG: LoadVideoTask"
    m.top.functionName = "LoadVideo"
end sub

sub LoadVideo()
    print "DEBUGLOG: LoadVideo (task)"
    uriResult = GetMediaURIs()
    m.global.SetField("wanURI", uriResult)
    print "DEBUGLOG: LoadVideo: FederateToken "; m.global.FederatedToken; " LoadVideo: wanMedia "; m.global.wanURI
    m.top.videoURLIsReady = true
end sub

Function GetMediaURIs() As String
    cameraUUID = m.global.CurrentCameraUUID
    if (cameraUUID = "" or cameraUUID = invalid)
        print "GetMediaURIs - no cameraUUID set"
        return "error"
    end if

    url = "https://api2.rhombussystems.com/api/camera/getMediaUris"

    apiKey = m.global.APIKey
    print("GetMediaURIs - getting url: " + url)
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.setRequest("POST")
   
    requestBody = { 
        "cameraUuid": cameraUUID
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
    print "GetMediaURIs responseCode: " + responseCode.ToStr()

    ' if (responseCode <> 200)
    '     print "!!error in Get media uRI"
    '     return invalid
    ' end if
    ' print("GetMediaURIs about to wait")
    response = wait(0, port)

    ' print("GetMediaURIs - done waiting")
    responseCode = response.GetResponseCode()
    print "GetMediaURIs - responseCode: " + responseCode.ToStr()
    failReason = response.GetFailureReason()
    print "GetMediaURIs - failReason: " + failReason.ToStr()
    responseBody = ParseJSON(response.GetString())
    print "GetMediaURIs - responseBody: "; responseBody
    ' if (responseBody <> invalid and responseBody.wanLiveM3u8Uri <> invalid)
    '     m.global.SetField("wanLiveM3u8Uri", responseBody.wanLiveM3u8Uri)
    '     print "GetMediaURIs - wanLiveM3u8Uri for "; cameraUUID; " is "; responseBody.wanLiveM3u8Uri
    ' else
    '     print "responseBody is invalid, no WAN uri for "; cameraUUID
    '     return "error"
    ' end if
    wanURL = "error"
    ' if (responseBody = invalid or responseBody.wanLiveM3u8Uri = invalid or responseBody.wanLiveMpdUri <> "")
    if (responseBody <> invalid and responseBody.wanLiveM3u8Uri <> invalid)
        wanURL = responseBody.wanLiveM3u8Uri
    else
        wanURL = GetMediaDoorbellCameraURIs()
    end if
    print "GetMediaURIs - wanURL for "; cameraUUID; " is "; wanURL
    return wanURL
end function

Function GetMediaDoorbellCameraURIs() As String
    url = "https://api2.rhombussystems.com/api/doorbellcamera/getMediaUris"

    apiKey = m.global.APIKey
    print("GetMediaDoorbellURIs - getting url: " + url)
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.setRequest("POST")
    cameraUUID = m.global.CurrentCameraUUID
   
    requestBody = { 
        "deviceUuid": cameraUUID
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
    print "GetMediaURIs responseCode: " + responseCode.ToStr()

    ' if (responseCode <> 200)
    '     print "!!error in Get media uRI"
    '     return invalid
    ' end if

    response = wait(0, port)

    responseCode = response.GetResponseCode()
    print "GetMediaURIs - responseCode: " + responseCode.ToStr()
    failReason = response.GetFailureReason()
    print "GetMediaURIs - failReason: " + failReason.ToStr()
    responseBody = ParseJSON(response.GetString())
    print "GetMediaURIs - responseBody: "; responseBody
    
    if (responseBody.wanLiveMpdUri <> invalid)
        wanURL = responseBody.wanLiveMpdUri
    else
        wanURL = "error"
    end if
    return wanURL
end function

