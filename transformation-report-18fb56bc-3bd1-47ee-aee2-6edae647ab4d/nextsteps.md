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

Verify that no warnings or errors appear in the output. Pay attention to any `NU` prefixed NuGet warnings, as they may indicate package compatibility issues that did not surface as hard errors.

## 3. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may throw at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any resulting analyzer warnings in your IDE or build output and replace Windows-specific APIs with cross-platform alternatives where applicable.

## 4. Run Existing Tests

If the solution contains test projects, execute them to confirm runtime behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 5. Validate on Target Operating Systems

If cross-platform support is a goal, run the application or tests on each intended operating system (e.g., Linux, macOS) to catch any runtime issues not visible on Windows:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Registry access (not available on Linux/macOS)
- Windows-specific interop or P/Invoke calls

## 6. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Check that each package supports the new target framework by reviewing the package on [nuget.org](https://www.nuget.org) and confirming the listed supported frameworks include your TFM.

## 7. Check Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables, as `System.Configuration` support is limited in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate RID (e.g., `win-x64`, `osx-x64`) for your deployment target. Review the output in the `publish` folder before deploying.