# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any tests that were previously passing in the legacy project but now fail, as these may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that may have been available in .NET Framework but are not fully supported or behave differently on cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires additional packages on non-Windows platforms)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server usage
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

## 5. Review NuGet Package Compatibility

Verify that all NuGet packages referenced in `AdoCore.csproj` have versions that are compatible with your target framework. You can check this by reviewing the package pages on [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform .NET support.

## 6. Validate ADO.NET Data Access Behavior

Since the project name suggests ADO.NET usage (`AdoCore`), confirm that all database connectivity works as expected:

- Verify connection strings are correctly configured for the target environment.
- Ensure the appropriate database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Test all data access paths, including queries, transactions, and connection pooling behavior.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.