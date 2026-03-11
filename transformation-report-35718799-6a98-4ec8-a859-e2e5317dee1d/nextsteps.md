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

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages still reference the old `net4x` or `.NETFramework` target, consider finding their cross-platform equivalents on [NuGet.org](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, even if there are no errors. Warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers should be addressed before moving forward.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that may not behave correctly on non-Windows operating systems. You can enable this by ensuring the following is present in your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild after adding these properties and review any new diagnostics.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time. Pay particular attention to:

- File path separators
- Registry access (not available on Linux/macOS)
- Windows-specific APIs such as those in `System.Drawing` or `Microsoft.Win32`

## 7. Review Configuration and App Settings

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or environment variables, which are the standard configuration mechanisms in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`). Review the contents of the `publish` output folder to confirm all required assets are present before deploying.