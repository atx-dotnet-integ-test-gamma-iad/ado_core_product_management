# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so test coverage is critical at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution to avoid inter-project compatibility issues.

## 5. Check for Removed or Changed APIs

Run the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs that may have been removed or changed in the target framework version. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs that may require the `<RuntimeIdentifier>` to be set
- Any reflection-based code that may behave differently

## 6. Review Platform-Specific Code

Search the codebase for any platform-specific assumptions such as Windows registry access, Windows file path separators, or COM interop. These areas will require conditional compilation or refactoring to function correctly on non-Windows platforms.

```bash
grep -rn "Registry\|Environment.GetFolderPath\|Path.DirectorySeparatorChar" .
```

## 7. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Linux, macOS, Windows) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on your deployment environment and whether the .NET runtime will be pre-installed on the target machine.

## 9. Review Output Artifacts

Inspect the `publish` output directory to confirm that all expected assemblies, configuration files, and static assets are present before deploying to the target environment.