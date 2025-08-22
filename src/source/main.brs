sub main()
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    m.global = screen.getGlobalNode()
    mainScene = screen.CreateScene("MainScene")
    screen.show()
    print "!!mainScene: "; mainScene.visible
    
    m.Registry = CreateObject("roRegistrySection", "RhombusApp")
    APIKey = m.Registry.Read("APIKey")
    if (APIKey <> invalid)
        SetFederatedToken(APIKey)

    end if

    StartRepeatingTask()
    StartRepeatingFederatedTokenGeneration()

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if (msgType = "roSGScreenEvent")
            if (msg.isScreenClosed())
                return
            end if
        end if
    end while
end sub

sub SetFederatedToken(APIKey as String)
    federatedToken = "error"
    federatedToken = GetFederatedToken(APIKey)
    if (federatedToken <> "error")
        ' print "!!federatedToken: "; federatedToken 'REMOVE
        Notify_Roku_UserIsLoggedIn()
        print "!!Roku_Authenticated event dispatched via main (task)"
        m.global.AuthenticationError = false
    else 
        print "!!error in GetFederatedToken"
        m.global.AuthenticationError = true
    end if
    m.global.SetField("FederatedToken", federatedToken)
end sub


sub PrintDir(path as string)
    m.fs = CreateObject("roFileSystem")
    tempDir = m.fs.GetDirectoryListing(path)
    print tempDir
end sub

sub DeleteTempFiles()
    tmpDir = m.fs.GetDirectoryListing("tmp:/")
    for each file in tmpDir
        extractedRefreshCounter = ExtractRefreshCounter(file, 0, 7)
        cutoff = m.global.RefreshCounter - 1
        if (extractedRefreshCounter < cutoff)
            print "Refreshcounter: "; extractedRefreshCounter; "Cutoff: "; cutoff.ToStr(); ". Will delete file: "; file
            DeleteFile("tmp:/" + file)
        else
            print "Refreshcounter: "; extractedRefreshCounter; "Cutoff: "; cutoff.ToStr(); ". File is not old enough to delete: "; file
        end if

    end for
end sub

Function ExtractRefreshCounter(inputString as String, startIndex as Integer, endIndex as Integer) as Integer
    substring = inputString.Mid(startIndex, endIndex - startIndex + 1)
    return substring.ToInt()
end function

Function StartRepeatingTask() as String
    print "Starting timer...."

    counter = 1
    while (true)
        PrintDir("tmp:/")
        counter = counter + 1

        sleep(60000)
        DeleteTempFiles()
        ' Yield execution to avoid freezing
        sleep(500) ' Small delay to reduce CPU usage
    end while
    return ""
End Function

Function StartRepeatingFederatedTokenGeneration() as String
    print "Starting timer repeat get federated token...."
    APIKey = m.Registry.Read("APIKey")

    minutes = 1380
    seconds = minutes * 60
    milliseconds = seconds * 1000
    while (true)


        sleep(milliseconds)
        SetFederatedToken(APIKey)
        ' Yield execution to avoid freezing
        sleep(500) ' Small delay to reduce CPU usage
    end while
    return ""
End Function

Function GetUnixEpoch() As Integer
    print("getting epoch")
    dt = CreateObject("roDateTime")
    dt.Mark()
    result = dt.AsSeconds() - 60
    print(result)
    return Abs(result)
End Function

Function GetFederatedToken(APIKey as String) as String
    print "!!welcome to getFederaredToken"
    url = "https://api2.rhombussystems.com/api/org/generateFederatedSessionToken"
    request = createObject("roUrlTransfer")
    request.setRequest("POST")
    requestBody = { "durationSec": 14400 }
    print requestBody
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.setHeaders({
        "content-type": "application/json",
        "x-auth-apikey": APIKey,
        "x-auth-scheme": "api-token",
        "accept": "application/json",
        "pragma": "no-cache"
    })
    port = createObject("roMessagePort")
    request.SetMessagePort(port)
    responseCode = request.AsyncPostFromString(formatJson(requestBody))
    print("GetFederatedToken - about to wait")
    response = wait(0, port)
    print("GetFederatedToken - done waiting")
    responseCode = response.GetResponseCode()
    if (responseCode <> 200)
        print "!!error in GetFederatedToken - " + responseCode.ToStr()
        return "error"
    end if
    print "GetFederatedToken - responseCode - " + responseCode.ToStr()
    failReaseon = response.GetFailureReason()
    print "GetFederatedToken - failReason - " + failReaseon.ToStr()
    ' print "GetFederatedToken - request - " + request
    responseBody = ParseJSON(response.GetString())
    if (responseBody = invalid)
        print "!!error in GetFederatedToken"
        return "error"
    end if
    if (responseBody.federatedSessionToken = invalid)
        print "!!error in GetFederatedToken"
        return "error"
    end if
    FederatedToken = responseBody.federatedSessionToken
    return FederatedToken
End Function

sub Notify_Roku_UserIsLoggedIn()

    globalNode = m.global

    ' get the Roku Analytics Component Library used for RED
    RAC = globalNode.roku_event_dispatcher
    if (RAC = invalid)
        RAC = createObject("roSGNode", "Roku_Analytics:AnalyticsNode")
        RAC.debug = true ' for verbose output to BrightScript console, optional
        RAC.init = {RED: {}} ' activate RED as a provider
        globalNode.addFields({roku_event_dispatcher: RAC})
    end if

    ' dispatch an event to Roku
    RAC.trackEvent = {RED: {eventName: "Roku_Authenticated"}}
    print "!!Roku_Authenticated event dispatched"
end sub
