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

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Pay particular attention to:

- **Registry access** (`Microsoft.Win32.Registry`) — not available on Linux/macOS without additional packages.
- **Windows Communication Foundation (WCF)** — client support is available via `System.ServiceModel` packages, but server-side hosting is not supported.
- **`System.Drawing`** — requires the `System.Drawing.Common` NuGet package and may have platform restrictions.
- **`AppDomain`** — some members are not supported and will throw `PlatformNotSupportedException` at runtime.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

## 5. Review NuGet Package Versions

Open the `.csproj` file and verify that all NuGet dependencies reference versions that are compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and confirm that no packages still target `net45`, `net461`, or other legacy monikers exclusively.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment-based configuration as appropriate for .NET. The `System.Configuration.ConfigurationManager` NuGet package can provide backward compatibility if a full migration is not yet feasible.

## 7. Test on Target Platform

If the goal is cross-platform execution, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build and test pass.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected assemblies and configuration files are present before deploying to the target environment.