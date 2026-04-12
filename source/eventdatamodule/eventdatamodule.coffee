############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("eventdatamodule")
#endregion

############################################################
import * as cfg from "./configmodule.js"
import * as bs from "./bugsnitch.js"

############################################################
import * as allEv from "./allevents.js" 

############################################################
idToEvent = Object.create(null)
eventSummary = []

############################################################
export initialize = ->
    log "initialize"
    heartbeatMS = cfg.statisticsDataRequestHeartbeatMS
    allEv.initialize(cfg)

    ########################################################
    addEvent = (evnt) ->
        id = evnt.id
        label = evnt.label
        type = evnt.type

        idToEvent[id] = evnt
        eventSummary.push({id, label, type})
        return

    events = allEv.allEvents()
    addEvent(evnt) for evnt in events

    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return

############################################################
heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        if cfg.testRun == "eventdata" then await retrieveEventData()
    else await retrieveEventData()

    # olog eventSummary
    # olog idToEvent
    
    return

############################################################
retrieveEventData = ->
    log "retrieveEventData"
    promises = []
    for id,evnt of idToEvent
        promises.push(evnt.retrieveDates())
    try await Promise.all(promises)
    catch err then bs.report("@eventdatamodule.retrieveEventData: "+err.message)
    return

############################################################
export getAllEvents = -> eventSummary
export getEventDates = (id) -> 
    log "getEventDates #{id}"
    if idToEvent[id]? then return idToEvent[id].dates
    else return null