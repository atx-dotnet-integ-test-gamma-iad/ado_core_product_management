# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet.org for updated versions that support modern .NET.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee behavioral equivalence with the original .NET Framework version, so test coverage is important here.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET, including:

- `System.Web` references
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage beyond what is supported
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to assist with this review.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and environment variable differences across platforms.

## 7. Review Configuration Files

Ensure any configuration previously handled by `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables, which are the standard configuration mechanisms in modern .NET.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate RID, such as `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Review the publish output directory to confirm all required files and dependencies are present before deploying.