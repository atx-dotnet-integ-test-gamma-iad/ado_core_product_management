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

Update any packages that have newer stable versions available, particularly those that were previously targeting .NET Framework.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET. Review the code for usage of:

- `System.Web` (not available in .NET Core/.NET 5+)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if not explicitly targeted)
- `AppDomain`, `BinaryFormatter`, or `Remoting` APIs which are restricted or removed

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any runtime compatibility concerns.

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to validate runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any test failures that may indicate behavioral differences between .NET Framework and the new target framework.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary code paths manually or through integration tests:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:

- Database connectivity (ADO.NET connection strings and provider names may differ)
- File I/O paths (path separators differ on Linux/macOS)
- Configuration loading (e.g., `app.config` is replaced by `appsettings.json` in modern .NET)

## 7. Validate Configuration Migration

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used to read them.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.