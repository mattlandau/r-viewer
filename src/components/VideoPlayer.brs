sub init ()
    print "DEBUGLOG: VideoPlyaer.brs"
    m.VideoComponent = m.top.findNode("MyVideo")
    print "VideoPlayer.brs VideoComponenet: "; m.VideoComponent
end sub

sub showVideoContent()
    print "DEBUGLOG: showVideoContent (VideoComponent.bs)"
    print m.top.content
    url = m.global.wanURI + "?_ds=h480b480"

    print "DEBUGLOG: showVideoContent, url is: "; url
    m.videoContent = createObject("RoSGNode", "ContentNode")
    m.videoContent.url = url
    m.videoContent.live = true

    m.videoContent.title = "Loading..."

    httpAgent = CreateObject("roHttpAgent")
    APIKey = m.global.APIKey
    httpAgent.AddHeader("x-auth-apikey", APIKey)
    httpAgent.AddHeader("x-auth-scheme", "api-token")

    m.VideoComponent.setHttpAgent(httpAgent)
    m.VideoComponent.content = m.videoContent

    m.VideoComponent.control = "play"

    print "DEBUGLOG: showVideoContent, videoContent is: "; m.videoContent
    print "DEBUGLOG: showVideoContent, videoComponent is: "; m.VideoComponent.state
    print "DEBUGLOG: showVideoContent, videoContent is: "; m.VideoContent.state
    print "DEBUGLOG: showVideoContent - exiting sub"
end sub
