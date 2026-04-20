# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated packages or version conflicts. If any packages targeting the old .NET Framework are still present, check for their .NET-compatible equivalents on [NuGet.org](https://www.nuget.org).

## 2. Build the Solution

Perform a full solution build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Review all warnings in the build output. While warnings do not block compilation, they may indicate areas of the code that use obsolete APIs or patterns that should be addressed.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or serialization behavior).

## 4. Review Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but may behave differently or have limited support in cross-platform .NET. Common areas to review include:

- `System.Windows.Forms` or `System.Web` usage (these are not fully cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop (`DllImport` with Windows-only DLLs)
- `AppDomain` usage, as some members are no longer supported
- `BinaryFormatter`, which is disabled by default in modern .NET due to security concerns

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these issues systematically.

## 5. Validate Configuration Files

Check that any configuration previously handled by `App.config` or `Web.config` has been correctly migrated to the appropriate modern equivalents:

- `appsettings.json` for application settings
- `Microsoft.Extensions.Configuration` for configuration access patterns
- Environment variables where applicable

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and test the application on each intended target operating system (e.g., Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Review Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If long-term support is a requirement, ensure you are targeting an LTS release of .NET (e.g., .NET 8).

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` flag to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`). Review the publish output directory to confirm all required files are present.