// This file contains your Data Connector logic
section SamsaraPQExtension;

[DataSource.Kind="SamsaraPQExtension", Publish="SamsaraPQExtension.Publish"]
shared SamsaraPQExtension.Contents = () =>
    let
        source = NavigationTable
    in
        source
;

/*
Purpose:
    Return tables and other objects that will be visible in Power BI's Navigation dialog
*/

// shared NavigationTable = () =>
NavigationTable = 
    let
        objects = #table(
            {"Name","Key","Data","ItemKind", "ItemName","IsLeaf"},
            {
				{"Drivers","drivers", Drivers, "Table", "Table", true},
                {"Vehicles","vehicles", Vehicles, "Table", "Table", true}
//                 {"Users", "users", Users(subdomain), "Table", "Table", true},
//                 {"Tables", "tables",  TableNodes(subdomain), "Folder", "Folder", false},
//                 {"Metadata", "metadata",  MetadataNodes(subdomain), "Folder", "Folder", false}
//                 {"Credentials","credentials", Credentials, "Table", "Table", true}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable
;

Credentials =
	let
		accessToken = Extension.CurrentCredential()[Key],
		Source = #table({"AccessToken"}, {{accessToken}})
	in
		Source
;

/*
Purpose:
    Retrieve table of Drivers
Links:
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
Links:
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
