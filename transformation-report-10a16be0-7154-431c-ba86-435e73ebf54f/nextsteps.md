# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including the core project `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while not blocking the build, may indicate compatibility concerns with the target framework.

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended modern .NET version (e.g., `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple target frameworks are needed, verify `<TargetFrameworks>` is configured correctly.

### 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and modern .NET.

### 5. Check for Removed or Changed APIs

Even with a clean build, some APIs behave differently on modern .NET. Pay particular attention to:

- **`System.Web`** dependencies, which are not available on cross-platform .NET.
- **Remoting and AppDomain** usage, which has limited support.
- **Binary serialization** (`BinaryFormatter`), which is disabled by default in .NET 5+.
- **Windows-specific APIs**, which will fail at runtime on non-Windows platforms if not guarded.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility issues.

### 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not appear during compilation.

### 7. Review Configuration Files

Ensure that any configuration previously held in `App.config` or `Web.config` has been properly migrated to `appsettings.json` or the appropriate modern .NET configuration mechanism, and that the application reads these values correctly at runtime.

### 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the output directory and confirm the application runs correctly from the published output before deploying to the target environment.