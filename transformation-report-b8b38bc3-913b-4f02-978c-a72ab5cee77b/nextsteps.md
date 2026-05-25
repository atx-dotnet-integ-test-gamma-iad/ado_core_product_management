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

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility shims.

## 3. Build the Solution

Perform a clean build to confirm the absence of errors in a fresh build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` result files for any test failures that may indicate behavioral differences introduced by the framework change.

## 5. Check for Windows-Specific API Usage

Because this is a cross-platform migration, run the .NET Compatibility Analyzer to surface any remaining platform-specific API calls:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416` (platform compatibility). Any flagged APIs that are Windows-only will need to be guarded with `OperatingSystem.IsWindows()` checks or replaced with cross-platform alternatives.

## 6. Validate ADO-Specific Functionality

Given the project name (`AdoCore`), manually verify that all data access operations function correctly:

- Test all database connection strings to confirm they are compatible with the ADO.NET providers available on .NET.
- If `System.Data.OleDb` was used in the original project, note that it is only supported on Windows. Replace it with an appropriate cross-platform provider (e.g., `Microsoft.Data.SqlClient` for SQL Server).
- If `System.Data.Odbc` is used, verify the target platform has the required ODBC drivers installed.

## 7. Run on the Target Platform

If the intended deployment target is Linux or macOS, execute the application on that platform explicitly to catch any runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent deployment as appropriate:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and confirm all expected assemblies and configuration files are present before deploying to the target environment.