sub init()
    m.defaultFormat = "MM/dd/yyyy hh:mm a"
    m.top.text = ""
end sub

sub updateTimestamp()
    print "!!welcome updateTimestamp"
    if (m.top.fireUpdate = false)
        return
    end if

    timestamp = m.global.Timestamp
    if (timestamp = invalid or timestamp = 0)
        m.top.text = ""
        return
    end if
    
    dateTime = CreateObject("roDateTime")
    dateTime.FromSeconds(timestamp)

    dateTime.ToLocalTime()
    date = dateTime.asDateStringLoc("short")
    time = dateTime.asTimeStringLoc("short-h24")
    seconds = dateTime.GetSeconds()
    if (seconds <> invalid)
        m.top.text = "  Last image pulled in on " + date + ", " + time + ":" + ZeroPadInteger(seconds,2) + "  "
    end if 
    m.top.fireUpdate = false
end sub

function ZeroPadInteger(num as Integer, length as Integer) as String
    numStr = num.ToStr()
    paddingNeeded = length - numStr.Len()
    return String(paddingNeeded, "0") + numStr
end function
