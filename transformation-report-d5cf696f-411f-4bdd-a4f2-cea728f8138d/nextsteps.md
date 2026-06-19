# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file(s) and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, then rebuild to confirm no new errors are introduced.

## 4. Run Existing Tests

If the solution contains test projects, execute them to validate runtime behavior:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around areas such as:

- `System.Configuration` usage
- Windows-specific APIs (e.g., registry access, COM interop)
- Reflection behavior differences
- Globalization and encoding defaults

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior or may throw `PlatformNotSupportedException` at runtime on non-Windows systems. Use the .NET Compatibility Analyzer or review the Microsoft documentation for any APIs flagged during the original transformation.

You can also run the following to check for platform compatibility issues:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application and its tests on each intended operating system (e.g., Linux, macOS) to surface any platform-specific runtime issues that would not appear on Windows.

## 7. Validate Application Behavior

Perform functional testing against the running application to confirm that the migrated behavior matches the legacy version. Pay particular attention to:

- Database connectivity and ADO.NET operations (given the `AdoCore` project name)
- Connection string formats, which may differ between `System.Data` implementations
- Any use of `DataSet`, `DataTable`, or `DataAdapter` classes, which are supported but have some behavioral differences

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.