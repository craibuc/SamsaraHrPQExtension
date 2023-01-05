// This file contains your Data Connector logic
section SamsaraPQExtension;

[DataSource.Kind="SamsaraPQExtension", Publish="SamsaraPQExtension.Publish"]
shared SamsaraPQExtension.Contents = (optional referenceDate as text) =>
    let
        referenceDate = if (referenceDate = null) then Date.AddDays(DateTime.Date(DateTime.LocalNow()),-1) else Date.FromText(referenceDate),
        source = NavigationTable(referenceDate)
    in
        source
;

/*
Purpose:
    Return tables and other objects that will be visible in Power BI's Navigation dialog
*/

// shared NavigationTable = () =>
NavigationTable = (referenceDate as date) =>
    let
        objects = #table(
            {"Name","Key","Data","ItemKind", "ItemName","IsLeaf"},
            {
				{"Drivers","drivers", Drivers, "Table", "Table", true},
                {"Vehicles","vehicles", Vehicles, "Table", "Table", true},
				{"Dates","dates", Dates(referenceDate), "Table", "Table", true}
//                 {"Users", "users", Users(subdomain), "Table", "Table", true},
//                 {"Tables", "tables",  TableNodes(subdomain), "Folder", "Folder", false},
//                 {"Metadata", "metadata",  MetadataNodes(subdomain), "Folder", "Folder", false}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable
;

/*
*/

Dates = (referenceDate as date) =>
	let
		Source = { Number.From(referenceDate)..Number.From( Date.AddDays(DateTime.Date(DateTime.LocalNow()),-1) ) },
		#"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
		#"Changed Type" = Table.TransformColumnTypes(#"Converted to Table",{{"Column1", type datetime}}),
		#"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Column1", "StartOfDay"}}),
		#"Inserted EndOfDay" = Table.AddColumn(#"Renamed Columns", "EndOfDay", each Date.EndOfDay([StartOfDay]), type datetime)
	in
		#"Inserted EndOfDay"
	;

/*
Purpose:
    Retrieve table of Drivers
Link:
	https://developers.samsara.com/reference/overview#operation/listDrivers
*/

Drivers = 
    let
		accessToken = Extension.CurrentCredential()[Key],
		baseUrl = "https://api.samsara.com/",
		endpointUrl = "/fleet/drivers",
		response = Json.Document(Web.Contents(baseUrl,[RelativePath = endpointUrl, Headers = [Authorization = "Bearer " & accessToken]])),
		#"Converted to Table" = Record.ToTable(response),
		Value = #"Converted to Table"{0}[Value],
		#"Converted to Table1" = Table.FromList(Value, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
		#"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table1", "Column1", {"id", "name", "username", "phone", "licenseNumber", "licenseState", "eldExemptReason", "eldSettings", "timezone", "updatedAtTime", "createdAtTime", "carrierSettings", "driverActivationStatus", "tags", "peerGroupTag", "eldExempt", "eldPcEnabled", "staticAssignedVehicle", "usDriverRulesetOverride", "notes", "locale"})
    in
        #"Expanded Column1"
;

/*
Purpose:
    Retrieve table of Vehicles
Link:
	https://developers.samsara.com/reference/listvehicles
*/

Vehicles = 
    let
		accessToken = Extension.CurrentCredential()[Key],
		baseUrl = "https://api.samsara.com/",
		endpointUrl = "/fleet/vehicles",
		response = Json.Document(Web.Contents(baseUrl,[RelativePath = endpointUrl, Headers = [Authorization = "Bearer " & accessToken]])),
		data = response[data],
		#"Converted to Table" = Table.FromList(data, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
		#"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "name", "licensePlate", "vehicleRegulationMode", "createdAtTime", "updatedAtTime", "cameraSerial", "tags", "externalIds", "make", "model", "vin", "year", "esn", "staticAssignedDriver", "gateway", "serial", "harshAccelerationSettingType", "notes"})
    in
        #"Expanded Column1"
;

/*
Parameters:
	localDateTime - a date/time value assumed to be at the local timezone
Returns:
	# of seconds since 1970/01/01 00:00:00 @ UTC
*/

DateTimeToTimeStamp = (localDateTime as datetime) =>
    let
		Local = DateTimeZone.From(localDateTime),
		UTC = DateTimeZone.ToUtc(Local),
        timestamp = Duration.TotalSeconds(UTC - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0)) * 1000
    in
        timestamp
;

/*
Parameters:
	timestamp - # of seconds since 1970/01/01 00:00:00 @ UTC
Returns:
	a date/time value at the local timezone
*/

TimeStampToDateTime = (timestamp as number) =>
    let
        dateTime = DateTimeZone.ToLocal(#datetimezone(1970, 1, 1, 0, 0, 0, 0, 0) + #duration(0,0,0,timestamp/1000))
    in
        dateTime
;

/*
Purpose:
	Return the driver's safety score within the date range
Parameters:
	driverId - 
	from - start of date range @ local
	to - end of date range @ local
*/

GetSafetyScores = (driverId as number, from as datetime, to as datetime) as table =>

	let
		accessToken = Extension.CurrentCredential()[Key],
		baseUrl = "https://api.samsara.com/",
		endpointUrl = "/v1/fleet/drivers/" & Number.ToText(driverId) & "/safety/score",
		startMs = DateTimeToTimeStamp(from),
		endMs = DateTimeToTimeStamp(to),
		jsonDocument = Json.Document(Web.Contents(baseUrl,[RelativePath = endpointUrl & "?startMs=" & Number.ToText(startMs) & "&endMs=" & Number.ToText(endMs), Headers = [Authorization = "Bearer " & accessToken]])),
		#"Converted to Table" = Record.ToTable(jsonDocument),
		#"Pivoted Column" = Table.Pivot(#"Converted to Table", List.Distinct(#"Converted to Table"[Name]), "Name", "Value"),
		#"Added from" = Table.AddColumn(#"Pivoted Column","From", each from),
		#"Added to" = Table.AddColumn(#"Added from","To", each to)
// 		#"Added totalDistanceDrivenMiles" = Table.AddColumn(#"Pivoted Column", "totalDistanceDrivenMiles", each [totalDistanceDrivenMeters] * 0.0006213712, type number),
	in
		#"Added to"
;

/*
Purpose:
    Create a navigation table 
*/

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable
;

// Data Source Kind description
SamsaraPQExtension = [
    Authentication = [
        Key = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
SamsaraPQExtension.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://github.com/craibuc/SamsaraHrPQExtension",
    SourceImage = SamsaraPQExtension.Icons,
    SourceTypeImage = SamsaraPQExtension.Icons
];

SamsaraPQExtension.Icons = [
    Icon16 = { Extension.Contents("SamsaraPQExtension16.png"), Extension.Contents("SamsaraPQExtension20.png"), Extension.Contents("SamsaraPQExtension24.png"), Extension.Contents("SamsaraPQExtension32.png") },
    Icon32 = { Extension.Contents("SamsaraPQExtension32.png"), Extension.Contents("SamsaraPQExtension40.png"), Extension.Contents("SamsaraPQExtension48.png"), Extension.Contents("SamsaraPQExtension64.png") }
];
