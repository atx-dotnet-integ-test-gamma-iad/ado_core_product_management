# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to the following areas:

- **`System.Configuration`**: If the project previously used `App.config` or `ConfigurationManager`, verify that the `Microsoft.Extensions.Configuration` equivalents have been wired up correctly, or that the `System.Configuration.ConfigurationManager` NuGet package has been added.
- **`System.Data` / ADO.NET**: Since the project is named `AdoCore`, confirm that all database providers (e.g., `System.Data.SqlClient` or `Microsoft.Data.SqlClient`) are explicitly referenced as NuGet packages, as they are no longer included in the base framework.
- **Platform-specific APIs**: Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal.

## 5. Validate NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For each package, confirm it supports the target framework by checking [NuGet.org](https://www.nuget.org). Replace any packages that only target `net4x` with their cross-platform equivalents.

## 6. Review Removed or Changed APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify any API usage that may behave differently on non-Windows platforms.

## 7. Test Database Connectivity

Since this project involves ADO.NET (`AdoCore`), perform integration testing against the actual database to confirm:

- Connection strings are correctly read from the new configuration system.
- All queries, stored procedure calls, and transactions execute as expected.
- Exception handling around `SqlException` or equivalent provider exceptions still functions correctly.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.