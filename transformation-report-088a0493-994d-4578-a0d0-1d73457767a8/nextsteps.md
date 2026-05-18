# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests that previously passed may indicate a behavioral difference between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution, particularly for shared libraries.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- Remoting or binary serialization

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

## 6. Test on Target Platforms

Since the project is now cross-platform, validate it runs correctly on each operating system you intend to support:

```bash
dotnet run --configuration Release
```

Run this on Windows, Linux, and/or macOS as applicable to your deployment targets. Pay attention to file path separators, line endings, and environment variable handling, which can differ across platforms.

## 7. Review Configuration Files

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration system. Verify that configuration is loaded correctly at runtime.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, etc.).

## 9. Review Output Artifacts

Inspect the contents of the publish output directory to confirm all required files, assemblies, and configuration files are present before deploying to the target environment.