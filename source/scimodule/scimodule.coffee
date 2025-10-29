############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("scimodule")
#endregion

############################################################
#region modules from the Environment
import * as sciBase from "thingy-sci-ws-base"
import { onConnect } from "./wsimodule.js"
import { getState } from "./serverstatemodule.js"
import { checkOrThrow } from "./earlyblockermodule.js"
import { setAccess, unsetAccess } from "./accessmodule.js"

#endregion

############################################################
returnCurrentState = (req, res) ->
    res.send(getState())


############################################################
rejectForbidden = (req, res, next) ->
    ip = req.ip
    origin = req.origin
    try checkOrThrow(ip, origin)
    catch err then return res.status(403).send('Denied!')

    return next()

############################################################
setUserAccess = (req, res) ->
    try authenticateRequest(req.body)
    catch err then return res.status("403").send("Unauthorized!")

    try validateRequest(req.body)
    catch err then return res.status("400").send(err.message)
    
    try
        authCode = req.body.authCode
        ttlS = req.body.ttlS # time to live in seconds
        setAccess(authCode, ttlS)
        res.status(204).send()
    catch err then return res.status("500").send(err.message)
    return


############################################################
unsetUserAccess = (req, res) ->
    try authenticateRequest(req.body)
    catch err then return res.status("403").send("Unauthorized!")

    try validateRequest(req.body)
    catch err then return res.status("400").send(err.message)
    
    try
        authCode = req.body.authCode
        unsetAccess(authCode)
        res.status(204).send()
    catch err then return res.status("500").send(err.message)
    return


############################################################
export prepareAndExpose = ->
    log "prepareAndExpose"

    routes = {
        "getState": returnCurrentState,
        "grantAccess": setUserAccess,
        "revokeAccess": unsetUserAccess
    }

    sciBase.prepareAndExpose( rejectForbidden, routes )
    sciBase.onWebsocketConnect("/", onConnect)
    log "Server listening!"
    return
