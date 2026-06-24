# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command in the root of your solution to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated packages or version conflicts. If any packages were targeting the old .NET Framework, check if their cross-platform equivalents are available on [NuGet](https://www.nuget.org).

## 2. Build the Solution

Perform a full build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, even if the build succeeds. Warnings related to obsolete APIs or platform compatibility should be addressed before deployment.

## 3. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Pay close attention to any tests that exercise platform-specific functionality such as file I/O paths, registry access, Windows-specific APIs, or COM interop, as these are common sources of cross-platform issues that may not surface as build errors.

## 4. Check for Platform-Specific Code

Even without build errors, there may be runtime issues caused by platform-specific APIs that compile successfully but fail at runtime on non-Windows systems. Review the codebase for usage of:

- `Microsoft.Win32` namespace
- `System.Runtime.InteropServices` with Windows-specific P/Invoke calls
- Hardcoded Windows-style file paths (e.g., `C:\`)
- `System.Drawing` (GDI+ based, limited on non-Windows without additional packages)
- `System.Web` (not available in .NET Core/.NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with identifying these areas.

## 5. Validate Configuration Files

Check that any configuration files (e.g., `appsettings.json`, `app.config`, `web.config`) have been properly migrated. In modern .NET:

- `app.config` and `web.config` are largely replaced by `appsettings.json` and the `Microsoft.Extensions.Configuration` system.
- Connection strings, app settings, and environment-specific values should be reviewed and moved to the appropriate configuration structure.

## 6. Run the Application Manually

Execute the application directly and walk through its primary workflows to identify any runtime exceptions that would not be caught by automated tests:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Monitor the console output and application logs for unhandled exceptions or unexpected behavior.

## 7. Publish the Application

Once validation is complete, publish the application for your target environment. For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Replace `win-x64` with the appropriate runtime identifier (RID) for your target platform (e.g., `linux-x64`, `osx-x64`). A full list of RIDs is available in the [Microsoft documentation](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

For a framework-dependent deployment (requires .NET runtime installed on the target machine):

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required assets, configuration files, and dependencies are present before deploying to the target environment.