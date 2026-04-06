# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm no errors surface during compilation:

```bash
dotnet build --configuration Release
```

Address any warnings that may indicate compatibility concerns, even if they do not block the build.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for APIs that are Windows-only. You can also use the built-in Roslyn analyzer by adding the following to your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Pay particular attention to:
- `System.Data` usage with OLE DB or ODBC providers, which may have platform restrictions
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific COM interop

## 6. Validate ADO.NET Functionality

Since the project is named `AdoCore`, confirm that all database connectivity works as expected:

- Verify the correct ADO.NET provider NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server)
- Test connection strings and confirm they function in the target environment
- Confirm any `DataSet`, `DataTable`, or `DataAdapter` usage behaves consistently

## 7. Run on Target Platform

Execute the application on each platform you intend to support (Linux, macOS, Windows) to surface any platform-specific runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment target. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.