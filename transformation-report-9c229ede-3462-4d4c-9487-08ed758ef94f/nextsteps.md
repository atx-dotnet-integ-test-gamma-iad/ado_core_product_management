# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as errors.

## 3. Review Removed or Replaced Dependencies

Check that any NuGet packages that were previously targeting .NET Framework have been replaced with their .NET-compatible equivalents. Review the `<PackageReference>` entries in `AdoCore.csproj` and cross-reference them against [NuGet.org](https://www.nuget.org) to confirm each package supports your target framework.

## 4. Run Existing Tests

If there are test projects in the solution, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or reflection behavior).

## 5. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific under .NET Framework and may now throw `PlatformNotSupportedException` on non-Windows platforms. Common areas include:

- `System.Drawing`
- `Microsoft.Win32.Registry`
- Windows Communication Foundation (WCF) server-side APIs
- `System.Security.Permissions`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis may not detect.

## 7. Validate Application Behavior

Perform functional testing of the application to confirm that the migrated version produces the same outputs and side effects as the original .NET Framework version. Pay particular attention to:

- Database connectivity and query results
- File I/O paths and behavior
- Configuration file loading (`appsettings.json` vs. `app.config`)
- Serialization and deserialization logic

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present before deploying to the target environment.