# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly under the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite:

```bash
dotnet test --configuration Release
```

Review test results and investigate any failures that may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to identify any APIs that are Windows-only or otherwise platform-restricted. Pay particular attention to:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific authentication or security APIs

## 6. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, verify that the database drivers in use are compatible with cross-platform .NET:

- Replace `System.Data.SqlClient` with `Microsoft.Data.SqlClient` if targeting SQL Server.
- Confirm connection strings and provider factories function correctly on the target OS.
- Run integration tests or a manual connection test against your database.

## 7. Review NuGet Package Versions

Check that all referenced NuGet packages have versions that support the new TFM. You can audit this with:

```bash
dotnet list package --outdated
```

Update packages where appropriate, taking care to review changelogs for breaking changes.

## 8. Smoke Test on Target Platform

If the intent is to run on Linux or macOS, execute the built output on that platform to catch any runtime issues that do not appear during compilation:

```bash
dotnet run --configuration Release
```

or for a published output:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then execute the published binary on the target machine.

## 9. Review Output Type and Entry Point

Confirm that the output type (`Exe` or `Library`) in the `.csproj` is correct and that any entry point (`Program.cs` / top-level statements) behaves as expected after migration.