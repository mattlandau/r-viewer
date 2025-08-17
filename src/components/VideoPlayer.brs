sub init ()
    print "!!welcome video player"
    m.VideoComponent = m.top.findNode("MyVideo")
    print m.VideoComponent
end sub

sub showTestContent()
    print "!!welcome video player showTestContent (VideoComponent.bs)"
    print m.top.myText
end sub

sub showVideoContent()
    print "!!welcome video player showVideoContent (VideoComponent.bs)"

    print m.top.content

    url = m.global.wanLiveM3u8Uri
    if (url = "error")
        print "!!error in showVideoContent, url is _error_"
        m.videoContent = invalid
        return
    end if
    
    m.videoContent = createObject("RoSGNode", "ContentNode")
    m.videoContent.url = url
    m.videoContent.live = true
    m.videoContent.playstart = 0
    m.videoContent.title = "Loading..."
    
    httpAgent = CreateObject("roHttpAgent")
    APIKey = m.global.APIKey
    httpAgent.AddHeader("x-auth-apikey", APIKey)
    httpAgent.AddHeader("x-auth-scheme", "api-token")
    FederatedToken = m.global.FederatedToken
    httpAgent.AddHeader("Cookie", "RSESSIONID=RFT:" + FederatedToken)
    m.VideoComponent.setHttpAgent(httpAgent)
    m.VideoComponent.content = m.videoContent
    m.VideoComponent.control = "play"
end sub
