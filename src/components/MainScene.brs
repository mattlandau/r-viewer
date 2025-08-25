sub init()
    InitializeComponents()
    CreateObservers()
    m.Timer.control = "start"

    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    print "Display Size: "; displaySize.w; "x"; displaySize.h
    m.global.AddFields({
        ActualDeviceCount: 0,
        APIKey: "",
        AuthenticationError: false,
        DeviceURIStems: CreateObject("roAssociativeArray"),
        DeviceNames: CreateObject("roAssociativeArray"),
        FederatedToken: "",
        LoadingState: "",
        SelectedVideoWallIndex: 0,
        PreviousVideoWallIndex: -1,
        SelectedThumbnailIndex: 0,
        PlaceholderImage: "pkg:/images/focus-sd-1-0.png",
        CurrentCameraUUID: "",
        wanLiveM3u8Uri: "",
        RefreshCounter: 0,
        ScreenWidth: displaySize.w,
        ScreenHeight: displaySize.h,
        Timestamp: 0,
        VideoWalls: []
    })
    m.global.SetField("deviceURIStems", CreateObject("roAssociativeArray"))
    m.global.SetField("deviceNames", CreateObject("roAssociativeArray"))

    readAPIKey()
    createGetVideoWallsTask()
    m.VideoWallList.setFocus(true)

    ' This is required to pass certification.
    ' Specified in section 3.2 of the Roku Certification Criteria.
    ' Reference: https://developer.roku.com/docs/developer-program/certification/certification.md#3-performance
    m.top.signalBeacon("AppLaunchComplete")
end sub

sub InitializeComponents()
    print "!!welcome InitializeComponents"
    m.LayoutContainer = m.top.FindNode("MyLayoutContainer")
    m.AccountButton = m.top.FindNode("MyAccountButton")
    m.VideoWallList = m.top.FindNode("MyList")
    m.GetVideoWallTask = CreateObject("roSGNode", "GetVideoWallsTask")
    m.APIKeyError = m.top.FindNode("APIKeyError")
    m.VideoPlayer = m.top.findNode("MyVideoPlayer")
    m.MyVideo = m.top.FindNode("MyVideo")
    m.Registry = CreateObject("roRegistrySection", "RhombusApp")
    m.Timer = m.top.FindNode("MyTimer")
    m.ThumbnailGrid = m.top.findNode("ThumbnailGrid")
    m.GridLoadTask = createObject("roSGNode", "ContentReader")
    m.Timestamp = m.top.findNode("MyTimestamp")
    m.MyZeroDevicesLabel = m.top.FindNode("MyZeroDevicesLabel")
    m.AuthenticationTask = CreateObject("roSGNode", "MyAuthenticationTask")
    m.TimestampSpacer = m.top.FindNode("TimestampSpacer")
    m.GridLoadingSpinnerHorizontalSpacer = m.top.FindNode("GridLoadingSpinnerHorizontalSpacer")
    m.GridLoadingSpinnerVerticalSpacer = m.top.FindNode("GridLoadingSpinnerVerticalSpacer")
    m.ZeroDeviceHorizontalSpacer = m.top.FindNode("ZeroDevicesHorizontalSpacer")
    m.LoadVideoPlayerTask = CreateObject("roSGNode", "LoadVideoTask")
end sub


sub CreateObservers()
    m.AccountButton.observeField("resetGetVideoWallsTask", "GoResetGetVideoWallsTask")
    m.Timer.ObserveField("fire","TimerElapsed")
    m.VideoWallList.ObserveField("itemFocused", "OnSidebarFocusChange")
    m.GetVideoWallTask.observeField("requestTopNode", "onRequestTopNodeForVideoWallList")
    m.GetVideoWallTask.observeField("error", "callVideoWallListError")
    m.GridLoadTask.observeField("content", "showmarkupgrid")
    m.GridLoadTask.observeField("zeroDevices", "DisplayZeroDevices")
    m.LoadVideoPlayerTask.observeField("videoURLIsReady", "goVideoContent")
    m.MyVideo.observeField("state", "videoStateChanged")
end sub

sub videoStateChanged()
    print "!!wideoStateChanged: "; m.MyVideo.state
    if (m.MyVideo.state = "error")
        print "!!videoStateChanged "; m.MyVideo.errorMsg
        print "!!videoStateChanged "; m.MyVideo.errorCode
        print "!!videoStateChanged "; m.MyVideo.errorStr
        print "!!videoStateChanged "; m.MyVideo.streamformat
    end if
end sub

sub SetTimestampVisibility(show as Boolean)
    print "!!welcome SetTimestampVisibility, show: "; show.ToStr()
    if (show = true)
        m.Timestamp.visible = false
        m.Timestamp.scale = [ 0, 0 ]
        m.TimestampSpacer.visible = false
        m.TimestampSpacer.scale = [ 0, 0 ]
    else
        m.Timestamp.visible = true
        m.Timestamp.scale = [ 1, 1 ]
        m.TimestampSpacer.visible = true
        m.TimestampSpacer.scale = [ 1, 0.25 ]
    end if
end sub

function readAPIKey() as Boolean
    print "!!welcome readAPIKey"
    m.Registry = CreateObject("roRegistrySection", "RhombusApp")
    myText = m.Registry.Read("APIKey")
    m.global.APIKey = myText
    return true
end function

sub StopNonVideoTasks()
    print "!!welcome StopNonVideoTasks"
    m.GridLoadTask.control = "STOP"
    m.Timer.control = "stop"
end sub

sub StartNonVideoTasks()
    print "!!welcome StartNonVideoTasks"
    m.GridLoadTask.control = "RUN"
    m.Timer.control = "start"
end sub

sub DisplayZeroDevices()
    print "!!welcome DisplayZeroDevices"
    SetTimestampVisibility(false)
    if (m.GridLoadTask.zeroDevices = true)
        print "!!welcome DisplayZeroDevices: zero devices true"
        m.ZeroDeviceHorizontalSpacer.visible = true
        m.ZeroDeviceHorizontalSpacer.scale = [ 64, 1 ]
        m.MyZeroDevicesLabel.visible = true
        ' m.Timestamp.visible = false
        print "DisplayZeroDevices: thumbnailgrid visible false"
        m.ThumbnailGrid.visible = false
        m.ThumbnailGrid.scale = [ 0, 0 ]
    else
        print "!!welcome DisplayZeroDevices: zero devices false"
        print "DisplayZeroDevices: thumbnailgrid visible true"
        m.ZeroDeviceHorizontalSpacer.visible = false
        m.ZeroDeviceHorizontalSpacer.scale = [ 0, 0 ]
        m.MyZeroDevicesLabel.visible = false
        m.ThumbnailGrid.visible = true
        m.ThumbnailGrid.scale = [ 1, 1 ]
    end if
end sub

sub GoResetGetVideoWallsTask()
    print "!!welcome GoResetGetVideoWallsTask"
    m.GetVideoWallTask.control = "STOP"
    m.GetVideoWallTask.control = "RUN"
    m.VideoWallList.setFocus(true)
end sub

sub callVideoWallListError() 
    print "!!welcome callVideoWallListError"
    ShowAPIKeyError(m.GetVideoWallTask.error)
end sub

sub ShowAPIKeyError(error as boolean)
    print "!!welcome ShowAPIKeyError"
    print "m.GetVideoWallTask.error "; m.GetVideoWallTask.error.ToStr()

    if (error = true) 
        print "api key error true"
        m.APIKeyError.visible = true
        m.VideoWallList.visible = false
        m.Timestamp.visible = false
        m.AccountButton.SetFocus(true)
        m.GridLoadingSpinner.visible = false
        m.GridLoadingSpinner.scale = [ 0, 0 ]
    else
        print "api key error false"
        m.VideoWallList.visible = true
        if (m.GridLoadTask.zeroDevices = true)
            print "!!welcome callVideoWallListError: zero devices true"
            print "callVideoWallListError: thumbnailgrid visible false"
            m.ThumbnailGrid.visible = false
        else
            print "!!welcome callVideoWallListError: zero devices false"
            print "callVideoWallListError: thumbnailgrid visible true"
            m.ThumbnailGrid.visible = true
        end if
        m.Timestamp.visible = true
        m.APIKeyError.visible = false
    end if
end sub

sub TimerElapsed()
    print "!!welcome TimerElapsed"
    print "getVideoWallsTask: "; m.GetVideoWallTask.state
    if (m.GetVideoWallTask.state = "stop" and m.GetVideoWallTask.error = true)
        print "!!welcome TimerElapsed: make it run"
        m.GetVideoWallTask.control = "RUN"

    end if
    if (m.global.AuthenticationError = true)
        print "!!welcome TimerElapsed: authentication error true"
        ShowAPIKeyError(true)
    else 
        print "!!welcome TimerElapsed: authentication error false"
        ShowAPIKeyError(false)
    end if

    print "m.GridLoadTask.state: "; m.GridLoadTask.state
    if (m.GridLoadTask.state <> "run")
        print "!!welcome TimerElapsed: grid load task is not running, will refresh"
        m.Timestamp.fireUpdate = true
        m.global.RefreshCounter = m.global.RefreshCounter + 1
        UpdateGrid()
    else
        print "!!welcome TimerElapsed: grid load task is running, will not refresh"
    end if
end sub

sub showmarkupgrid()
    print "!!welcome showThumbnailGrid (main); itemSelected: "; m.ThumbnailGrid.itemSelected.ToStr()
    m.ThumbnailGrid.content = m.GridLoadTask.content
    m.Timestamp.fireUpdate = true
end sub

sub showVideoWallThumbnailGrid()
    print "!!welcome showVideoWallThumbnailGrid"
    m.VideoThumbnailGrid.content = m.LoadVideoWallThumbnailsTask.content
end sub

sub onRequestTopNodeForVideoWallList()
    print "!!welcome onRequestTopNodeForVideoWallList"
    if (m.GetVideoWallTask.requestTopNode = true)
        m.GetVideoWallTask.topNode = m.top ' Pass reference to scene
    end if
end sub

sub onRequestTopNodeForVideoWallThumbnails()
    print "!!welcome onRequestTopNodeForVideoWallThumbnails"
    if (m.LoadVideoWallThumbnailsTask.requestTopNode = true)
        m.LoadVideoWallThumbnailsTask.topNode = m.top ' Pass reference to scene
    end if
end sub

sub createGetVideoWallsTask()
    print "!!welcome GetVideoWalls task"
    m.GetVideoWallTask.control = "RUN"
end sub

sub OnSidebarFocusChange()
    print "sidebar focus changed from: "; m.focusedIndex
    
    m.focusedIndex = m.VideoWallList.itemFocused
    print "sidebar focus changed to: "; m.focusedIndex
    m.global.PreviousVideoWallIndex = m.global.SelectedVideoWallIndex
    m.global.SelectedVideoWallIndex = m.focusedIndex
    UpdateGrid()
end sub

Function DevicesCountCurrentWall() as integer
    print "!!welcome DevicesCount (main)"
    if (m.global.VideoWalls = invalid or m.global.VideoWalls.count() = 0)
        print "devicescount returning 0"
        return 0
    end if
    devices = m.global.VideoWalls[m.global.SelectedVideoWallIndex].deviceList
    if (devices = invalid)
        print "devicescount returning 0"
        return 0
    end if
    print "devicescount returning "; devices.count().ToStr()
    m.global.ActualDeviceCount = devices.count()
    return devices.count()
end function

sub UpdateGrid() 
    print "!!welcome UpdateGrid"

    if (m.global.VideoWalls = invalid or m.global.VideoWalls.count() = 0)
        print "!!error in UpdateGrid: no video walls"
        return
    end if
    if (m.global.SelectedVideoWallIndex < 0 or m.global.SelectedVideoWallIndex >= m.global.VideoWalls.count())
        print "!!error in UpdateGrid: invalid video wall index"
        return
    end if
    if (m.global.VideoWalls[m.global.SelectedVideoWallIndex] = invalid)
        print "!!error in UpdateGrid: video wall invalid"
        return
    end if
    if (m.global.VideoWalls[m.global.SelectedVideoWallIndex].deviceList = invalid)
        print "!!error in UpdateGrid: no devices"
        return
    end if
    devices = m.global.VideoWalls[m.global.SelectedVideoWallIndex].deviceList
    if (devices.count() > 0)
        for each device in devices
            print "UpdateGrid device: "; device
        end for
    end if

    RestartThumbnailGridTask()
end sub

sub RestartThumbnailGridTask()
    print "starting RestartThumbnailGridTask"
    if (m.focusedIndex >= 0)
        if (m.ThumbnailGrid.itemFocused <> invalid)
            print "!!welcome RestartThumbnailGridTask: itemFocused: "; m.ThumbnailGrid.itemFocused.ToStr()
            if (m.ThumbnailGrid.itemFocused < 1)
                m.global.SelectedThumbnailIndex = 0
            else
                m.global.SelectedThumbnailIndex = m.ThumbnailGrid.itemFocused
            end if
        end if
    
    end if
    m.GridLoadTask.control = "STOP"
    print "!!welcome RestartThumbnailGridTask: m.GridLoadTask.control = STOP"
    m.GridLoadTask.control = "RUN"
    print "!!welcome RestartThumbnailGridTask: m.GridLoadTask.control = RUN"
end sub

sub HandleThumbnailClick() 
    print "!!welcome HandleThumbnailClick"
    print "HandleThumbnailClick itemFocused: "; m.ThumbnailGrid.itemFocused.ToStr()
    m.global.SetField("SelectedThumbnailIndex", m.ThumbnailGrid.itemFocused)
    focusedItem = m.ThumbnailGrid.content.GetChild(m.global.SelectedThumbnailIndex)
    m.global.SetField("CurrentCameraUUID", focusedItem.GetField("cameraUUID"))

    m.LayoutContainer.visible = false
    m.VideoPlayer.visible = true

    m.LoadVideoPlayerTask.control = "RUN"
    StopNonVideoTasks()

end sub

sub goVideoContent()
    print "!!welcome goVideoContent (main)"

    focusedItem = m.ThumbnailGrid.content.GetChild(m.global.SelectedThumbnailIndex)
    print "goVideoContent focusedItem: "; focusedItem
    ' if (focusedItem = invalid)
    '     print "!!error in goVideoContent: focusedItem invalid"
    '     return
    ' end if
    cameraUUID = focusedItem.GetField("cameraUUID")
    print "goVideoContent cameraUUID: "; cameraUUID

    print "goVideoContent url: "; m.global.wanLiveM3u8Uri
    m.VideoPlayer.callFunc("showVideoContent")    

end sub

sub HandleVideoBack() 
    print "HandleVideoBack MyVideo.state: "; m.MyVideo.state
    m.MyVideo.control = "stop"
    print "HandleVideoBack MyVideo.state: "; m.MyVideo.state
    m.LoadVideoPlayerTask.videoURLIsReady = false
    m.LoadVideoPlayerTask.control = "STOP"
    m.VideoPlayer.visible = false
    m.MyVideo.content = invalid
    m.LayoutContainer.visible = true
    m.global.wanLiveM3u8Uri = "error"
    StartNonVideoTasks()
end sub

function OnKeyEvent(key as String, press as Boolean) as Boolean
    print "key press (main)" + key
    if (not press) 
        return false
    end if
    
    m.lastKey = key ' Store last key press
    
    if (key = "back" and m.VideoPlayer.visible <> true)
        ' Handle back button
        print "back pressed"
        return false
    else if (key = "back" and m.VideoPlayer.visible = true)
        print "back pressed on video player"
        HandleVideoBack()
        return true
    else if (key = "OK" and m.ThumbnailGrid.HasFocus())
        print "OK pressed on ThumbnailGrid"
        HandleThumbnailClick()
        return true
    else if (key = "OK" and m.VideoWallList.HasFocus())
        m.VideoWallList.SetFocus(false)
        m.ThumbnailGrid.SetFocus(true)
        m.ThumbnailGrid.jumpToItem = 0
        return true
    else if (key = "up" and m.VideoWallList.HasFocus())
        m.VideoWallList.SetFocus(false)
        m.AccountButton.SetFocus(true)
        return true
    else if (key = "down" and m.AccountButton.HasFocus())
        m.VideoWallList.SetFocus(true)
        m.AccountButton.SetFocus(false)
        return true
    else if (key = "right" and m.VideoWallList.HasFocus())
        m.VideoWallList.SetFocus(false)
        m.ThumbnailGrid.SetFocus(true)
        return true
    else if (key = "left" and m.ThumbnailGrid.HasFocus())
        m.VideoWallList.SetFocus(true)
        m.ThumbnailGrid.SetFocus(false)
        return true
    end if
    print "no handler called for key: "; key
    return false
end function
