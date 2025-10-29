############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("accessmodule")
#endregion

############################################################
import * as cfg from "./configmodule.js"

############################################################
authCodeToHandle = {}

############################################################
export initialize = ->
    log "initialize"
    if cfg.fallbackAuthCode 
        authCodeToHandle[cfg.fallbackAuthCode] = fbHandle 
    #Implement or Remove :-)
    return

export setAccess = (authCode, ttlS) ->
    log "setAccess"
    tllMS = tllS * 1000 # get time to live in Milliseconds
    deathHappens = () -> unsetAccess(authCode)

    handle = authCodeToHandle[authCode]
    if handle? then clearTimeout(handle.deathTimerID)
    else handle = {}

    if !handle.sockets? then handle.sockets = new Set()

    handle.deathTimerID = setTimeout(deathHappens, tllMS)    
    return

export unsetAccess = (authCode) ->
    log "unsetAccess"
    handle = authCodeToHandle[authCode]
    return unless handle? # already removed

    delete authCodeToHandle[authCode]
    return


export checkSocket = (authCode, socket) ->
    log "checkSocket"
    handle = authCodeToHandle[authCode]
    if !handle? then throw new Error("Invalid AuthCode!")
