# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility issues that were not caught as errors, such as platform-specific API usage.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether the failures are due to the migration or pre-existing issues.

## 4. Check for Platform-Specific API Usage

Even without build errors, certain APIs may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Rebuild and review any new analyzer warnings related to platform compatibility.

## 5. Validate NuGet Dependencies

Confirm that all NuGet packages referenced in `AdoCore.csproj` support the target framework. Check each package on [nuget.org](https://www.nuget.org) or run:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target TFM with supported alternatives.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, registry access, and any Windows-specific interop code.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying.