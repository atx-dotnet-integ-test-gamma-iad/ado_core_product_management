# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages reference old `net4x` or `netstandard` versions exclusively, consider finding updated alternatives on [NuGet.org](https://www.nuget.org).

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no issues beyond what was captured in the transformation output:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas of risk.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences in the new runtime or by platform-specific code that was not fully migrated.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that may have been available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- `AppDomain` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `System.Drawing` (requires the `System.Drawing.Common` package and may have OS limitations)
- WCF server-side components (require the `CoreWCF` packages as a replacement)

You can use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these systematically.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any OS-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and case sensitivity in file system operations, as these differ between Windows and Unix-based systems.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before deploying to the target environment.