############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("ukdata")
#endregion

############################################################
import * as cfg from "./configmodule.js"

months = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
]

monthsShortsToName = {
    "JAN": "January",
    "FEB": "February",
    "MAR": "March",
    "APR": "April",
    "MAY": "May",
    "JUN": "June",
    "JUL": "July",
    "AUG": "August",
    "SEP": "September",
    "OCT": "October",
    "NOV": "November",
    "DEC": "December",
}

############################################################
data = {
    hicp: NaN,
    hicpMeta: {}
    mrr: NaN,
    mrrMeta: {}
    gdpg: NaN 
    gdpgMeta: {}
    cotData: {}
}

############################################################
export initialize = ->
    log "initialize"
    data.hicp = "i.UK"
    data.mrr = "r.UK"
    data.gdpg = "g.UK"

    heartbeatMS = cfg. statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return


############################################################
heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        switch(cfg.testRun)
            when "ukMRR" then await requestMRR()
            when "ukHICP" then await requestHICP()
            when "ukGDPG" then await requestGDPG()
    else
        await requestMRR()
        await requestHICP()
        await requestGDPG()
    return

############################################################

############################################################
requestMRR = ->
    log "requestMRR"
    try

        response = await fetch("https://www.bankofengland.co.uk/boeapps/database/Bank-Rate.asp")
        htmlResponse = await response.text()

        #Area of Interest:
        # <div class="featured-stat">
        #     <p class="stat-intro">Current official Bank Rate</p>
        #     <p class="stat-figure">4%</p>
        # </div>

        parts = htmlResponse.split('<div class="featured-stat">')
        
        if parts.length != 2 then throw new Error("Unexpected HTML structure!")
        parts = parts[1].split('<p class="stat-figure">')
        if parts.length != 2 then throw new Error("Unexpected HTML structure!")

        parts = parts[1].split("</p>")
        mrr = parseFloat(parts[0])
        # log mrr
        mrrDate = new Date() # TODO parse for latest release Date

        data.mrr = "#{mrr.toFixed(2)}%"
        data.mrrMeta = {
            source: '<a href="https://www.bankofengland.co.uk">Bank of England</a>',
            dataSet: "Bank Rate",
            date: mrrDate # DATE
        }

        olog data            
    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try
        url = "https://www.ons.gov.uk/generator?format=csv&uri=/economy/inflationandpriceindices/timeseries/d7bt/mm23"
        response = await fetch(url)
        csvResponse = await response.text()
        # log csvResponse

        date = new Date()
        thisYear = "#{date.getFullYear()}"
        lastYear = "#{date.getFullYear() - 1}"
        yearBefore = "#{date.getFullYear() - 2}"
        
        keysToData = {}
        for m in months
            key = "#{thisYear} #{m}"
            keysToData[key] = true
            key = "#{lastYear} #{m}"
            keysToData[key] = true
            key = "#{yearBefore} #{m}"
            keysToData[key] = true
        olog keysToData

        latestKey = null
        csvLines = csvResponse.split("\n")
        for line in csvLines
            cells = line.split(",")
            key = cells[0].trim().replaceAll("\"", "")
            # log key

            if keysToData[key]
                value = parseFloat(cells[1].trim().replaceAll("\"", ""))
                keysToData[key] = value
                latestKey = key

        ts = latestKey.split(" ")
        latestKeyYear = parseInt(ts[0])
        yearBeforeKey = "#{latestKeyYear - 1} #{ts[1]}"

        olog keysToData
        hicpBefore = keysToData[yearBeforeKey]
        hicpNow = keysToData[latestKey]

        log latestKey
        ts = latestKey.split(" ")
        dateString = "#{monthsShortsToName[ts[1]]} #{ts[0]}"

        olog {hicpBefore, hicpNow}

        hicp = (100.0 * hicpNow / hicpBefore) - 100
        data.hicp = "#{hicp.toFixed(2)}%"
        data.hicpMeta = {
            source: '<a href="https://www.ons.gov.uk/" target="_blank">Office for National Statistics</a>',
            dataSet: "CPI INDEX 00: ALL ITEMS (d7bt)",
            date: dateString
        }

        olog {data}
    catch err then log err
    return

############################################################
requestGDPG = ->
    ## Here we want Annualized QoQ growth of Real GDP 
    #  -> Adjusted for inflation, Seasonality and Calendar 
    try
        url = "https://www.ons.gov.uk/generator?format=csv&uri=/economy/grossdomesticproductgdp/timeseries/abmi/pn2"
        response = await fetch(url)
        csvData = await response.text()        
        csvLines = csvData.split("\n")
        olog csvLines

        date = new Date()
        thisYear = "#{date.getFullYear()}"
        lastYear = "#{date.getFullYear() - 1}"

        isRelevant = (label) ->
            # log "isRelevant"
            label = label.trim().replaceAll("\"", "")
            ts = label.split(" ")
            # olog ts
            return false unless ts[0] == thisYear || ts[0] == lastYear
            return true if ts[1] == "Q1" || ts[1] == "Q2" || ts[1] == "Q3" || ts[1] == "Q4"
            return false

        # Here we assume that the last 2 relevant entries are the latest two consecutive Quarters
        latestGDP = 0
        gdpBefore = 0
        for line in csvLines
            tks = line.split(",")
            if isRelevant(tks[0])
                log "#{tks[0]} was relevant!" 
                gdpBefore = latestGDP
                latestGDP = parseFloat(tks[1].trim().replaceAll("\"", ""))
                latestDate = tks[0].replaceAll("\"", "")

        ts = latestDate.split(" ")
        dateString = "#{ts[1]} #{ts[0]}"


        gdpgQ = (100.00 * latestGDP / gdpBefore) - 100
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        data.gdpg = "#{gdpgA.toFixed(2)}%"
        data.gdpgMeta = {
            source: '<a href="https://www.ons.gov.uk/" target="_blank">Office for National Statistics</a>',
            dataSet: "GDP (abmi/pn2) Real GDP SA QoQ% annualized",
            date: dateString
        }

        olog { gdpgQ, gdpgA, data }    
        
    catch err then log err
    return

############################################################
export getData = -> data

############################################################
export setCOTData = (cotData) ->
    log "setCOTData"
    data.cotIndex36 = cotData.n36Index
    data.cotIndex6 = cotData.n6Index
    olog data
    return