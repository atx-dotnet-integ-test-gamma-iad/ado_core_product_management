# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures that did not exist before migration may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Use the .NET Compatibility Analyzer to check for any APIs that may not be supported on all target platforms. You can enable this by ensuring the following is set in your project files:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Pay particular attention to any code that previously relied on Windows-specific APIs such as the registry, Windows Communication Foundation (WCF), or certain System.Drawing functionality.

## 5. Review Target Framework Monikers

Open each `.csproj` file and confirm the `<TargetFramework>` value is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If any project still references `net472` or similar legacy monikers, update them accordingly.

## 6. Test Runtime Behavior

Run the application manually and exercise the primary workflows to confirm functional correctness. Pay attention to:

- File path handling, as path separators differ between Windows and Linux/macOS.
- Configuration file loading, particularly if the project previously used `App.config` or `Web.config`, which behave differently under cross-platform .NET.
- Any reflection-based code, which may behave differently due to trimming or assembly loading changes.

## 7. Review NuGet Package Versions

Check that all NuGet dependencies have versions that support the target framework. You can audit this with:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support or address known compatibility issues.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

If targeting a specific runtime, include the runtime identifier, for example:

```bash
dotnet publish --configuration Release -r linux-x64 --self-contained false --output ./publish
```

Review the published output to confirm all required assets and dependencies are present.