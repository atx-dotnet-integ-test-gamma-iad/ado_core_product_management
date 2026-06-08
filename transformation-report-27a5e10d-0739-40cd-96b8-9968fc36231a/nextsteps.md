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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not regressed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding further.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless intentionally required.

## 5. Check for Windows-Specific APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may not surface as build errors but will fail at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop usage
- `System.Drawing` (which has platform limitations outside of Windows)

## 6. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that the application starts and core functionality operates as expected.

## 7. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Linux, macOS) to catch any runtime platform-specific issues that static analysis may not detect.

## 8. Review Output Artifacts

After a successful Release build, inspect the output in the `bin/Release` directory. Confirm that the published output does not contain unnecessary legacy assemblies or configuration files from the old .NET Framework project structure.

## 9. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag as needed (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you require the .NET runtime to be bundled with the output.