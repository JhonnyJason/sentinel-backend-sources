############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("scimodule")
#endregion

############################################################
#region modules from the Environment
import * as sciBase from "thingy-sci-base"
# import * as routes from ""
# import * as handlers from ""
#endregion

############################################################
routes = {}

routes["sampleRoute"] = (res, req) ->
    # req.body is our json
    # handle
    res.send("Hello World!")

    
############################################################
export prepareAndExpose = ->
    log "prepareAndExpose"
    # handlers.setService(this)
    sciBase.prepareAndExpose(null, routes)
    log "Server listening!"
    return
