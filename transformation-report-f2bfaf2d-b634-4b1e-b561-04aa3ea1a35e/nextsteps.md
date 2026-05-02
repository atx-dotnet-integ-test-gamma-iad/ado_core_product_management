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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any runtime-level compatibility issues that do not surface as build errors.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze AdoCore.csproj
```

## 5. Validate NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. You can inspect this in the `.csproj` file or by running:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that are outdated or deprecated to their current stable versions.

## 6. Test on Target Operating Systems

Since the goal of the migration is cross-platform support, run and test the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues, particularly around:

- File path separators
- Registry access (not available on Linux/macOS)
- Windows-specific interop or P/Invoke calls

## 7. Review Configuration and Environment Settings

If the project previously used `app.config` or `web.config`, verify that configuration has been migrated to `appsettings.json` or environment variables, which are the standard configuration mechanisms in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish -c Release -o ./publish

# Self-contained deployment for a specific platform
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Verify the output in the `./publish` directory runs correctly on the target machine.