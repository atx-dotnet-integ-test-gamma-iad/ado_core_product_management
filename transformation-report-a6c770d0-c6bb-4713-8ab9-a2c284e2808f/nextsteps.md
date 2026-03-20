# Next Steps

The solution has no build errors following the transformation. The migration to cross-platform .NET appears to have completed successfully. The following steps outline how to validate, test, and deploy the project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures that were not present before the migration should be investigated, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs. Use the .NET Compatibility Analyzer to identify any remaining platform-specific calls:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any `CA1416` warnings, which flag APIs that are only supported on specific platforms.

## 5. Review Target Framework Monikers

Open each `.csproj` file and confirm that the `<TargetFramework>` element references an appropriate modern TFM such as `net8.0` or `net9.0`. Ensure no project still references `net472` or similar legacy monikers unless interoperability with .NET Framework is explicitly required.

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent mechanisms compatible with `Microsoft.Extensions.Configuration`. Test that all configuration values are read correctly at runtime.

## 7. Perform Runtime Smoke Testing

Run the application locally and exercise its primary code paths. Focus on areas that commonly differ between .NET Framework and cross-platform .NET, including:

- Serialization and deserialization behavior
- Reflection-based operations
- File path handling (path separator differences between Windows and Linux/macOS)
- Culture and encoding defaults

## 8. Review Removed or Changed APIs

Consult the official .NET migration guide for any APIs that were removed or had their behavior changed. The following resource is useful for this:

[https://learn.microsoft.com/en-us/dotnet/core/compatibility/](https://learn.microsoft.com/en-us/dotnet/core/compatibility/)

## 9. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) if deploying to a non-Windows environment. Review the publish output directory to confirm all required assets are present.