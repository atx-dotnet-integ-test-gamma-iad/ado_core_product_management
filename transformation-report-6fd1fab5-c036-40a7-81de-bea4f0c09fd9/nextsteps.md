# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The solution compiles without issues.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Verify that no warnings or errors appear during the restore process.

### 2. Build the Solution

Perform a full build to confirm the solution compiles cleanly:

```bash
dotnet build --configuration Release
```

Review the output to confirm there are zero errors and note any warnings that may need attention.

### 3. Run Unit Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --verbosity normal
```

Review test results and address any failing tests before proceeding.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with your organization's supported runtime version.

### 5. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently between .NET Framework and modern .NET. Review the following areas manually:

- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET.
- **Remoting**: `System.Runtime.Remoting` is not supported and has no direct replacement.
- **WCF**: If any WCF server-side components exist, they are not supported on modern .NET without using a community package such as `CoreWCF`.
- **AppDomain**: Some `AppDomain` members are no-ops or throw `PlatformNotSupportedException` on modern .NET.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

### 6. Run the Application

Execute the application directly to validate runtime behavior:

```bash
dotnet run --project AdoCore/AdoCore.csproj --configuration Release
```

Walk through the primary workflows of the application and confirm expected behavior.

### 7. Review Warnings

Even if the build succeeds, review any compiler warnings produced during the build step. Warnings related to nullable reference types, obsolete APIs, or platform compatibility attributes may indicate areas that require attention before the project is considered fully modernized.

### 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

```bash
# Framework-dependent
dotnet publish AdoCore/AdoCore.csproj --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish AdoCore/AdoCore.csproj --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the output in the `./publish` directory contains all expected files before deploying to the target environment.