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

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced by the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Compatibility Analyzer or review the code manually for any usage of Windows-specific APIs such as the Windows Registry, `System.Windows.Forms`, or `System.Drawing` (GDI+). These will not function correctly on Linux or macOS without additional configuration or replacement libraries.

You can also run the following command to surface platform compatibility warnings:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

## 6. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been replaced or supplemented with the appropriate `appsettings.json` files and that configuration is being loaded using `Microsoft.Extensions.Configuration` where applicable.

## 7. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable differences across operating systems

## 8. Publish the Application

Once validation is complete, publish the application using the following command, substituting the appropriate runtime identifier (RID) for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Common runtime identifiers include:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS (Intel)
- `osx-arm64` for macOS (Apple Silicon)

Review the publish output directory to confirm all required files and dependencies are present before deploying.