# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches. If any packages were previously Windows-only (e.g., packages targeting `net4x`), verify that cross-platform equivalents are in place.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output, as some warnings may indicate compatibility concerns that do not block the build but could cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs may have been available in .NET Framework but behave differently or throw `PlatformNotSupportedException` at runtime in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the following command to check for known compatibility issues:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage, given the project name `AdoCore`
- Any database drivers or OLE DB/ODBC providers that may not have cross-platform support
- Registry access, Windows-specific file paths, or COM interop

## 6. Validate ADO.NET Provider Compatibility

Since this project appears to be ADO.NET related, confirm that the database provider being used has a cross-platform compatible NuGet package. For example:

| Legacy Provider | Cross-Platform Alternative |
|---|---|
| `System.Data.SqlClient` | `Microsoft.Data.SqlClient` |
| OLE DB providers | Not supported on non-Windows; use a native driver |
| ODBC | Limited cross-platform support; verify per platform |

Update connection strings and provider references accordingly.

## 7. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (RID) as needed, such as `win-x64` or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Refer to the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported runtime identifiers.