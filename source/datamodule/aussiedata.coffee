############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("aussiedata")
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
    data.hicp = "i.AU"
    data.mrr = "r.AU"
    data.gdpg = "g.AU"

    heartbeatMS = cfg. statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return


############################################################
heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        switch(cfg.testRun)
            when "aussieMRR" then await requestMRR()
            when "aussieHICP" then await requestHICP()
            when "aussieGDPG" then await requestGDPG()
    else 
        await requestMRR()
        await requestHICP()
        await requestGDPG()
    return

############################################################
excractLatestYoYHICP = (sdmxJSON) ->
    key = "1:0:0:0:0" # YoY Change in %, All groups CPI, not seasonally adjusted
    observations = sdmxJSON.dataSets[0].series[key].observations
    latestKey = Object.keys(observations).sort().reverse()[0]
    # olog latestKey
    # olog observations
    periods = sdmxJSON.structure.dimensions.observation[0].values
    latestPeriod = periods[latestKey].id
    latestValue = observations[latestKey][0]
    return {latestPeriod, latestValue}

excractLatestQoQGDPG = (sdmxJSON) ->
    key = "1:1:0:0:0" # QoQ Change in %, GDP, seasonally adjusted and inflation adjusted
    observations = sdmxJSON.dataSets[0].series[key].observations
    latestKey = Object.keys(observations).sort().reverse()[0]
    # olog latestKey
    # olog observations

    periods = sdmxJSON.structure.dimensions.observation[0].values
    latestPeriod = periods[latestKey].id
    latestValue = observations[latestKey][0]
    return {latestPeriod, latestValue}


############################################################
requestMRR = ->
    log "requestMRR"
    try
        response = await fetch("https://www.rba.gov.au/statistics/tables/csv/a2-data.csv")
        csvTable = await response.text()

        csvLines = csvTable.split("\n")
        # olog csvLines
        titleLine = csvLines[1]
        titleEls = titleLine.split(",")
        if titleEls[0] != "Title" or titleEls[2] != "New Cash Rate Target"
            throw new Error("Unexpected structure!")
        
        latestRate = NaN

        i = 11
        els = csvLines[i].split(",")
        while els[0] != ""
            latestRate = parseFloat(els[2])
            latestDate = els[0]
            mrrDate = new Date()
            i++
            els = csvLines[i].split(",")

        # olog { la1testRate, latestDate }
        mrrDate = new Date(latestDate)

        data.mrr = "#{latestRate.toFixed(2)}%"
        data.mrrMeta = {
            source: '<a href="https://www.rba.gov.au/">RBA</a>',
            dataSet: "Cash Rate Target",
            date: mrrDate # DATE
        }

        olog data
    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try 
        url = "https://indicator.api.abs.gov.au/v1/data/CPI_M_H/JSON"
        fetchOptions = {
            method: "GET"
            headers: {
                "accept": "application/json"
                "x-api-key": cfg.absAPIKey
            }
        }
        response = await fetch(url, fetchOptions)
        hicpData = await response.json()
        # olog hicpData
        latestDataPoint = excractLatestYoYHICP(hicpData)
        # olog latestDataPoint

        ts = latestDataPoint.latestPeriod.split("-")
        dateString = "#{monthToName[ts[1]]} #{ts[0]}"
        
        hicp = parseFloat(latestDataPoint.latestValue)
        data.hicp = "#{hicp.toFixed(2)}%"                
        data.hicpMeta = {
            source: '<a href="https://www.abs.gov.au/" target="_blank">Australian Bureau of Statistics</a>',
            dataSet: "Monthly CPI Indicator (CPI_M_H)",
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
        url = "https://indicator.api.abs.gov.au/v1/data/GDPE_H/JSON"
        fetchOptions = {
            method: "GET"
            headers: {
                "accept": "application/json"
                "x-api-key": cfg.absAPIKey
            }
        }
        response = await fetch(url, fetchOptions)
        gdpData = await response.json()
        # olog hicpData
        latestDataPoint = excractLatestQoQGDPG(gdpData)
        olog latestDataPoint
        ts = latestDataPoint.latestPeriod.split("-")
        dateString = "#{ts[1]} #{ts[0]}"
        gdpgQ = parseFloat(latestDataPoint.latestValue)
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        data.gdpg = "#{gdpgA.toFixed(2)}%"
        data.gdpgMeta = {
            source: '<a href="https://www.abs.gov.au/" target="_blank">Australian Bureau of Statistics</a>',
            dataSet: "GDP (GDPE_H) Real GDP SA QoQ% annualized",
            date: dateString
        }

        olog { gdpgQ, gdpgA, data }    
        
    catch err then log err
    return

############################################################
export getData = -> data
