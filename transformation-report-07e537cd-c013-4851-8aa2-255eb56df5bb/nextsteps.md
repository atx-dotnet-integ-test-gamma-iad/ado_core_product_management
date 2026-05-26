# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any test failures should be investigated before proceeding, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs (e.g., `System.Drawing`, `Microsoft.Win32` registry access, WCF server-side hosting, etc.). Use the .NET Upgrade Assistant compatibility analyzer or the following command to check for platform compatibility issues:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Review any `CA1416` (platform compatibility) warnings in the output.

## 5. Review Target Framework

Open the `AdoCore.csproj` file and confirm the target framework moniker (TFM) is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project needs to remain compatible with .NET Framework for any consumers, consider using multi-targeting:

```xml
<TargetFrameworks>net8.0;net472</TargetFrameworks>
```

## 6. Validate Runtime Behavior

Run the application manually or through its primary entry point and exercise its core functionality. Pay particular attention to:

- File path handling, as .NET on Linux/macOS is case-sensitive.
- Configuration file loading (e.g., `app.config` vs `appsettings.json`).
- Any reflection-based code that may behave differently under the new runtime.

## 7. Review NuGet Package Versions

Check that all referenced NuGet packages have versions compatible with the target framework. Outdated packages that were written for .NET Framework may have newer versions with cross-platform support:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify that updated versions do not introduce breaking API changes.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) for your target environment.