# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior matches expectations after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to identify these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+)
- `AppDomain` usage beyond what is supported in .NET Core+

## 5. Review NuGet Package Versions

Confirm that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. Check for any packages that may have been carried over from the legacy project and have since been superseded:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify that no packages are targeting `net45`, `net46`, or similar legacy monikers exclusively.

## 6. Validate Configuration Files

If the project previously relied on `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration mechanisms. The legacy XML-based configuration system has limited support in modern .NET.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that are not caught at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets are present before deploying to the target environment.