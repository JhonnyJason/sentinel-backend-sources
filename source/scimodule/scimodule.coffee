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
import { passphrase } from "./configmodule.js"
#endregion

############################################################
returnCurrentState = (req, res) ->
    res.send(getState())

############################################################
export prepareAndExpose = ->
    log "prepareAndExpose"

    sciBase.prepareAndExpose(null, { "getState": returnCurrentState })

    sciBase.onWebsocketConnect("/", onConnect)
    log "Server listening!"
    log "passphrase is: #{passphrase}"
    return
