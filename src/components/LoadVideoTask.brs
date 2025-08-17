sub Init()
    print "!!welcome LoadVideoTask"
    m.top.functionName = "LoadVideo"
end sub

sub LoadVideo()
    print "!!welcome LoadVideo (task)"
    uriResult = GetMediaURIs()
    if (m.global.FederatedToken = "error" or uriResult = "error")
        print "!!error in LoadVideo"
        m.top.videoReady = false
        m.global.wanLiveM3u8Uri = "error"
        print "!!error in LoadVideo, wanLiveM3u8Uri is: "; m.global.wanLiveM3u8Uri
        return
    end if
    print "!!welcome LoadVideo: FederateToken "; m.global.FederatedToken
    print "!!welcome LoadVideo: wanMedia "; m.global.wanLiveM3u8Uri
    m.top.videoReady = true
end sub

Function GetMediaURIs() As String
    url = "https://api2.rhombussystems.com/api/camera/getMediaUris"

    apiKey = m.global.APIKey
    print("getting url: " + url)
    print "howdy url "; url
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.setRequest("POST")
    cameraUUID = m.global.CurrentCameraUUID
   
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
    print "responseCode: "
    print responseCode
    if (responseCode <> 200)
        print "!!error in Get media uRI"
        return invalid
    end if
    print("2 about to wait")
    response = wait(0, port)
    print response
    print response.GetResponseCode()
    print response.GetFailureReason()
    print("2 done waiting")
    responseCode = response.GetResponseCode()
    print "2 responseCode: "
    print(responseCode)
    print "2 failReason: "
    failReason = response.GetFailureReason()
    print(failReason)
    responseBody = ParseJSON(response.GetString())
    m.global.SetField("wanLiveM3u8Uri", responseBody.wanLiveM3u8Uri)
    if (responseBody.wanLiveM3u8Uri = invalid)
        print "responseBody is invalid, no WAN uri for "; cameraUUID
        return "error"
    end if
    return responseBody.wanLiveM3u8Uri
end function

