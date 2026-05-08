# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless there is a specific reason to retain them.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate platform-specific behavior differences between .NET Framework and cross-platform .NET.

## 5. Check for Windows-Specific APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+) usage outside of Windows

## 6. Run the Application and Perform Smoke Testing

Start the application and exercise its primary workflows manually or through integration tests:

```bash
dotnet run --project <YourStartupProject> --configuration Release
```

Confirm that configuration files (e.g., `appsettings.json`), connection strings, and environment-specific settings are loading correctly under the new hosting model.

## 7. Review Removed or Changed Configuration

If the original project used `app.config` or `web.config`, verify that all relevant settings have been migrated to `appsettings.json` or environment variables, as the behavior of configuration providers differs between .NET Framework and cross-platform .NET.

## 8. Validate on Target Platforms

If cross-platform support is a goal, run the build and test steps above on each target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during compilation.

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier as appropriate for your deployment targets.