# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them in the `.csproj` file as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate compatibility issues, such as obsolete API usage or platform-specific calls.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` usage (not available in .NET Core/.NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- COM interop or P/Invoke calls targeting Windows-specific libraries
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any remaining compatibility issues.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and test the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target platform. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the output directory to confirm all required files are present.

## 8. Review Output Artifacts

Inspect the published output to ensure no legacy configuration files (e.g., `app.config`, `web.config`) are missing or misconfigured for the new runtime environment. For web projects, confirm `appsettings.json` is correctly structured and present in the output.