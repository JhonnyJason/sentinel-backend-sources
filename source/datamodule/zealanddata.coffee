############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("zealanddata")
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
    data.hicp = "i.NZ"
    data.mrr = "r.NZ"
    data.gdpg = "g.NZ"
    return


############################################################
export getData = -> data