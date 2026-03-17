############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("aussiedata")
#endregion

############################################################
import * as cachedData from "cached-persistentstate"

############################################################
import * as cfg from "./configmodule.js"
import * as bs from "./bugsnitch.js"

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
    cotIndex36:  NaN
    cotIndex6:  NaN
}
STOREKEY = "aussiedata"
############################################################
save = -> await cachedData.save(STOREKEY)

############################################################
mrr_cookies = ""

############################################################
export initialize = ->
    log "initialize"
    if cfg? then cachedData.initialize(cfg.persistentStateOptions) 
    else cachedData.initialize()

    data.hicp = "i.AU"
    data.mrr = "r.AU"
    data.gdpg = "g.AU"
    data.cotIndex6 = "c6.AU"
    data.cotIndex36 = "c36.AU"

    store = cachedData.load(STOREKEY)
    if !store.hicp? or !store.gdpg?
        cachedData.save(STOREKEY, data)
    else data = store

    heartbeatMS = cfg.statisticsDataRequestHeartbeatMS
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
    save()
    return

############################################################
decodeSeriesTable = (data) ->
    dims = data.structure.dimensions.series
    series = data.dataSets[0].series

    table = []

    for key of series

        indexes = key.split(":")
        row = {}
        row.key = key

        for i in [0...dims.length]

            dim = dims[i]
            index = parseInt(indexes[i])

            if dim? and dim.values? and dim.values[index]?
                row[dim.id] = dim.values[index].id
            else
                row[dim.id] = "?"

        table.push row

    console.table table
    return table

findSeriesKey = (search, structure) ->
    dims = structure.dimensions.series
    indexes = []

    for dim in dims
        if search[dim.id]?
            target = search[dim.id]

            valueIndex = dim.values.findIndex(
                (v) -> v.id is target.id or v.name is target.name
            )

            if valueIndex < 0
                throw new Error "Value #{target} not found in #{dim.id}" 

            indexes.push valueIndex

        else indexes.push 0   # default if not specified

    return indexes.join(":")

excractLatestYoYHICP = (sdmxJSON) ->
    # decodeSeriesTable(sdmxJSON)
    search = { # YoY Change in %, All groups CPI, not seasonally adjusted
        "MEASURE": { id: "3" },
        "INDEX": { id: "10001" },
        "TSEST": { id: "20" },
        # "REGION": { id: "50" }
        # "FREQ": { id: "M"}
    }
    key = findSeriesKey(search, sdmxJSON.structure)
    # key = "2:0:0:0:0" 
    log key

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
        url = "https://www.rba.gov.au/statistics/tables/csv/a2-data.csv"
        options = {
            method: 'GET',
            headers: { 
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
                "Accept": "text/csv,application/octet-stream;q=0.9,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": "https://www.rba.gov.au/",
                "Connection": "keep-alive",
                "Cookie": mrr_cookies
            }
        }
        response = await fetch(url, options)
        status = response.status
        mrr_cookies = response.headers.get("set-cookie")

        csvTable = await response.text()

        csvLines = csvTable.split("\n")
        # olog csvLines
        titleLine = csvLines[1]
        titleEls = titleLine.split(",")
        if titleEls[0] != "Title" or titleEls[2] != "New Cash Rate Target"
            olog {
                "Title": titleEls[0]
                "NewCashRateTarget": titleEls[2]
            }
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
    catch err then bs.report("@aussiedata.requestMRR: "+err.message)
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try
        # url = "https://indicator.api.abs.gov.au/v1/data/CPI_M_H/JSON"
        url = "https://indicator.api.abs.gov.au/v1/data/CPI_H/JSON"
        fetchOptions = {
            method: "GET"
            headers: {
                "accept": "application/json"
                "x-api-key": cfg.apiKeyAbs
            }
        }
        response = await fetch(url, fetchOptions)
        hicpData = await response.json()
        # olog hicpData
        latestDataPoint = excractLatestYoYHICP(hicpData)
        olog latestDataPoint

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
    catch err then bs.report("@aussiedata.requestHICP: "+err.message)
    return

############################################################
requestGDPG = ->
    log "requestGDPG"
    ## Here we want Annualized QoQ growth of Real GDP 
    #  -> Adjusted for inflation, Seasonality and Calendar 
    try
        url = "https://indicator.api.abs.gov.au/v1/data/GDPE_H/JSON"
        fetchOptions = {
            method: "GET"
            headers: {
                "accept": "application/json"
                "x-api-key": cfg.apiKeyAbs
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
    catch err then bs.report("@aussiedata.requestGDPG: "+err.message)
    return

############################################################
export getData = -> data

############################################################
export cotDataSet = (cotData) ->
    log "cotDataSet"
    data.cotIndex36 = cotData.n36Index
    data.cotIndex6 = cotData.n6Index
    olog data
    return