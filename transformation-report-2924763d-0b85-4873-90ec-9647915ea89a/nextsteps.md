# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any test failures should be investigated before proceeding, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs (e.g., `System.Drawing`, `Microsoft.Win32.Registry`, certain `System.Windows.Forms` members). Run the .NET Compatibility Analyzer to identify any remaining platform-specific calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review analyzer output in your IDE or build log and replace or conditionally compile any flagged APIs.

## 5. Check Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File path handling, as cross-platform .NET uses `Path.Combine` and forward slashes on non-Windows systems.
- Configuration file loading, particularly if the project previously relied on `app.config` or `web.config` with `ConfigurationManager`.
- Reflection-based code, which may behave differently under the new runtime.

## 6. Review Target Framework

Open the `.csproj` file(s) and confirm the target framework moniker (TFM) is set appropriately for your intended deployment targets:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If Windows-only features are required, consider using:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. Review the contents of the `publish` output folder before deploying.