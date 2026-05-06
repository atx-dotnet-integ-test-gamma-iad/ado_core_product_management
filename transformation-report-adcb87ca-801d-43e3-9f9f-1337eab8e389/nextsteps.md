# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Review the following areas manually:

- Any usage of `System.Web` (not available in cross-platform .NET)
- `AppDomain`, `Remoting`, or `BinaryFormatter` usage
- Windows-specific registry or file path assumptions (e.g., hardcoded `C:\` paths)
- Any P/Invoke calls that may be Windows-only

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) if a deeper API compatibility scan is needed.

## 5. Run Existing Tests

If the solution contains a test project, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:

- Database connectivity (ADO.NET connection strings and drivers may need updating)
- File I/O operations
- Any configuration files (e.g., `app.config` may need to be migrated to `appsettings.json`)

## 7. Validate Configuration Migration

If the project previously used `app.config` or `web.config`, confirm that settings have been moved to the appropriate cross-platform configuration mechanism:

```bash
# Ensure Microsoft.Extensions.Configuration packages are present if needed
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.Extensions.Configuration.Json
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish (optional, for environments without .NET runtime installed)
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish-selfcontained
```

Verify the contents of the `./publish` directory before deploying to the target environment.