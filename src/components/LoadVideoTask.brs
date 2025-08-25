sub Init()
    print "!!welcome LoadVideoTask"
    m.top.functionName = "LoadVideo"
end sub

sub LoadVideo()
    print "!!welcome LoadVideo (task)"
    uriResult = GetMediaURIs()
    if (m.global.FederatedToken = "error" or uriResult = "error")
        print "!!error in LoadVideo"
        m.global.wanLiveM3u8Uri = "error"
        print "!!error in LoadVideo, wanLiveM3u8Uri is: "; m.global.wanLiveM3u8Uri; " videoReady is false"
        return
    end if
    print "!!welcome LoadVideo: FederateToken "; m.global.FederatedToken
    print "!!welcome LoadVideo: wanMedia "; m.global.wanLiveM3u8Uri
    
    m.top.videoURLIsReady = true
end sub

Function GetMediaURIs() As String
    url = "https://api2.rhombussystems.com/api/camera/getMediaUris"

    apiKey = m.global.APIKey
    print("GetMediaURIs - getting url: " + url)
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
    print "GetMediaURIs responseCode: " + responseCode.ToStr()

    if (responseCode <> 200)
        print "!!error in Get media uRI"
        return invalid
    end if
    print("GetMediaURIs about to wait")
    response = wait(0, port)

    print("GetMediaURIs - done waiting")
    responseCode = response.GetResponseCode()
    print "GetMediaURIs - responseCode: " + responseCode.ToStr()
    failReason = response.GetFailureReason()
    print "GetMediaURIs - failReason: " + failReason.ToStr()
    responseBody = ParseJSON(response.GetString())
    print "GetMediaURIs - responseBody: "; responseBody
    if (responseBody <> invalid and responseBody.wanLiveM3u8Uri <> invalid)
        m.global.SetField("wanLiveM3u8Uri", responseBody.wanLiveM3u8Uri)
        print "GetMediaURIs - wanLiveM3u8Uri for "; cameraUUID; " is "; responseBody.wanLiveM3u8Uri
    else
        print "responseBody is invalid, no WAN uri for "; cameraUUID
        return "error"
    end if


    ' Create a URL transfer object
    ' urlTransfer = CreateObject("roUrlTransfer")
    ' urlTransfer.SetUrl(responseBody.wanLiveM3u8Uri)

    ' Fetch the data
    ' responseText = urlTransfer.GetToString()
    ' print "GetMediaURIs Response Text: " + responseText



    return responseBody.wanLiveM3u8Uri
    ' return responseBody.wanLiveMpdUri
    ' return responseBody.wanLiveH264Uri

end function

