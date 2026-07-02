# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated packages or version conflicts. If any packages targeting the old .NET Framework are still present, consider finding their cross-platform equivalents on [NuGet.org](https://www.nuget.org).

## 2. Build the Solution

Perform a full solution build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Review any warnings in the output. While warnings do not prevent a build from succeeding, they may indicate areas of the code that could cause runtime issues.

## 3. Run Unit Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated and resolved before proceeding further.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net472` or other Windows-only framework monikers unless there is a specific reason to do so.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may behave differently or throw exceptions at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to areas of the code that use:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file paths or environment variables
- COM interop
- `System.Drawing` (which has platform limitations outside of Windows)

## 6. Run the Application

Execute the application on each target platform (Windows, Linux, macOS as applicable) to observe runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly those that interact with external systems such as databases, file systems, or network resources.

## 7. Review Configuration Files

Check that any configuration files (e.g., `appsettings.json`, connection strings, environment-specific settings) have been properly migrated from the legacy `App.config` or `Web.config` format to the modern `appsettings.json` format compatible with `Microsoft.Extensions.Configuration`.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the output directory to confirm all required files are present before deployment.