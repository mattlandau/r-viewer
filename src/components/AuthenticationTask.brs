sub init()
    m.top.functionName = "TryAuthenticating" 
end sub

sub TryAuthenticating()
    print "DEBUGLOG: to TryAuthenticating"
    error = true
    federatedToken = GetFederatedToken(m.global.APIKey)
    if (federatedToken <> "error")
        print "!!success in TryAuthenticating"
        m.global.FederatedToken = federatedToken
        Notify_Roku_UserIsLoggedIn()
        print "Roku authenticated via authentication (task)"
        error = false
        m.global.AuthenticationError = false
        m.top.error = false
    else
        m.global.AuthenticationError = true
        m.top.error = error
    end if
    m.top.finished = true
end sub

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
  
  Function GetFederatedToken(APIKey as String) as String
      print "DEBUGLOG: to getFederaredToken"
      url = "https://api2.rhombussystems.com/api/org/generateFederatedSessionToken"
      request = createObject("roUrlTransfer")
      request.setRequest("POST")
      requestBody = { "durationSec": 14400 }
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
      print("Notify_Roku_UserIsLoggedIn - about to wait")
      response = wait(0, port)
      print("Notify_Roku_UserIsLoggedIn  - done waiting")
      responseCode = response.GetResponseCode()
      print(responseCode)
      if (responseCode <> 200)
          print "!!error in GetFederatedToken"
          print "GetFederatedToken responseCode: " + responseCode.ToStr()
          return "error"
      end if
      failReaseon = response.GetFailureReason()
      print "GetFederatedToken - failReaseon: " + failReaseon.ToStr()
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
  