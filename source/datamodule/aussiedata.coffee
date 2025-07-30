############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("aussiedata")
#endregion

############################################################
import * as cfg from "./configmodule.js"

############################################################
data = { 
    hicp: NaN,
    mrr: NaN,
    gdpg: NaN 
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
            olog { latestRate }
            i++
            els = csvLines[i].split(",")

        data.mrr = "#{latestRate.toFixed(2)}%"
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
        
        hicp = parseFloat(latestDataPoint.latestValue)
        data.hicp = "#{hicp.toFixed(2)}%"
        
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
        # olog latestDataPoint

        gdpgQ = parseFloat(latestDataPoint.latestValue)
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        data.gdpg = "#{gdpgA.toFixed(2)}%"
        olog { gdpgQ, gdpgA, data }    
        
    catch err then log err
    return

############################################################
export getData = -> data
