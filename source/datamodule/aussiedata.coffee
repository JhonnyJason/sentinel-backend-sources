############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("aussiedata")
#endregion

############################################################
data = { 
    hicp: NaN,
    mrr: NaN,
    gdpg: NaN 
}

############################################################
export initialize = ->
    log "initialize"
    data.hicp = "i.AU"
    data.mrr = "r.AU"
    data.gdpg = "g.AU"
    return


############################################################
export getData = -> data