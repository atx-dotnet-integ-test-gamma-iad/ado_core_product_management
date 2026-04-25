# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the target framework does not match your intended version, update it and rebuild the solution.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and resolve them before proceeding.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete API usage, as these can indicate compatibility issues at runtime.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality behaves as expected after the migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but are not fully supported or behave differently in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires the `System.Drawing.Common` package and may have OS-specific limitations)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components (not supported; consider CoreWCF as a replacement)
- `AppDomain` usage beyond the single default domain
- `System.Runtime.Remoting` (not supported)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility concerns.

## 6. Test on Target Operating Systems

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface during compilation:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, and any OS-specific behavior in your data access or I/O code.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release
```

Review the contents of the `publish` output directory to confirm all required assets and dependencies are present before deploying to your target environment.