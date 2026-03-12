############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("accessmodule")
#endregion

############################################################
import * as secUtl from "secret-manager-crypto-utils"
import { STRINGHEX32, STRINGHEX64, STRINGHEX128, NUMBER, 
    createValidator } from "thingy-schema-validate"

############################################################
validateAuthMessage = createValidator({
    randomHex: STRINGHEX32
    timestamp: NUMBER
    publicKey: STRINGHEX64
    signature: STRINGHEX128
})

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

export authorizeAdmin = (authMessage) ->
    log "authorizeAdmin"
    authObj = JSON.parse(authMessage)
    err = validateAuthMessage(authObj)
    if err then return err

    pubKey = authObj.publicKey
    return "Key not Known!" unless authorizedKeys.has(pubKey)

    sigHex = authObj.signature
    content = authMessage.replace(sigHex, "")
    isValid = await secUtl.verify(sigHex, pubKey, content)
    if !isValid then return "Invalid Signature!"
    return

############################################################
export setAdminKeys = (adminKeys) ->
    log "setAdminKeys"
    
    return
