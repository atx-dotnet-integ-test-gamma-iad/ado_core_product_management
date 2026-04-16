# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the target framework does not match your intended version, update it and rebuild the solution.

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Validate Runtime Behavior on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to confirm there are no platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Platform-specific APIs that may have been used in the original project (e.g., Windows Registry access, COM interop)
- Environment variable differences between platforms

## 5. Check for Removed or Changed APIs

Review the code for any use of APIs that were available in .NET Framework but have changed behavior or been removed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package can assist with this.

## 6. Review NuGet Package Compatibility

Verify that all NuGet dependencies referenced in `AdoCore.csproj` support the target framework. Check each package on [nuget.org](https://www.nuget.org) to confirm compatibility. Replace any packages that only support .NET Framework with their cross-platform equivalents.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime(s):

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Confirm the output in the publish directory contains all expected files and that the application runs correctly from the published output.