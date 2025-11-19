############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("cotdatamodule")
#endregion

############################################################
import { performance, PerformanceObserver } from 'node:perf_hooks';
import * as fs from "node:fs"

############################################################
import * as yauzl from "yauzl"
import * as state from "cached-persistentstate"

############################################################
import * as cfg from "./configmodule.js"
import * as bs from "./bugsnitch.js"

############################################################
import * as eurodata from "./eurodata.js"
import * as usdata from "./usdata.js"
import * as japandata from "./japandata.js"
import * as swissdata from "./swissdata.js"
import * as canadadata from "./canadadata.js"
import * as aussiedata from "./aussiedata.js"
import * as zealanddata from "./zealanddata.js"
import * as ukdata from "./ukdata.js"

############################################################
obs = new PerformanceObserver(
    (items) ->
        log(items.getEntries()[0].duration)
        performance.clearMarks()
)
obs.observe({ type: 'measure' })

############################################################
allData = { # we need data for the last 163 weeks >= 36 months
}

dateKeys = null

############################################################
commodityCodeToCurrency = {
    "090": "CAD",
    "092": "CHF",
    "096": "GBP",
    "097": "JPY",
    "099": "EUR",
    "232": "AUD",
    "112": "NZD",
    "098": "USD"
}

############################################################
REPORT_DATE = 2
COMMODITY_CODE = 6
DEALERS_LONG = 8
DEALERS_SHORT = 9

############################################################
data = {
    "AUD": {},
    "CAD": {},
    "JPY": {},
    "EUR": {},
    "CHF": {},
    "GBP": {},
    "NONE": {}
}
    # # 6 months -> (26) -> 27 Weeks
    # # 36 months -> (130) -> 131 Weeks = 917 days
    # leDat.setDate(leDat.getDate() - 917)
    # fromDateString = leDat.toISOString().split("T")[0]

############################################################
currencyShortformForCFTCName = (cftcName) ->
    switch cftcName
        when "AUSTRALIAN DOLLAR" then return "AUD"
        when "CANADIAN DOLLAR" then return "CAD"
        when "EUROPEAN CURRENCY UNIT" then return "EUR"
        when "JAPANESE YEN" then return "JPY"
        when "POUND STERLING" then return "GBP"
        when "SWISS FRANC" then return "CHF"
        else return "NONE"
    return

############################################################
export initialize = ->
    log "initialize"

    state.initialize()

    reportData = state.load("cotReportData")
    dateKeys = Object.keys(reportData).sort().reverse()
    if dateKeys.length <= 0 then state.save("cotReportData", allData)
    else allData = reportData

    # olog allData

    heartbeatMS = cfg.cotDataRequestHeartbeatMS
    setInterval(heartbeat, heartbeatMS)
    heartbeat()
    return

############################################################
heartbeat = ->
    log "heartbeat"
    if !cfg.testRun? then await updateCOTData() 
    else if cfg.testRun == "cotData" then  await updateCOTData()
    return

############################################################
updateCOTData = ->
    log "updateCOTData"
    try
        # if dateKeys.length <= 0 then await loadAllCOTReportData()

        dateKeys = Object.keys(allData).sort().reverse()
        # olog dateKeys
        # log dateKeys.length

        years = findYearsWithHoles(dateKeys)
        olog years
        for year in years
            try await loadAndDigestHistoricalData(year, true)
            catch err then log "Could not load Data for #{year}: #{err.message}"

        dateKeys = Object.keys(allData).sort().reverse()
        # olog dateKeys
        # log dateKeys.length

        # we need to check if any Data is missing
        latestDate = dateKeys[0]
        if dateDaysAge(new Date(latestDate)) > 6
            log "The latestDate #{latestDate} was older than 6 days."
            await loadLatestReport()

        state.save("cotReportData", allData)

        eurodata.cotDataSet(summarizeCOTData("EUR"))
        usdata.cotDataSet(summarizeCOTData("USD")) 
        japandata.cotDataSet(summarizeCOTData("JPY"))
        swissdata.cotDataSet(summarizeCOTData("CHF"))
        canadadata.cotDataSet(summarizeCOTData("CAD"))
        aussiedata.cotDataSet(summarizeCOTData("AUD"))
        zealanddata.cotDataSet(summarizeCOTData("NZD"))
        ukdata.cotDataSet(summarizeCOTData("GBP"))

    catch err then bs.report(err)
    return

findYearsWithHoles = (dates) ->
    log "findYearsWithHoles"
    if !Array.isArray(dates) or dates.length == 0
        year = (new Date()).getFullYear()
        return ["#{year--}", "#{year--}", "#{year--}", "#{year}"]

    # 36 months -> (162) -> 163 Weeks = 917 days
    leDat = new Date()
    leDat.setDate(leDat.getDate() - 917)
    minDate = leDat.toISOString().split("T")[0]

    relevantDates = dateKeys.filter((el) -> (el > minDate))
    sortedDates = relevantDates.sort().reverse().map((el) -> new Date(el))
    yearsMissing = {}

    lastDate = new Date()

    for date in sortedDates
        daysDif = datesDaysDif(date, lastDate)
        
        if daysDif > 13
            yearsMissing[date.getFullYear] = true
            yearsMissing[lastDate.getFullYear] = true

        lastDate = date

    return Object.keys(yearsMissing)

############################################################
loadAllCOTReportData = ->
    log "loadAllCOTReportData"
    date = new Date()

    ## Data of the current year might always be incomplete so we need to discard the cache
    year = date.getFullYear()
    try await loadAndDigestHistoricalData(year, true)
    catch err then bs.report("Could not load Data for #{year}: #{err.message}")

    # older data should not change, so we consider the cache
    year-- 
    try await loadAndDigestHistoricalData(year)
    catch err then bs.report("Could not load Data for #{year}: #{err.message}")
    
    year-- 
    try await loadAndDigestHistoricalData(year)
    catch err then bs.report("Could not load Data for #{year}: #{err.message}")

    year-- 
    try await loadAndDigestHistoricalData(year)
    catch err then bs.report("Could not load Data for #{year}: #{err.message}")
    return

############################################################
loadLatestReport = ->
    log "loadLatestReport"
    url = "https://www.cftc.gov/dea/newcot/FinFutWk.txt"

    try
        response = await fetch(url)
        if !response.ok then throw new Error("Fetch response not OK! (#{response.status})")

        fileString = await response.text()
        fileString = fileString.replaceAll("\"", "")
        csvLines = fileString.split("\n")

        return digestCSVLines(csvLines)

    catch err then bs.report(err)
    return

############################################################
getFileURL = (year) -> "https://www.cftc.gov/files/dea/history/fut_fin_txt_#{year}.zip"
getFileName = (year) -> "cotReports#{year}.zip"

############################################################
loadAndDigestHistoricalData = (year, overwriteCache) ->
    log "loadAndDigestHistoricalData"
    fileName = getFileName(year)
    
    if !overwriteCache? or !overwriteCache
        try fileBuffer = fs.readFileSync(fileName)
        catch err then log err

    if !fileBuffer? 
        response = await fetch(getFileURL(year))
        if !response.ok then throw new Error("Fetch response not OK! (#{response.status})")

        fileBuffer = Buffer.from(await response.arrayBuffer())
        fs.writeFileSync(fileName, fileBuffer)
    
    log "File for #{year} has byte-size of: #{fileBuffer.length}"

    fileString = await extractFileStringFromFirstZipEntry(fileBuffer)
    fileString = fileString.replaceAll("\"", "")
    csvLines = fileString.split("\n")
    
    return digestCSVLines(csvLines)

############################################################
digestCSVLines = (csvLines) ->
    log "digestCSVLines"
    
    # ## checking the structure
    # headerLine = csvLines[0]
    # headElements = headerLine.split(",")
    # olog headElements

    for line,i in csvLines
        
        data = line.split(",")
        if data.length < 10 then continue
        cCode = data[COMMODITY_CODE].trim()
        # log "#{cCode} is #{typeof cCode}"

        currency = commodityCodeToCurrency[cCode]
        if !currency? then continue
        # log "detected currency: #{currency}"

        date = data[REPORT_DATE].trim().split("T")[0]
        longPos = parseInt(data[DEALERS_LONG].trim())
        shortPos = parseInt(data[DEALERS_SHORT].trim())
        netLong =  longPos - shortPos 
        addDataPoint({currency, date, netLong})

    return

############################################################
addDataPoint = (dataObj) ->
    # log "addDataPoint"
    if !allData[dataObj.date]? then allData[dataObj.date] = {}
    dateSlot = allData[dataObj.date]
    if !dateSlot[dataObj.currency]? then dateSlot[dataObj.currency] = dataObj.netLong
    else log "double entry for date + currency!"
    return

############################################################
extractFileStringFromFirstZipEntry = (zipFileBuffer) ->
    return new Promise (rslv, rjct) ->
        handleFileUnzip = (err, yauzlFileHandle) ->
            if (err) then rjct(err)

            read = (entry) ->
                # We expect only one file in the zip
                compileData = (err, readStream) ->
                    if (err) then rjct(err)

                    all = [];
                    rslvAsString = -> rslv(Buffer.concat(all).toString("utf8"))

                    readStream.on("data", (d) -> all.push(d))
                    readStream.on("end", rslvAsString)
                    return

                yauzlFileHandle.openReadStream( entry, compileData)
                return

            yauzlFileHandle.readEntry();
            yauzlFileHandle.on( "entry", read)
            yauzlFileHandle.on("end", () -> rjct(new Error("No entries found!")))
            return

        yauzl.fromBuffer(zipFileBuffer, { lazyEntries: true }, handleFileUnzip);
        return

############################################################
datesDaysDif = (firstDate, secondDate) ->
    firstTime = firstDate.getTime()
    secondTime = secondDate.getTime()
    timeDif = secondTime - firstTime
    daysDif =  1.0 * timeDif / (1000 * 60 * 60 * 24)
    return daysDif

############################################################
dateDaysAge = (date) ->
    log "dateDaysAge #{date}"

    currentDate = new Date()
    daysDif = datesDaysDif(date, currentDate)

    if daysDif < 0 then throw new Error("The provided day to check for its age has not even happened yet! #{date} currentDate is: #{currentDate}")

    log "daysDif #{daysDif}"
    return daysDif

############################################################
summarizeCOTData = (asset) ->
    log "summarizeCOTData"
    return {
        n36Index: cotIndexForN36(asset),
        n6Index: cotIndexForN6(asset)
    }
        
############################################################
cotIndexForN6 = (asset) ->
    log "cotIndexForN6"
    # 6 months -> (26) -> 27 Weeks = 189 days
    leDat = new Date()
    leDat.setDate(leDat.getDate() - 189)
    minDateString = leDat.toISOString().split("T")[0]

    return getCOTIndexFromDate(asset, minDateString)

cotIndexForN36 = (asset) ->
    log "cotIndexForN36"
    # 36 months -> (156) -> 157 Weeks = 1099 days
    leDat = new Date()
    # leDat.setDate(leDat.getDate() - 917)
    leDat.setDate(leDat.getDate() - 1099)
    minDateString = leDat.toISOString().split("T")[0]

    return getCOTIndexFromDate(asset, minDateString)

getCOTIndexFromDate = (asset, minDate) ->
    log "getCOTIndexFromDate"

    relevantDates = dateKeys.filter((el) -> (el > minDate))
    log "Total: #{dateKeys.length}\nRelevant: #{relevantDates.length}"
    # log relevantDates

    maxNetValue = Number.NEGATIVE_INFINITY
    minNetValue = Number.POSITIVE_INFINITY

    for date in relevantDates
        netPos = allData[date][asset]
        if netPos > maxNetValue then maxNetValue = netPos
        if netPos < minNetValue then minNetValue = netPos

    latestDate = relevantDates.sort().reverse()[0]
    olog { latestDate }
    latestValue = allData[latestDate][asset]

    fullRange = maxNetValue - minNetValue
    currentLevel = latestValue - minNetValue
    index = 100.00 * currentLevel / fullRange
    olog { maxNetValue, minNetValue, latestValue }
    return index

############################################################
#region Sample value
# {
#     "id":"250805232741F",
#     "market_and_exchange_names":"AUSTRALIAN DOLLAR - CHICAGO MERCANTILE EXCHANGE","report_date_as_yyyy_mm_dd":"2025-08-05T00:00:00.000",
#     "yyyy_report_week_ww":"2025 Report Week 31",
#     "contract_market_name":"AUSTRALIAN DOLLAR",
#     "cftc_contract_market_code":"232741","cftc_market_code":"CME ","cftc_region_code":"CHI",
#     "cftc_commodity_code":"232 ",
#     "commodity_name":"AUSTRALIAN DOLLAR",
#     "open_interest_all":"163900",
#     "dealer_positions_long_all":"69127",
#     "dealer_positions_short_all":"2137",
#     "dealer_positions_spread_all":"166",
#     "asset_mgr_positions_long":"40337",
#     "asset_mgr_positions_short":"101819",
#     "asset_mgr_positions_spread":"5242",
#     "lev_money_positions_long":"19628",
#     "lev_money_positions_short":"30092",
#     "lev_money_positions_spread":"3056",
#     "other_rept_positions_long":"4541",
#     "other_rept_positions_short":"600",
#     "other_rept_positions_spread":"42",
#     "tot_rept_positions_long_all":"142139",
#     "tot_rept_positions_short":"143154",
#     "nonrept_positions_long_all":"21761",
#     "nonrept_positions_short_all":"20746",
#     "change_in_open_interest_all":"4220",
#     "change_in_dealer_long_all":"12706",
#     "change_in_dealer_short_all":"-690",
#     "change_in_dealer_spread_all":"29",
#     "change_in_asset_mgr_long":"-2021",
#     "change_in_asset_mgr_short":"9980",
#     "change_in_asset_mgr_spread":"-2148",
#     "change_in_lev_money_long":"-3385",
#     "change_in_lev_money_short":"-4307",
#     "change_in_lev_money_spread":"191",
#     "change_in_other_rept_long":"-280",
#     "change_in_other_rept_short":"0",
#     "change_in_other_rept_spread":"0",
#     "change_in_tot_rept_long_all":"5092",
#     "change_in_tot_rept_short":"3055",
#     "change_in_nonrept_long_all":"-872",
#     "change_in_nonrept_short_all":"1165",
#     "pct_of_open_interest_all":"100.0",
#     "pct_of_oi_dealer_long_all":"42.2",
#     "pct_of_oi_dealer_short_all":"1.3",
#     "pct_of_oi_dealer_spread_all":"0.1",
#     "pct_of_oi_asset_mgr_long":"24.6",
#     "pct_of_oi_asset_mgr_short":"62.1",
#     "pct_of_oi_asset_mgr_spread":"3.2",
#     "pct_of_oi_lev_money_long":"12.0",
#     "pct_of_oi_lev_money_short":"18.4",
#     "pct_of_oi_lev_money_spread":"1.9",
#     "pct_of_oi_other_rept_long":"2.8",
#     "pct_of_oi_other_rept_short":"0.4",
#     "pct_of_oi_other_rept_spread":"0.0",
#     "pct_of_oi_tot_rept_long_all":"86.7",
#     "pct_of_oi_tot_rept_short":"87.3",
#     "pct_of_oi_nonrept_long_all":"13.3",
#     "pct_of_oi_nonrept_short_all":"12.7",
#     "traders_tot_all":"91",
#     "traders_dealer_long_all":"13",
#     "traders_asset_mgr_long_all":"12",
#     "traders_asset_mgr_short_all":"14",
#     "traders_asset_mgr_spread":"8",
#     "traders_lev_money_long_all":"20",
#     "traders_lev_money_short_all":"22",
#     "traders_lev_money_spread":"7",
#     "traders_other_rept_long_all":"6",
#     "traders_tot_rept_long_all":"61",
#     "traders_tot_rept_short_all":"49",
#     "conc_gross_le_4_tdr_long":"42.9",
#     "conc_gross_le_4_tdr_short":"55.2",
#     "conc_gross_le_8_tdr_long":"54.3",
#     "conc_gross_le_8_tdr_short":"66.0",
#     "conc_net_le_4_tdr_long_all":"42.9",
#     "conc_net_le_4_tdr_short_all":"52.4",
#     "conc_net_le_8_tdr_long_all":"53.7",
#     "conc_net_le_8_tdr_short_all":"62.9",
#     "contract_units":"(CONTRACTS OF AUD 100,000)",
#     "cftc_subgroup_code":"F10",
#     "commodity":"AUSTRALIAN DOLLAR","commodity_subgroup_name":"CURRENCY",
#     "commodity_group_name":"FINANCIAL INSTRUMENTS",
#     "futonly_or_combined":"FutOnly"
# }

#endregion

