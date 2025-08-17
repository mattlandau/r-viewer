
sub init()
  m.top.id = "markupgriditem"
  m.itemposter = m.top.findNode("itemPoster") 
  m.focuslabel = m.top.findNode("focusLabel")
  m.itemLabel = m.top.findNode("itemLabel")
  m.cameraUUIDLabel= m.top.findNode("cameraUUID")
end sub

sub showcontent()
  print "!!welcome markupgriditem showcontent"
  itemcontent = m.top.itemContent
  m.itemposter.uri = itemcontent.hdgridposterurl
  print "DEBUG DEBUG DEBUG: itemLabel: " + m.itemLabel.text + " itemPoster: " + m.itemposter.uri
  m.itemLabel.text = itemcontent.title
  m.cameraUUIDLabel.text = itemcontent.cameraUUID
  print "cameraUUID.text: "; m.cameraUUIDLabel.text 
end sub

function OnKeyEvent(key as String, press as Boolean) as Boolean
  print "!!welcome markupgriditem onKeyPress"
  print "key press (griditem) " + key + " " + press.ToStr()
  return true
end function

sub showfocus()
  scale = 1 + (m.top.focusPercent * 0.02)
  m.itemposter.scale = [scale, scale]
end sub
