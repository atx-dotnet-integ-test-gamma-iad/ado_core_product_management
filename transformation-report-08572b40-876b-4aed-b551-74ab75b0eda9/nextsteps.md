# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing.

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to a supported, non-end-of-life version of .NET, such as `net8.0`:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it is targeting an older version such as `net5.0` or `net6.0`, consider updating it to a current long-term support (LTS) release.

### 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Runtime-Specific APIs

Even when a project builds successfully, certain APIs behave differently or are unsupported on non-Windows platforms. Review the code for usage of the following:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages on Linux/macOS)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific P/Invoke calls
- `AppDomain` usage beyond what is supported in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific dependencies.

### 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues not caught at build time.

### 7. Review Configuration Files

Ensure that any configuration previously handled by `App.config` or `Web.config` has been correctly migrated to `appsettings.json` or environment-based configuration, as the legacy XML-based configuration system has limited support in modern .NET.

### 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assets and dependencies are present before deployment.