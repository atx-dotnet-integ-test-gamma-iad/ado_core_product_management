# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about package compatibility or deprecated packages that may need to be updated.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface during the build, as some may indicate runtime issues even if compilation succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may point to behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in `System.Data`, encoding defaults, or file path handling).

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that may not behave identically on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider registrations, which may require explicit package references on cross-platform .NET.
- Windows registry access (`Microsoft.Win32.Registry`), which is not available on non-Windows platforms.
- File path separators and case sensitivity on Linux file systems.

## 6. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, confirm that the appropriate database driver NuGet package is explicitly referenced. On cross-platform .NET, drivers are not included by default. For example:

| Database | Package |
|---|---|
| SQL Server | `Microsoft.Data.SqlClient` |
| SQLite | `Microsoft.Data.Sqlite` |
| PostgreSQL | `Npgsql` |
| MySQL | `MySql.Data` or `MySqlConnector` |

Verify connection strings and provider factory registrations are functioning correctly in the new runtime environment.

## 7. Manual Smoke Testing

Run the application manually against a known dataset or test environment and verify that:
- Database connections open and close as expected.
- Queries return correct results.
- Exception handling behaves as intended.

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag (`win-x64`, `osx-x64`, `linux-x64`, etc.) and `--self-contained` flag to match your deployment requirements. Review the output directory to confirm all necessary files are present before deploying.