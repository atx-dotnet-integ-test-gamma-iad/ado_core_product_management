# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests that previously passed may indicate a behavioral difference between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Validate Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but may behave differently or have limited support in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires additional packages on non-Windows platforms)
- `System.Web` (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain` usage beyond what is supported

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility concerns.

## 5. Review Configuration Files

Ensure that any configuration previously held in `App.config` or `Web.config` has been properly migrated to the appropriate format:

- Console and library projects should use `appsettings.json` with `Microsoft.Extensions.Configuration`
- Verify connection strings, app settings, and custom configuration sections have been transferred correctly

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended target operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that do not surface at build time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS 64-bit

Review the publish output directory to confirm all required files and dependencies are present before deploying.