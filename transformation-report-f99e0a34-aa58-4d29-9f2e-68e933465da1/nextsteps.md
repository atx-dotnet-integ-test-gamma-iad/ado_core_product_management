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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced during migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Compatibility Analyzer or the following CLI tool to scan for platform-specific API usage that may not be available on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to APIs in namespaces such as `Microsoft.Win32`, `System.Windows.Forms`, or `System.Drawing` if cross-platform support is required.

## 6. Test on Target Platforms

If the goal is cross-platform support, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Review Output Artifacts

Publish the application and inspect the output to confirm all required files and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify that the published output runs correctly in an environment that mirrors your intended deployment target.

## 8. Review Removed or Changed References

Compare the original project references and NuGet packages against the migrated versions. Confirm that any packages that were updated during transformation are functionally equivalent and that no required packages were inadvertently removed.