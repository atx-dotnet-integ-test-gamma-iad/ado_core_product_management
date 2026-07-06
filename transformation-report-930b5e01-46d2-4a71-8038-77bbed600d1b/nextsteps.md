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

Review test results carefully. Any failures should be investigated to determine whether they stem from migration-related changes or pre-existing issues.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element references the intended .NET version (e.g., `net8.0`). Ensure consistency across all projects in the solution.

## 5. Check for Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Tools that can assist with this include:

```bash
dotnet tool install -g dotnet-apicompat
```

The [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) can also flag compatibility concerns if not already used.

## 6. Review Configuration Files

Confirm that any `app.config` or `web.config` files have been properly migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that connection strings, application settings, and environment-specific values are correctly represented.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay attention to:

- File path handling, as cross-platform .NET uses forward slashes on Linux/macOS
- Registry access, which is Windows-only
- Windows-specific APIs such as `System.Drawing` (GDI+), which may require additional packages like `System.Drawing.Common` or replacement libraries

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 9. Review Output Artifacts

Inspect the contents of the publish output directory to confirm all required files, assets, and dependencies are present before deploying to the target environment.