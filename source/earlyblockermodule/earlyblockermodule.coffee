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
export isBlocked = (ip, origin) ->
    log "isBlocked"

    if blockedIPs.has(ip)
        log "blocked request with IP: #{ip}"
        return "IP blocked!"
    
    if !legalOrigins.has(origin)
        log "blocked request with origin: #{origin}"
        blockedIPs.add(ip)
        console.error("Request failed due to blocked origin!")
        console.error("Origin: #{origin}, IP:#{ip}")
        return "Illegal Origin!"
    
    log "passed!"
    return


############################################################
export blockIp = (ip) -> blockedIPs.add(ip)
