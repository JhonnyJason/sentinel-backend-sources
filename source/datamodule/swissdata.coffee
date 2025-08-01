############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("swissdata")
#endregion

############################################################
import * as cfg from "./configmodule.js"

############################################################
monthToName = {
    "01": "January"
    "02": "February"
    "03": "March"
    "04": "April"
    "05": "May"
    "06": "June"
    "07": "July"
    "08": "August"
    "09": "September"
    "10": "October"
    "11": "November"
    "12": "December"
}

############################################################
data = { 
    hicp: NaN,
    hicpMeta: {}
    mrr: NaN,
    mrrMeta: {}
    gdpg: NaN 
    gdpgMeta: {}
}

############################################################
export initialize = ->
    log "initialize"
    data.hicp = "i.CH"
    data.mrr = "r.CH"
    data.gdpg = "g.CH"
 
    heartbeatMS = cfg. statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return

############################################################
heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        switch(cfg.testRun)
            when "swissMRR" then await requestMRR()
            when "swissHICP" then await requestHICP()
            when "swissGDPG" then await requestGDPG()
    else 
        await requestMRR()
        await requestHICP()
        await requestGDPG()
    return

############################################################
requestMRR = ->
    log "requestMRR"
    try
        response = await fetch("https://data.snb.ch/api/cube/snbgwdzid/data/json/en?dimSel=D0(LZ)")
        mrrData = await response.json()
        # olog mrrData
        mrrData = mrrData.timeseries[0].values
        # olog mrrData
        
        dateToValue = {}
        dateToValue[d.date] = d.value for d in mrrData
        dates = Object.keys(dateToValue).sort().reverse()

        # olog dateToValue
        # olog dates
        # log dates[0]
        mrrDate = new Date(dates[0])

        mrr = parseFloat(dateToValue[dates[0]])
        data.mrr = "#{mrr.toFixed(2)}%"

        data.mrrMeta = {
            source: '<a href="https://data.snb.ch/en">SNB</a>',
            dataSet: "SNB Policy Rate (snbgwdzid)",
            date: mrrDate # DATE
        }

        olog data

    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try # M.RCH_A.NSA.CP-HI00.EA20
        # response = await fetch("https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/prc_hicp_manr?freq=M&unit=RCH_A&coicop=CP00&geo=EA20&time=2025-06&format=JSON") # Fails...
        response = await fetch("https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/prc_hicp_manr/M.RCH_A.CP00.CH?format=JSON")
        hicpData = await response.json()

        # log Object.keys(hicpData)
        # olog hicpData.value
        # olog hicpData.dimension.time

        allValues = hicpData.value
        indices = hicpData.dimension.time.category.index

        indexKeys = Object.keys(indices)
        indexKeys = indexKeys.sort().reverse()
        # log indexKeys

        i = 0
        hicp = allValues[indices[indexKeys[i]]]
        while !hicp?
            i++
            hicp = allValues[indices[indexKeys[i]]]

        indexKey = indexKeys[i]
        # log indexKey
        ## Format Date
        ts = indexKey.split("-") 
        dateString = "#{monthToName[ts[1]]} #{ts[0]}"

        if typeof hicp != "number" then hicp = parseFloat(hicp)        
        data.hicp = "#{hicp.toFixed(2)}%"

        data.hicpMeta = {
            source: '<a href="https://ec.europa.eu/eurostat" target="_blank">Eurostat</a>',
            dataSet: "HICP monthly data - annual rate of change (prc_hicp_manr/M.RCH_A.CP00.CH)",
            date: dateString
        }

        olog {data}

    catch err then log err
    return

############################################################
requestGDPG = ->
    log "requestGDPG"
    ## Here we want Annualized QoQ growth of Real GDP 
    #  -> Adjusted for inflation, Seasonality and Calendar 
    try
        ## Key buildup = freq.unit.s_adj.na_item.geo
        # freq: Q -> Quarterly
        # unit: CLV_I10 -> Chained Linked Volume Index from 2010 (inflation adjusted)
        # s_adj: SCA -> Saesonally and Calendar adjusted
        # na_item: B1GQ -> Gross domestic product at market prices
        # geo: CH -> Switzerland
        response = await fetch("https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/namq_10_gdp/Q.CLV_I10.SCA.B1GQ.CH?format=JSON") 
        gdpData = await response.json()

        # olog gdpData

        allValues = gdpData.value
        indices = gdpData.dimension.time.category.index

        indexKeys = Object.keys(indices)
        indexKeys = indexKeys.sort().reverse()
        # log indexKeys

        i = 0
        latestGDP = allValues[indices[indexKeys[i]]]
        while !latestGDP?
            i++
            latestGDP = allValues[indices[indexKeys[i]]]
        
        indexKey = indexKeys[i]
        log indexKey
        ## Format Date
        ts = indexKey.split("-") 
        dateString = "#{ts[1]} #{ts[0]}"

        i++
        gdpBefore = allValues[indices[indexKeys[i]]]
        
        if typeof latestGDP != "number" then latestGDP = parseFloat(latestGDP)
        if typeof gdpBefore != "number" then gdpBefore = parseFloat(gdpBefore)

        gdpgQ = (100.00 * latestGDP / gdpBefore ) - 100.00
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        data.gdpg = "#{gdpgA.toFixed(2)}%"
        data.gdpgMeta = {
            source: '<a href="https://ec.europa.eu/eurostat" target="_blank">Eurostat</a>',
            dataSet: "GDP and main components (namq_10_gdp/Q.CLV_I10.SCA.B1GQ.CH) Real GDP SCA QoQ% annualized",
            date: dateString
        }

        olog { latestGDP, gdpBefore, data }    
        
    catch err then log err
    return


############################################################
export getData = -> data