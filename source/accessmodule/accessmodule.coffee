############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("accessmodule")
#endregion

############################################################
import * as validStamp from "validatabletimestamp"
import * as secUtl from "secret-manager-crypto-utils"
import { STRINGHEX32, STRINGHEX64, STRINGHEX128, NUMBER, 
    createValidator } from "thingy-schema-validate"

############################################################
import * as sS from "./signencstoremodule.js"

############################################################
validateAuthMessage = createValidator({
    randomHex: STRINGHEX32
    timestamp: NUMBER
    publicKey: STRINGHEX64
    signature: STRINGHEX128
})

############################################################
authCodeToHandle = Object.create(null)
adminAccessKeys = []

############################################################
STOREKEY = "accessStore"
store = null
############################################################
save = -> sS.save(STOREKEY)


############################################################
authorizedKeys = new Set()

############################################################
cleanoutIntervalMS = 360_000 # 6min


############################################################
export initialize = (c) ->
    log "initialize"        
    store = await sS.load(STOREKEY)
    if store.authCodeToHandle? then authCodeToHandle = store.authCodeToHandle
    else store.authCodeToHandle = authCodeToHandle

    if store.adminAccessKeys? then adminAccessKeys = store.adminAccessKeys
    else store.adminAccessKeys = adminAccessKeys
    authorizedKeys = new Set(adminAccessKeys)

    if c.fallbackAuthCode 
        authCodeToHandle[c.fallbackAuthCode] = {}
    
    setInterval(cleanoutAccess, cleanoutIntervalMS)
    cleanoutAccess()
    return

############################################################
cleanoutAccess = ->
    log "cleanoutAccess"
    now = Date.now()
    for code, handle of authCodeToHandle
        if now > handle.timeOfDeath then delete authCodeToHandle[code]
    return save()

############################################################
export setAccess = (authCode, ttlMS) ->
    log "setAccess"
    log authCode
    log ttlMS

    timeOfDeath = Date.now() + ttlMS

    handle = authCodeToHandle[authCode]
    if handle? then handle.timeOfDeath = timeOfDeath
    else handle = { timeOfDeath }

    authCodeToHandle[authCode] = handle
    return save()

############################################################
export unsetAccess = (authCode) ->
    log "unsetAccess"

    handle = authCodeToHandle[authCode]
    return unless handle? # already removed

    delete authCodeToHandle[authCode]
    return save()

############################################################
export setAdminKeys = (adminKeys) ->
    log "setAdminKeys"
    store.adminAccessKeys = adminKeys
    adminAccessKeys = adminKeys
    authorizedKeys = new Set(adminKeys)
    return save() 


############################################################
export hasAccess = (authCode) -> authCodeToHandle[authCode]?

export authorizeAdmin = (authMessage) ->
    log "authorizeAdmin"
    authObj = JSON.parse(authMessage)
    err = validateAuthMessage(authObj)
    if err then return err

    err = validStamp.checkValidity(authObj.timestamp)
    if err then return "Invalid Timestamp!"

    pubKey = authObj.publicKey
    return "Key not Known!" unless authorizedKeys.has(pubKey)

    sigHex = authObj.signature
    content = authMessage.replace(sigHex, "")
    isValid = await secUtl.verify(sigHex, pubKey, content)
    if !isValid then return "Invalid Signature!"
    return