############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("zealanddata")
#endregion


############################################################
import * as xlsx from "xlsx"

############################################################
import * as cfg from "./configmodule.js"

############################################################
numToMonth = {
    "0": "January",
    "1": "February",
    "2": "March",
    "3": "April",
    "4": "May",
    "5": "June", 
    "6": "July",
    "7": "August",
    "8": "September",
    "9": "October",
    "10": "November",
    "11": "December"
}

numToQuarter = {
    "0": "Q1",
    "1": "Q1",
    "2": "Q1",
    "3": "Q2",
    "4": "Q2",
    "5": "Q2", 
    "6": "Q3",
    "7": "Q3",
    "8": "Q3",
    "9": "Q4",
    "10": "Q4",
    "11": "Q4"
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
userAgent = "me"

############################################################
export initialize = ->
    log "initialize"
    data.hicp = "i.NZ"
    data.mrr = "r.NZ"
    data.gdpg = "g.NZ"

    heartbeatMS = cfg. statisticsDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    
    if cfg.testRun? then userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
    else userAgent = cfg.rbnzUserAgent
    
    return

# https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/b/b2/hb2-daily.xlsx # interest rates # column 0: daily dates, column 1: OCR

# https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/m/m1/hm1.xlsx # consumer prices # column 0: months, column 1: CPI LVL, column 3: CPI YoY%

# https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/m/m5/hm5.xlsx # gdp # coumn 0: months, column2: real SA GDP LVL, column 3: Real SA GDP QoQ%

############################################################
excelToJSDate = (d) ->
    d = parseInt(d)
    return new Date(Math.round((d - 25569) * 86400 * 1000));


############################################################
heartbeat = ->
    log "heartbeat"
    if cfg.testRun?
        switch(cfg.testRun)
            when "zealandMRR" then await requestMRR()
            when "zealandHICP" then await requestHICP()
            when "zealandGDPG" then await requestGDPG()
    else
        await requestMRR()
        await requestHICP()
        await requestGDPG()
    return

############################################################
requestMRR = ->
    log "requestMRR"
    try
        url = "https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/b/b2/hb2-daily.xlsx"
        fetchOptions = {
            headers: { "User-Agent": userAgent }
        }

        response = await fetch(url, fetchOptions)
        # textResponse = await response.text()
        # log textResponse
        # return

        xlsxBuffer = await response.arrayBuffer()
        sheets = xlsx.read(xlsxBuffer)
        # log sheets.SheetNames
        dataSheet = sheets.Sheets["Data"]

        if!dataSheet? then throw new Error("Sheet 'Data' not found in document.")

        dataId = "INM.DP1.N"
        dataIdCell = "B5"
        id = dataSheet[dataIdCell].v
        if id != dataId then throw new Error("B5 did not carry right dataId (found Id: #{id} | expected: #{dataId})!")

        range = xlsx.utils.decode_range(dataSheet["!ref"])
        bottomRow = range.e.r + 1 # row 1 is at index 0 etc.
        dateCell = "A#{bottomRow}"
        dataCell = "B#{bottomRow}"

        dateRaw = dataSheet[dateCell].v
        mrrDate = excelToJSDate(dateRaw) 
        mrr = parseFloat(dataSheet[dataCell].v)

        data.mrr = "#{mrr.toFixed(2)}%"
        data.gdpgMeta = {
            source: '<a href="https://www.rbnz.govt.nz/" target="_blank">Reserve Bank of New Zealand</a>',
            dataSet: "Official Cash Rate (B2/INM.DP1.N)",
            date: mrrDate
        }

        olog data

    catch err then log err
    return

############################################################
requestHICP = ->
    log "requestHICP"
    try
        url = "https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/m/m1/hm1.xlsx"
        fetchOptions = {
            headers: { "User-Agent": userAgent }
        }

        response = await fetch(url, fetchOptions)
        xlsxBuffer = await response.arrayBuffer()
        sheets = xlsx.read(xlsxBuffer)
        # log sheets.SheetNames
        dataSheet = sheets.Sheets["Data"]

        if!dataSheet? then throw new Error("Sheet 'data' not found in document.")

        dataId = "CPI.Q.C.iay"
        dataIdCell = "D5"
        id = dataSheet[dataIdCell].v
        if id != dataId then throw new Error("D5 did not carry right dataId (found Id: #{id} | expected: #{dataId})!")

        range = xlsx.utils.decode_range(dataSheet["!ref"])
        bottomRow = range.e.r + 1 # row 1 is at index 0 etc.
        dateCell = "A#{bottomRow}"
        dataCell = "D#{bottomRow}"

        dateRaw = dataSheet[dateCell].v
        dt = excelToJSDate(dateRaw)
        dateString = "#{numToMonth[dt.getMonth()]} #{dt.getFullYear()}" # June 2025

        hicp = parseFloat(dataSheet[dataCell].v)

        data.hicp = "#{hicp.toFixed(2)}%"
        data.hicpMeta = {
            source: '<a href="https://www.rbnz.govt.nz/" target="_blank">Reserve Bank of New Zealand</a>',
            dataSet: "Consumper Price Index (M1/CPI.Q.C.iay) quarterly data - annual rate of change",
            date: dateString
        }

        olog data
    catch err then log err
    return

############################################################
requestGDPG = ->
    log "requestGDPG"
    ## Here we want Annualized QoQ growth of Real GDP 
    #  -> Adjusted for inflation, Seasonality and Calendar 
    try
        url = "https://www.rbnz.govt.nz/-/media/project/sites/rbnz/files/statistics/series/m/m5/hm5.xlsx"
        fetchOptions = {
            headers: { "User-Agent": userAgent }
        }

        response = await fetch(url, fetchOptions)
        xlsxBuffer = await response.arrayBuffer()
        sheets = xlsx.read(xlsxBuffer)
        # log sheets.SheetNames
        dataSheet = sheets.Sheets["Data"]

        if!dataSheet? then throw new Error("Sheet 'data' not found in document.")

        dataId = "GDE.Q.EY.RS"
        dataIdCell = "K5"
        id = dataSheet[dataIdCell].v
        if id != dataId then throw new Error("K5 did not carry right dataId (found Id: #{id} | expected: #{dataId})!")

        range = xlsx.utils.decode_range(dataSheet["!ref"])
        bottomRow = range.e.r + 1 # row 1 is at index 0 etc.
        dateCell = "A#{bottomRow}"
        dataCellQBefore = "K#{bottomRow - 1}"
        dataCellQLatest = "K#{bottomRow}"

        dateRaw = dataSheet[dateCell].v
        dt = excelToJSDate(dateRaw)
        dateString = "#{numToQuarter[dt.getMonth()]} #{dt.getFullYear()}" # Q2 2025
        
        latestGDP = parseFloat(dataSheet[dataCellQLatest].v)
        gdpBefore = parseFloat(dataSheet[dataCellQBefore].v)

        gdpgQ = (100.00 * latestGDP / gdpBefore ) - 100.00
        gdpgA = 100.00 * (Math.pow( (1 + gdpgQ / 100), 4 ) - 1)

        data.gdpg = "#{gdpgA.toFixed(2)}%"
        data.gdpgMeta = {
            source: '<a href="https://www.rbnz.govt.nz/" target="_blank">Reserve Bank of New Zealand</a>',
            dataSet: "GDP (M5/GDE.Q.EY.RS) Real GDP SCA QoQ% annualized",
            date: dateString
        }

        olog { latestGDP, gdpBefore, gdpgQ, gdpgA, data }
    catch err then log err
    return

############################################################
export getData = -> data
