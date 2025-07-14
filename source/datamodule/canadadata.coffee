############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("canadadata")
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
    data.hicp = "i.CA"
    data.mrr = "r.CA"
    data.gdpg = "g.CA"
    return


############################################################
export getData = -> data