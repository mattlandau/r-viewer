sub init ()
    print "!!welcome VideoPlyaer.brs"
    m.VideoComponent = m.top.findNode("MyVideo")
    print "VideoPlayer.brs VideoComponenet: "; m.VideoComponent
end sub

sub showVideoContent()
    print "!!welcome showVideoContent (VideoComponent.bs)"
    print m.top.content
    url = m.global.wanLiveM3u8Uri
    ' url = m.global.wanLiveMpdUri
    ' if (url = "error")
    '     print "!!error in showVideoContent, url is _error_"
    '     m.videoContent = invalid
    '     return
    ' end if
    print "!!welcome showVideoContent, url is: "; url
    m.videoContent = createObject("RoSGNode", "ContentNode")
    m.videoContent.url = url
    m.videoContent.live = true
    ' m.videoContent.playstart = 0
    ' m.videoContent.streamformat = "mp4"
    m.videoContent.title = "Loading..."
    ' m.videoContent.IsHD = false
    httpAgent = CreateObject("roHttpAgent")
    APIKey = m.global.APIKey
    httpAgent.AddHeader("x-auth-apikey", APIKey)
    httpAgent.AddHeader("x-auth-scheme", "api-token")
    ' FederatedToken = m.global.FederatedToken
    ' httpAgent.AddHeader("Cookie", "RSESSIONID=RFT:" + FederatedToken)
    m.VideoComponent.setHttpAgent(httpAgent)
    m.VideoComponent.content = m.videoContent
    ' m.VideoComponenet.IsHD = true
    m.VideoComponent.control = "play"

    ' print "!!welcome showVideoContent FederatedToken is: "; FederatedToken
    print "!!welcome showVideoContent, videoContent is: "; m.videoContent
    print "!!welcome showVideoContent, videoComponent is: "; m.VideoComponent.state
    print "!!welcome showVideoContent, videoContent is: "; m.VideoContent.state
    print "!!welcome showVideoContent - exiting sub"
end sub
