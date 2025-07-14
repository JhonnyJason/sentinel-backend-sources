############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("startupmodule")
#endregion

############################################################
import * as sci from "./scimodule.js"
import * as state from "./serverstatemodule.js"

############################################################
export serviceStartup = ->
    log "serviceStartup"
    # other startup moves
    state.setRunning()
    sci.prepareAndExpose()
    return
