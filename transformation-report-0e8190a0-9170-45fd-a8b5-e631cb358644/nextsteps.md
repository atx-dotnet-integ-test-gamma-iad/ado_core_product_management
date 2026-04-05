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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that may have been available in .NET Framework but behave differently or are unavailable on non-Windows platforms. Common areas to check include:

- `System.Drawing` (requires additional packages on Linux/macOS)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server usage
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

## 5. Review NuGet Package Compatibility

Inspect all NuGet package references in `AdoCore.csproj` and confirm each package supports the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by reviewing the `lib` folders inside the package directories in your local NuGet cache.

```bash
dotnet list package --outdated
```

Update any outdated packages that have newer versions with cross-platform support.

## 6. Validate Runtime Behavior

Run the application manually or through integration tests against a representative dataset or workload. Pay particular attention to:

- Database connectivity and ADO.NET provider behavior (given the `AdoCore` project name suggests data access)
- Connection string formats, which may differ between providers on cross-platform .NET
- Exception handling paths that may surface differently on non-Windows operating systems

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (e.g., Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you need to bundle the .NET runtime with the output.