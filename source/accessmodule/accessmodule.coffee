############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("accessmodule")
#endregion

############################################################
authCodeToHandle = Object.create(null)
## TODO upgrade the authCode Cancellation situation

############################################################
export initialize = (c) ->
    log "initialize"
    if c.fallbackAuthCode 
        authCodeToHandle[c.fallbackAuthCode] = {}
    return

############################################################
export setAccess = ({ authCode, ttlMS }) ->
    log "setAccess"
    log authCode
    log ttlMS

    deathHappens = () -> unsetAccess(authCode)

    handle = authCodeToHandle[authCode]
    if handle? then clearTimeout(handle.deathTimerId)
    else handle = {}

    handle.deathTimerId = setTimeout(deathHappens, ttlMS)    
    authCodeToHandle[authCode] = handle
    return

############################################################
export unsetAccess = (authCode) ->
    log "unsetAccess"

    handle = authCodeToHandle[authCode]
    return unless handle? # already removed

    clearTimeout(handle.deathTimerId)
    delete authCodeToHandle[authCode]
    return

############################################################
export hasAccess = (authCode) -> authCodeToHandle[authCode]?
