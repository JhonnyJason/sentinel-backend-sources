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

    fred = new FRED(cfg.apiKeyFred)

    allInstances.push(new C()) for C in allClasses
    return

############################################################
export allEvents = -> allInstances


############################################################
# All Event Types
# "ForecastAndDecisions"
# "USMakro"
# "EUMakro"
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
        if date >= firstNew then break
        result.push(date)
    
    for date in newerDates
        result.push(date)

    return result

############################################################
#region Exports of specific Events

############################################################
allClasses.push(
    # FOMC = Federal Open Market Committee
    class FOMCEvent extends Event 
        constructor: ->
            super("US FOMC", "e001", "ForecastAndDecisions")    
            @remoteId = 326
            @remoteName = "Summary of Economic Projections"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                # log "FOMCEvent: checking future release dates"
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
                # olog @dates
            else 
                # log "FOMCEvent: checking all release dates"
                @dates = await fred.getReleaseDatesForId(@remoteId)
                # olog @dates

            @save()
            return
)

############################################################
allClasses.push(
    # Thanks Giving Event
    class ThanksGivingEvent extends Event 
        constructor: ->
            super("Thanks Giving", "e002", "Other")

        retrieveDates: => return
)

############################################################
allClasses.push(
    # Consumer Price Index Data Release Event
    class CPIEvent extends Event 
        constructor: ->
            super("US CPI Report", "e003", "USMakro")
            @remoteId = 10
            @remoteName = "Consumer Price Index"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
            else 
                @dates = await fred.getReleaseDatesForId(@remoteId)

            @save()
            return
)


############################################################
allClasses.push(
    # Gross Domestic Product Data Release Event
    class GDPEvent extends Event 
        constructor: ->
            super("US GDP Report", "e004", "USMakro")
            @remoteId = 53
            @remoteName = "Gross Domestic Product"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
            else 
                @dates = await fred.getReleaseDatesForId(@remoteId)

            @save()
            return
)

############################################################
allClasses.push(
    # Producer Price Index Data Release Event
    class PPIEvent extends Event 
        constructor: ->
            super("US PPI Report", "e005", "USMakro")
            @remoteId = 46
            @remoteName = "Producer Price Index"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
            else 
                @dates = await fred.getReleaseDatesForId(@remoteId)

            @save()
            return
)

############################################################
allClasses.push(
    # Retail Sales Data Release Event
    class RetailSalesRepEvent extends Event 
        constructor: ->
            super("US Retail Sales Report", "e006", "USMakro")
            @remoteId = 9
            @remoteName = "Advance Monthly Sales for Retail and Food Services"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
            else 
                @dates = await fred.getReleaseDatesForId(@remoteId)

            @save()
            return
)

############################################################
allClasses.push(
    # Employment Situation Data Release Event
    class EmplSituationRepEvent extends Event 
        constructor: ->
            super("US Employment Situation Report", "e007", "USMakro")
            @remoteId = 50
            @remoteName = "Employment Situation"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
            else 
                @dates = await fred.getReleaseDatesForId(@remoteId)

            @save()
            return
)

############################################################
allClasses.push(
    # Existing Home Sales Data Release Event
    class ExistingHomeSalesRepEvent extends Event 
        constructor: ->
            super("US Existing Home Sales Report", "e008", "USMakro")
            @remoteId = 291
            @remoteName = "Existing Home Sales"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
            else 
                @dates = await fred.getReleaseDatesForId(@remoteId)

            @save()
            return
)

############################################################
allClasses.push(
    # Initial Jobless Claims Data Release Event
    class JoblessClaimsRepEvent extends Event 
        constructor: ->
            super("US Jobless Claims Report", "e009", "USMakro")
            @remoteId = 180
            @remoteName = "Initial Claims"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
            else 
                @dates = await fred.getReleaseDatesForId(@remoteId)
            
            @save()
            return
)

############################################################
allClasses.push(
    # Quarterly Financial Data Release Event
    class QuarterlyFinancialRepEvent extends Event 
        constructor: ->
            super("US Quarterly Financial Report", "e010", "USMakro")
            @remoteId = 434
            @remoteName = "Quarterly Financial Report"

        retrieveDates: =>
            todayYYYYMMDD = (new Date()).toISOString().slice(0, 10)
            if @dates.length > 0 and @dates[@dates.length - 1] > todayYYYYMMDD
                newDates = await fred.getFutureReleaseDatesForId(@remoteId)
                @dates = updateNewerDates(@dates, newDates)
            else 
                @dates = await fred.getReleaseDatesForId(@remoteId)

            @save()
            return
)


#endregion