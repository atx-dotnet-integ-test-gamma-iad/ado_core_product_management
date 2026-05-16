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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failures that did not exist before the migration should be investigated as potential regressions introduced during the transformation.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Compatibility Analyzer or review the code manually for any usage of Windows-specific APIs such as the registry, Windows Forms, or WPF components. These will not function on Linux or macOS without additional configuration or replacement.

You can also run the following to surface platform compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

## 6. Validate Runtime Behavior

Run the application and exercise its primary workflows to confirm functional correctness. Pay particular attention to:

- File path handling, as Windows-style paths (`\`) may cause issues on Linux/macOS.
- Configuration file loading, particularly if `app.config` was used and has been migrated to `appsettings.json`.
- Any reflection-based code, which may behave differently under newer .NET runtimes.

## 7. Review Removed or Changed APIs

Cross-reference your codebase against the [.NET Upgrade Assistant breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for the specific .NET version you are targeting. Some APIs available in .NET Framework may have been removed or have different behavior in modern .NET.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific platform, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) based on your deployment target.