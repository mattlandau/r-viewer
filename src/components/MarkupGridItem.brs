
sub init()
  m.top.id = "markupgriditem"
  m.itemposter = m.top.findNode("itemPoster") 
  m.focuslabel = m.top.findNode("focusLabel")
  m.itemLabel = m.top.findNode("itemLabel")
  m.cameraUUIDLabel= m.top.findNode("cameraUUID")
  m.busySpinner = m.top.findNode("busySpinner")
end sub

sub showcontent()
  print "DEBUGLOG: markupgriditem showcontent"
  print "m.itemposter.uri: " + m.itemposter.uri
  if (m.itemposter.uri = "")
    m.busySpinner.visible = true
  else
    m.busySpinner.visible = false
  end if
  itemcontent = m.top.itemContent
  m.itemposter.uri = itemcontent.hdgridposterurl

  timestamp = m.global.Timestamp
  dateTime = CreateObject("roDateTime")
  dateTime.FromSeconds(timestamp)
  dateTime.ToLocalTime()
  time = dateTime.asTimeStringLoc("short-h24")
  seconds = dateTime.GetSeconds()
  print "DEBUGLOG: markupgriditem showcontent, time is: "; time; " seconds is: "; seconds.ToStr()
  if (seconds <> invalid and time <> "19:00" and seconds <> 0)
      timestamp = " -- (" + time + ":" + ZeroPadInteger(seconds,2) + ")"
  else  
      timestamp = ""
  end if
  m.itemLabel.text = itemcontent.title + timestamp

  m.cameraUUIDLabel.text = itemcontent.cameraUUID
end sub

sub showfocus()
  scale = 1 + (m.top.focusPercent * 0.02)
  m.itemposter.scale = [scale, scale]
end sub

function ZeroPadInteger(num as Integer, length as Integer) as String
    numStr = num.ToStr()
    paddingNeeded = length - numStr.Len()
    return String(paddingNeeded, "0") + numStr
end function

