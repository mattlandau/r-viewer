sub init()
  print "DEBUGLOG: account button"
  m.topNode = m.top.GetScene()
  m.AccountButton = m.top.findNode("MyAccountButton")
  m.AccountButton.observeField("buttonSelected", "onButtonPressed")
  m.keyboarddialog = createObject("roSGNode", "StandardKeyboardDialog")
end sub

sub onAuthenticationTaskError(event as Object)
  data = event.getData()
  print "onAuthenticationTaskError data: "; data
  m.top.error = data
end sub


sub onButtonPressed(event as Object) 
    print "called onButtonPressed"
    button = event.getRoSGNode()
    print "Button with ID " + button.id + " was pressed!"
    showdialog()

end sub

sub showdialog()
    print "called show dialog"
    print "voice enabled: "
    print m.keyboarddialog.textEditBox.voiceEnabled
    m.keyboarddialog.textEditBox.voiceEnabled = true
    m.keyboarddialog.title = "API Key"
    m.keyboarddialog.textEditBox.secureMode = true
    m.keyboarddialog.buttons = ["OK"]
    m.keyboarddialog.text = m.global.APIKey
  
    m.keyboarddialog.observeField("buttonSelected", "OnKeyboardDialogButtonPressed")
    m.topNode.dialog = m.keyboarddialog
    print "should now be showing keyboard dialog"
end sub

sub OnKeyboardDialogButtonPressed(event as Object)
  buttonIndex = event.getData()
  keyboardDialog = event.getRoSGNode()

  
  if (buttonIndex = 0)  ' OK button
      enteredText = keyboardDialog.text
      print "OK pressed with text:: "; enteredText

      m.global.APIKey = enteredText
      m.Registry = CreateObject("roRegistrySection", "RhombusApp")
      m.Registry.Write("APIKey", enteredText)
      m.Registry.Flush()
      m.top.resetGetVideoWallsTask = true
      keyboardDialog.close = true
      
      m.AuthenticationTask = createObject("roSGNode", "MyAuthenticationTask")
      m.AuthenticationTask.control = "RUN"
  end if
end sub

sub ResetRelevantGlobals()
    m.global.AddFields({
      CurrentCameraUUID: "",
      wanLiveM3u8Uri: "",
      Timestamp: 0
  })
end sub
