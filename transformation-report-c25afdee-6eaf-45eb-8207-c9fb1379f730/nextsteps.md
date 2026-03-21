# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the .NET SDK version installed on your machine by running:

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

Perform a clean build to confirm there are no compile-time issues:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some may indicate runtime issues that do not surface as errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific APIs

Search the codebase for APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` methods that are no longer supported
- `BinaryFormatter` (deprecated and disabled by default)
- COM interop dependencies

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package can assist with identifying these.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path separators, line endings, and case-sensitive file systems on Linux.

## 7. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Confirm that connection strings, application settings, and environment-specific values are correctly represented.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the output directory to confirm all required files are present before deployment.