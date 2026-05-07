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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs. Use the .NET Compatibility Analyzer to identify any remaining platform-specific calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any diagnostics produced and replace or conditionally compile platform-specific code where necessary.

## 5. Check Target Framework Monikers

Open each `.csproj` file and confirm that the `<TargetFramework>` element references an appropriate modern TFM such as `net8.0` or `net9.0`, rather than a legacy value like `net472` or `netstandard2.0`, where applicable.

## 6. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to the appropriate `appsettings.json` format if the project uses `Microsoft.Extensions.Configuration`. Legacy configuration sections are not supported in cross-platform .NET without additional compatibility shims.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay attention to:

- File path handling, as cross-platform .NET uses `Path.Combine` and forward-slash conventions on non-Windows systems.
- Registry access, which is Windows-only.
- Any use of `System.Drawing` or `System.Windows.Forms`, which require additional packages or are unsupported on non-Windows platforms.

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier as needed:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

For a cross-platform deployment, omit the `--runtime` flag or specify the appropriate RID for your target platform (e.g., `linux-x64`, `osx-x64`).

Review the publish output directory to confirm all required assets and dependencies are present before deploying.