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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet for updated versions that support your target TFM.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the output for any warnings, particularly around obsolete APIs or platform compatibility analyzers (e.g., `CA1416`).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization).

## 5. Check for Platform-Specific Code

Since this is an ADO-related project (`AdoCore`), review any database connectivity code for the following:

- **`System.Data.OleDb`**: This namespace is Windows-only in .NET 6+. If your code uses `OleDbConnection`, you will need to replace it with a cross-platform provider such as `Microsoft.Data.SqlClient` for SQL Server, or the appropriate provider for your database.
- **`System.Data.Odbc`**: Available cross-platform but with limitations. Verify it functions correctly on your target OS.
- **`System.Data.SqlClient`**: Replace with `Microsoft.Data.SqlClient` as the legacy package is no longer maintained.

You can search for these usages with:

```bash
grep -rn "OleDb\|System.Data.SqlClient\|System.Data.Odbc" --include="*.cs"
```

## 6. Run Platform Compatibility Analysis

Add the .NET platform compatibility analyzer if not already present, and build on each target platform (Windows, Linux, macOS) to surface any runtime issues:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

## 7. Manual Smoke Testing

Run the application manually and exercise the primary data access paths to confirm connectivity and query behavior are functioning as expected:

```bash
dotnet run --configuration Release
```

Verify connection strings in your configuration files (`appsettings.json`, `app.config`, etc.) are correct for the target environment.

## 8. Review Configuration Files

If the project previously used `app.config` or `web.config`, confirm that any relevant settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in modern .NET.

## 9. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <RID> --self-contained false
```

Replace `<RID>` with the appropriate Runtime Identifier, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the publish output directory to confirm all required assemblies and configuration files are present before deploying.