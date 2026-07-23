# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full solution build to confirm the error-free state holds under a clean build:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing.

### 3. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior is consistent with the pre-migration state:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Note any failing tests and compare results against a known baseline from the legacy project if one is available.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the runtime version installed on all target machines.

### 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available in .NET Framework but behave differently or throw at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface any such issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Review any new diagnostics produced and address platform-specific code paths accordingly.

### 6. Verify Configuration and App Settings

If the project previously relied on `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables as appropriate for the new hosting model.

### 7. Smoke Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime issues that static analysis would not surface:

```bash
dotnet run --configuration Release
```

Observe application startup, core workflows, and any platform-dependent features such as file paths, registry access, or Windows-specific authentication.

### 8. Review Output Artifacts

Publish the project and inspect the output to confirm all expected assemblies, configuration files, and assets are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Compare the contents of the `./publish` directory against the expectations for your deployment environment.