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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding further.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may not surface as build errors but will fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, review any usage of APIs such as `System.Windows.Forms`, `System.Drawing`, `Registry`, or P/Invoke calls that target Windows libraries.

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Linux, macOS, Windows) to catch any runtime-only issues:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable differences, and any platform-specific behavior in configuration loading.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime(s):

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your deployment target. Common options include:

- `win-x64`
- `linux-x64`
- `osx-x64`
- `osx-arm64`

Review the publish output directory to confirm all required assets are present.

## 8. Review Configuration Files

Ensure that any `App.config` or `Web.config` files have been properly migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy XML-based configuration is not fully supported in cross-platform .NET.