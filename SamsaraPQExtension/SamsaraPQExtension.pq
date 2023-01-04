// This file contains your Data Connector logic
section SamsaraPQExtension;

[DataSource.Kind="SamsaraPQExtension", Publish="SamsaraPQExtension.Publish"]
shared SamsaraPQExtension.Contents = (optional message as text) =>
    let
        _message = if (message <> null) then message else "(no message)",
        a = "Hello from SamsaraPQExtension: " & _message
    in
        a;

// Data Source Kind description
SamsaraPQExtension = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
SamsaraPQExtension.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = SamsaraPQExtension.Icons,
    SourceTypeImage = SamsaraPQExtension.Icons
];

SamsaraPQExtension.Icons = [
    Icon16 = { Extension.Contents("SamsaraPQExtension16.png"), Extension.Contents("SamsaraPQExtension20.png"), Extension.Contents("SamsaraPQExtension24.png"), Extension.Contents("SamsaraPQExtension32.png") },
    Icon32 = { Extension.Contents("SamsaraPQExtension32.png"), Extension.Contents("SamsaraPQExtension40.png"), Extension.Contents("SamsaraPQExtension48.png"), Extension.Contents("SamsaraPQExtension64.png") }
];
