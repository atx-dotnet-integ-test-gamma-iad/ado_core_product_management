# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously targeted .NET Framework.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET. Review the following areas:

- **`System.Data`** and ADO.NET usage — confirm that any database providers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct cross-platform variants.
- **`ConfigurationManager`** — if used, ensure it is replaced with `Microsoft.Extensions.Configuration` or that the `System.Configuration.ConfigurationManager` NuGet package is explicitly referenced.
- **Registry, WCF, or Windows-specific APIs** — these are not available on non-Windows platforms. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) to identify any remaining platform-specific calls.

## 5. Run Existing Tests

If the solution contains test projects, execute them to validate runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any failures. Pay close attention to tests that cover database connectivity, configuration loading, or file I/O, as these areas are most commonly affected by cross-platform migrations.

## 6. Perform Runtime Smoke Testing

Run the application directly and exercise its core functionality manually or through integration tests:

```bash
dotnet run --project AdoCore --configuration Release
```

Verify that database connections, queries, and any data access logic function as expected against your target database.

## 7. Validate on Target Operating System

If cross-platform support (Linux or macOS) is a goal, run the application on the intended non-Windows platform to surface any remaining OS-specific issues:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then execute the published output on the target machine and confirm expected behavior.

## 8. Review Output Type and Entry Point

If `AdoCore` is a library, confirm that `<OutputType>` is not set to `Exe`. If it is an executable, confirm a valid `Program.cs` entry point exists and that startup configuration (e.g., connection strings) is correctly loaded from `appsettings.json` or environment variables rather than `app.config`.