############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("earlyblockermodule")
#endregion

############################################################
import * as cfg from "./configmodule.js"

############################################################
legalOrigins = new Set()
blockedIPs = new Set()

############################################################
export initialize = ->
    log "initialize"
    legalOrigins.add(o) for o in cfg.legalOrigins
    content = new Array(...legalOrigins)
    log "legalOrigins: #{content}"   
    return


############################################################
export checkOrThrow = (ip, origin) ->
    log "checkOrThrow"

    if blockedIPs.has(ip)
        log "blocked request with IP: #{ip}"
        throw new Error("IP blocked!")
    
    if !legalOrigins.has(origin)
        log "blocked request with origin: #{origin}"
        blockedIPs.add(ip)
        throw new Error("Illegal Origin!")
    
    log "passed!"
    return


############################################################
export blockIp = (ip) -> blockedIPs.add(ip)
