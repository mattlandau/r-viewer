
sub init()
  m.top.id = "markupgriditem"
  m.itemposter = m.top.findNode("itemPoster") 
  m.focuslabel = m.top.findNode("focusLabel")
  m.itemLabel = m.top.findNode("itemLabel")
  m.cameraUUIDLabel= m.top.findNode("cameraUUID")
  m.busySpinner = m.top.findNode("busySpinner")
end sub

sub showcontent()
  print "!!welcome markupgriditem showcontent"
  print "m.itemposter.uri: " + m.itemposter.uri
  if (m.itemposter.uri = "")
    m.busySpinner.visible = true
  else
    m.busySpinner.visible = false
  end if
  itemcontent = m.top.itemContent
  m.itemposter.uri = itemcontent.hdgridposterurl
  m.itemLabel.text = itemcontent.title
  m.cameraUUIDLabel.text = itemcontent.cameraUUID
end sub

sub showfocus()
  scale = 1 + (m.top.focusPercent * 0.02)
  m.itemposter.scale = [scale, scale]
end sub
