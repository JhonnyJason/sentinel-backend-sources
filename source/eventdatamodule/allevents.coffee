############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("allevents")
#endregion

############################################################
import * as cachedData from "cached-persistentstate"
import { FRED } from "fred-sentinel"

############################################################
fred = null

############################################################
allClasses = []
allInstances = []

############################################################
export initialize = (cfg) ->
    log "initialize"
    if cfg? then cachedData.initialize(cfg.persistentStateOptions) 
    else cachedData.initialize()

    fred = new  FRED(cfg.apiKeyFred)

    allInstances.push(new C()) for C in allClasses
    return

############################################################
export allEvents = -> allInstances


############################################################
# All Event Types
# "ForecastAndDecisions"
# "MakroData"
# "Company"
# "Other"

############################################################
class Event
    constructor: (@label, @id, @type) ->
        log "Event:constructor"
        @STORAGEKEY = "dates:#{@id}"
        dates = cachedData.load(@STORAGEKEY)
        log "loaded dates"
        olog dates
        if !Array.isArray(dates) then dates = []
        @dates = dates
    
    save: => cachedData.save(@STORAGEKEY, @dates)

    retrieveDates: => # To be implemented in Child-Class
        throw new Error("#{constructor.name} must implement retrieveDates()!")


############################################################
updateNewerDates = (prevDates, newerDates) ->
    result = []
    firstNew = newerDates[0]

    for date in prevDates
        if firstNew >= date then break
        result.push(date)
    
    for date in newerDates
        result.push(date)

    return result

############################################################
#region Exports of specific Events

############################################################
allClasses.push(
    class FOMCEvent extends Event # Federal Open Market Committee
        constructor: ->
            super("FOMC", "e001", "ForecastAndDecisions")    
            @remoteId = 326
            @remoteName = "Summary of Economic Projections"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                log "FOMCEvent: checking future release dates"
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
                # olog @dates
            else 
                log "FOMCEvent: checking all release dates"
                @dates = await fred.getReleaseDatesForId(@remoteId)
                # olog @dates

            @save()
            return
)

############################################################


#endregion