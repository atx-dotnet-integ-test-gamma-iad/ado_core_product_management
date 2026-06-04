# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can verify your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` result files for any failures or skipped tests that may indicate runtime behavioral differences between the legacy framework and the new target.

## 5. Check for Windows-Specific API Usage

Because this project was migrated from a legacy (likely Windows-only) codebase, run the .NET Compatibility Analyzer to surface any platform-specific API calls that may fail on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416` (platform compatibility). Any flagged APIs will need to either be guarded with `OperatingSystem.IsWindows()` checks or replaced with cross-platform alternatives.

## 6. Validate Runtime Behavior

Run the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

If `AdoCore` is a library rather than an executable, write or run an integration test or a small console harness that exercises its primary public API surface.

## 7. Review NuGet Package Versions

Check that all referenced NuGet packages have stable releases compatible with your chosen TFM. Packages that previously targeted `net4x` may have newer major versions with breaking API changes. Consult each package's release notes for migration guidance.

## 8. Publish the Project

Once validation is complete, publish a self-contained or framework-dependent release artifact:

**Framework-dependent:**
```bash
dotnet publish AdoCore.csproj --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish AdoCore.csproj --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.