sub Init()
    m.top.functionName = "getVideoWallsTask"
    print "!!welcome getVideoWallTask"
end sub

function getVideoWallsTask() as Boolean
    print "!!welcome getVideoWallsTask"
    wallNames = GetVideoWalls()
    if (wallNames.count() = 0)
        print "!!error in getVideoWallsTask"
        m.top.error = true
    else
        print "!!success in getVideoWallsTask"
        setVideoWallList(wallNames)
        m.top.error = false
    end if
    return true
end function

sub assignTopNode()
    print "!!welcome assignTopNode"
    m.top.requestTopNode = true
    while (m.top.topNode = invalid)
        print "sleeping 1 sec"
        sleep(1000)       
    end while   
    m.topNode = m.top.topNode
    print "Got top node: "
end sub

sub setVideoWallList(wallNames as Object)
    print "welcome setVideoWallList"
    assignTopNode()
    m.MyList = m.topNode.findNode("MyList")

    m.VideoWallList = m.MyList.content

    for each name in wallNames 
        print name
        temp = m.VideoWallList.createChild("ContentNode")
        temp.title = name
    end for 

    print "finished setVideoWallList"
end sub


function GetVideoWalls() as Object
    print "!!welcome to GetVideoWalls (GetVideoWallsTask)"
    url = "https://api2.rhombussystems.com/api/camera/getVideoWalls"
    APIKey = m.global.APIKey
    if (APIKey.Len() < 22)
        print "!!error in GetVideoWalls - APIKey is too short"
        return []
    end if
    request = createObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.setURL(url)

    request.setHeaders({
        "content-type": "application/json",
        "x-auth-apikey": APIKey,
        "x-auth-scheme": "api-token",
        "accept": "application/json"
    })

    port = createObject("roMessagePort")
    requestBody = { }
    request.SetMessagePort(port)

    responseCode = request.AsyncPostFromString(formatJson(requestBody))
    
    print("GetVideoWalls - about to wait")
    response = wait(0, port)
    print("GetVideoWalls - done waiting")
    responseCode = response.GetResponseCode()
    if (responseCode <> 200)
        print "!!error in GetVideoWalls"
        print "responseCode: " + responseCode.ToStr()
        return []
    end if
    print "responseCode: " + responseCode.ToStr()
    failReason = response.GetFailureReason()
    print "failReason: " + failReason.ToStr()
    
    responseBody = ParseJSON(response.GetString())
    if (responseBody = invalid)
        print "GetVideoWalls responseBody is invalid"
        return []
    end if
    videoWalls = responseBody.videoWalls
    result = []
    print videoWalls
    for each videoWall in videoWalls
        result.push(videoWall.displayName)
    end for
    m.global.VideoWalls = videoWalls

    return result
End Function
