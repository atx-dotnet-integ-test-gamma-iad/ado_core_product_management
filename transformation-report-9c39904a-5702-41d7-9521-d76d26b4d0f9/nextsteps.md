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

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced during migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Compatibility Analyzer or the following CLI tool to scan for platform-specific API usage that may not behave correctly on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to usage of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls that rely on Windows-native libraries.

## 6. Run on Target Platforms

If cross-platform support is a goal, test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Review Configuration Files

Check that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy XML-based configuration is not fully supported in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required files are present.