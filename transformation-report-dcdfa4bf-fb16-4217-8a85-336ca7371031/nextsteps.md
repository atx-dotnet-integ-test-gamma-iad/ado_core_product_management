# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not fully support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the restored packages:

```bash
dotnet clean
dotnet build
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved after the migration:

```bash
dotnet test
```

Review the test results carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during the migration or a pre-existing issue.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-only interop or P/Invoke calls
- `AppDomain` usage patterns that behave differently in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific dependencies if needed.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release
```

Review the output directory to confirm all required files are present before distributing or deploying the application.