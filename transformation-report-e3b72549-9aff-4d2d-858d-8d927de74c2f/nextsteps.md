# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that were downgraded. Pay attention to any packages that previously targeted `net4x` or `netstandard` and confirm their cross-platform compatibility.

## 3. Build the Solution

Perform a clean build to confirm no errors surface during compilation:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output. Warnings related to obsolete APIs or platform compatibility analyzers (e.g., `CA1416`) should be addressed before deployment.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Compare test results against any previously recorded baselines from the legacy project.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility analyzer to identify any APIs that may not behave identically across operating systems:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable the `EnableNETAnalyzers` property in the `.csproj` file:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any new diagnostics.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior. Pay particular attention to:

- File path separators (`/` vs `\`)
- Registry access calls, which are Windows-only
- `System.Drawing` usage, which requires additional native dependencies on Linux/macOS
- Any P/Invoke or interop code that references platform-specific native libraries

## 7. Review Configuration Files

Confirm that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy configuration sections are not supported in cross-platform .NET without additional packages.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with your intended runtime identifier (RID), such as `win-x64` or `osx-x64`. Review the publish output directory to confirm all required files are present.