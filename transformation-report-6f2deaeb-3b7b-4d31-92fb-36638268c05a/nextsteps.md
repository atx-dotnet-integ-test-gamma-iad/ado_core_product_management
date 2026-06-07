# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to surface any runtime-level issues that do not appear as build errors:

```bash
dotnet tool install -g dotnet-upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage, given the `AdoCore` project name suggests database interaction.
- Any usage of `System.Configuration.ConfigurationManager`, which requires the `System.Configuration.ConfigurationManager` NuGet package in cross-platform .NET.
- Windows-specific APIs such as the registry or certain `System.Drawing` features.

## 5. Validate ADO.NET and Database Connectivity

Since the project is named `AdoCore`, verify that database connections function correctly in the new runtime:

- Confirm the correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Test connection strings and ensure they are being read correctly from configuration sources such as `appsettings.json` rather than `app.config` or `web.config` if those were migrated.

## 6. Review NuGet Package Versions

Check that all NuGet dependencies are up to date and compatible with the target framework:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify that no packages still target only .NET Framework.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime behavior that would not surface during a build.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present. If a self-contained deployment is needed, add the runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```